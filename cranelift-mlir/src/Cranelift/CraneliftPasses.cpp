#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Dominance.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/Region.h"
#include "mlir/IR/Value.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include <utility>

namespace cranelift {

#define GEN_PASS_DECL_CRANELIFTDUMMYPASS
#define GEN_PASS_DEF_CRANELIFTDUMMYPASS
#include "CraneliftPasses.h.inc"

class CraneliftDummyPass
    : public impl::CraneliftDummyPassBase<CraneliftDummyPass> {
public:
  using impl::CraneliftDummyPassBase<
      CraneliftDummyPass>::CraneliftDummyPassBase;

  mlir::equivalence::GraphOp convertToSoN(mlir::FunctionOpInterface funcOp) {
    mlir::OpBuilder builder(funcOp->getContext());
    mlir::Region &funcBody = funcOp.getFunctionBody();

    // Build dominator tree iteration order. For single-block regions the
    // DominanceInfo API asserts, so handle that case directly.
    llvm::SmallVector<mlir::Block *> blockOrder;
    if (funcBody.hasOneBlock()) {
      blockOrder.push_back(&funcBody.front());
    } else {
      mlir::DominanceInfo domInfo(funcOp);
      for (auto *domNode : llvm::depth_first(domInfo.getRootNode(&funcBody))) {
        blockOrder.push_back(domNode->getBlock());
      }
    }

    // Analyze up front so we can create the GraphOp once with the right
    // result types. Collect the ops destined for the graph (in processing
    // order) and, separately, track them in a set for fast membership tests.
    llvm::SmallVector<mlir::Operation *> opsToProcess;
    llvm::SmallPtrSet<mlir::Operation *, 16> opsInGraph;
    for (mlir::Block *block : blockOrder) {
      for (mlir::Operation &op : *block) {
        if (mlir::isSpeculatable(&op) &&
            !op.hasTrait<mlir::OpTrait::IsTerminator>()) {
          opsToProcess.push_back(&op);
          opsInGraph.insert(&op);
        }
      }
    }

    // A result escapes if any of its uses is by an op that is NOT going into
    // the graph. This matches the post-move "not an ancestor of graphOp"
    // check in the original, computed without mutating the IR.
    llvm::SmallVector<mlir::Value> escapingValues;
    llvm::SmallVector<mlir::Type> resultTypes;
    for (mlir::Operation *op : opsToProcess) {
      for (mlir::Value result : op->getResults()) {
        for (mlir::OpOperand &use : result.getUses()) {
          if (!opsInGraph.contains(use.getOwner())) {
            escapingValues.push_back(result);
            resultTypes.push_back(result.getType());
            break;
          }
        }
      }
    }

    // Create the GraphOp exactly once with the correct result types.
    builder.setInsertionPoint(funcOp);
    auto graphOp = mlir::equivalence::GraphOp::create(builder, funcOp.getLoc(),
                                                      resultTypes, {});
    builder.createBlock(&graphOp.getBody());
    // The yield references the escaping values directly. Their producers
    // still live in funcOp at this point and will be moved into the graph
    // block below. Hash-consing may subsequently rewire individual yield
    // operands via replaceAllUsesWith when duplicates are folded.
    auto yieldOp = mlir::equivalence::YieldOp::create(builder, funcOp.getLoc(),
                                                      escapingValues);

    // Redirect external uses of each escaping value to the corresponding
    // GraphOp result now, before any producer moves. Uses that will end up
    // inside the graph (producers still waiting to be moved, plus the yield
    // operand we just created) must keep pointing at the original SSA value.
    for (auto [escapingVal, graphResult] :
         llvm::zip(escapingValues, graphOp.getResults())) {
      escapingVal.replaceUsesWithIf(graphResult, [&](mlir::OpOperand &use) {
        mlir::Operation *owner = use.getOwner();
        return owner != yieldOp && !opsInGraph.contains(owner);
      });
    }

    // Set up hashcons with a root scope for the graph region.
    mlir::ematch::HashConsPatternRewriter rewriter(funcOp->getContext());
    rewriter.createRootScope(&graphOp.getBody());

    // Move ops into the graph block (before the yield) and hash-cons as we
    // go. When a duplicate is found, replaceAllUsesWith updates any dangling
    // internal uses — including yield operands — to the canonical
    // representative. Hash-cons preserves result types, so the pre-computed
    // GraphOp result types remain correct.
    for (mlir::Operation *op : opsToProcess) {
      op->moveBefore(yieldOp);
      if (mlir::Operation *existing = rewriter.lookup(op)) {
        op->replaceAllUsesWith(existing);
        op->erase();
      } else {
        (void)rewriter.insert(op);
      }
    }

    return graphOp;
  }

  void runOnOperation() final {
    mlir::FunctionOpInterface funcOp = getOperation();
    mlir::equivalence::GraphOp graph = convertToSoN(funcOp);

    // Run equality saturation if a patterns file is provided.
    if (!this->patternsFile.empty()) {
      mlir::ModuleOp parentModule = funcOp->getParentOfType<mlir::ModuleOp>();
      if (!parentModule) {
        funcOp.emitError() << "function must be inside a module";
        return this->signalPassFailure();
      }

      mlir::OwningOpRef<mlir::ModuleOp> parsedPatterns =
          mlir::parseSourceFile<mlir::ModuleOp>(this->patternsFile,
                                                funcOp->getContext());
      if (!parsedPatterns) {
        funcOp.emitError() << "failed to parse patterns file: "
                           << this->patternsFile;
        return this->signalPassFailure();
      }

      mlir::ematch::convertEmatchOpsToApplyRewrites(parsedPatterns.get());

      parsedPatterns.get().getOperation()->remove();
      mlir::PDLPatternModule pdlPattern(parsedPatterns.release());

      bool ok = mlir::ematch::runSaturation(
          parentModule->getContext(), std::move(pdlPattern), parentModule,
          this->maxIters, this->maxNodes, /*listener=*/nullptr,
          this->eagerRewrite);
      if (!ok) {
        funcOp.emitError() << "equality saturation failed";
        return this->signalPassFailure();
      }
    }

    mlir::equivalence::selectGreedy(graph, /*defaultCost=*/1);
    graph->dump();
    funcOp->dump();

    // elaborate
  }
};

} // namespace cranelift
