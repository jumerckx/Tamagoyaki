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
#include "mlir/IR/IRMapping.h"
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
#include "llvm/ADT/ScopedHashTable.h"
#include "llvm/ADT/SmallVector.h"
#include <cassert>
#include <functional>
#include <utility>

namespace cranelift {

#define GEN_PASS_DECL_CRANELIFTOPTIMIZEPASS
#define GEN_PASS_DEF_CRANELIFTOPTIMIZEPASS
#include "CraneliftPasses.h.inc"

class CraneliftOptimizePass
    : public impl::CraneliftOptimizePassBase<CraneliftOptimizePass> {
public:
  using impl::CraneliftOptimizePassBase<
      CraneliftOptimizePass>::CraneliftOptimizePassBase;

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

  /// Elaborate: materialize selected pure ops from the GraphOp back into the
  /// funcOp. Visits blocks in domtree preorder, using a scoped map so that
  /// values elaborated in a dominating block are reused by dominated blocks.
  void elaborate(mlir::FunctionOpInterface funcOp,
                 mlir::equivalence::GraphOp graphOp) {
    auto yieldOp = mlir::cast<mlir::equivalence::YieldOp>(
        graphOp.getBody().front().getTerminator());

    // Map each graphOp result to the graph-internal value it forwards.
    llvm::DenseMap<mlir::Value, mlir::Value> resultToGraphValue;
    for (auto [graphResult, yieldOperand] :
         llvm::zip(graphOp.getResults(), yieldOp.getValues()))
      resultToGraphValue[graphResult] = yieldOperand;

    // Scoped map: graph-internal Value → elaborated Value in funcOp.
    llvm::ScopedHashTable<mlir::Value, mlir::Value> elaborated;
    mlir::Region &graphBody = graphOp.getBody();

    // Recursively elaborate a graph-internal value, cloning its producing
    // op (and transitive dependencies) into the funcOp at the builder's
    // current insertion point.
    std::function<mlir::Value(mlir::Value, mlir::OpBuilder &)> elaborateValue;
    elaborateValue = [&](mlir::Value v,
                         mlir::OpBuilder &builder) -> mlir::Value {
      if (mlir::Value cached = elaborated.lookup(v))
        return cached;

      mlir::Operation *defOp = v.getDefiningOp();
      assert(defOp && "graph value without a defining op");

      // Elaborate operands that live inside the graph; others (block
      // args, side-effecting op results) are already available in funcOp.
      mlir::IRMapping mapping;
      for (mlir::Value operand : defOp->getOperands()) {
        if (auto *opDef = operand.getDefiningOp();
            opDef && opDef->getParentRegion() == &graphBody)
          mapping.map(operand, elaborateValue(operand, builder));
      }

      mlir::Operation *cloned = builder.clone(*defOp, mapping);

      for (auto [origRes, clonedRes] :
           llvm::zip(defOp->getResults(), cloned->getResults()))
        elaborated.insert(origRes, clonedRes);

      return cloned->getResult(mlir::cast<mlir::OpResult>(v).getResultNumber());
    };

    // DFS over the domtree; a ScopedHashTableScope is pushed per block
    // so that mappings from dominating blocks are visible to children
    // and automatically popped when backtracking to siblings.
    mlir::DominanceInfo domInfo(funcOp);
    mlir::Region &funcBody = funcOp.getFunctionBody();

    std::function<void(mlir::Block *)> visitBlock;
    visitBlock = [&](mlir::Block *block) {
      llvm::ScopedHashTableScope<mlir::Value, mlir::Value> scope(elaborated);
      mlir::OpBuilder builder(funcOp->getContext());

      for (mlir::Operation &op : *block) {
        builder.setInsertionPoint(&op);
        for (mlir::OpOperand &operand : op.getOpOperands()) {
          auto it = resultToGraphValue.find(operand.get());
          if (it != resultToGraphValue.end()) {
            mlir::Value elabVal = elaborateValue(it->second, builder);
            operand.set(elabVal);
          }
        }
      }

      // Visit dominator-tree children.
      if (funcBody.hasOneBlock())
        return;
      auto *domNode = domInfo.getNode(block);
      for (auto *child : domNode->children())
        visitBlock(child->getBlock());
    };

    visitBlock(&funcBody.front());
    graphOp->erase();
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
    mlir::equivalence::extractFromGraph(graph);
    elaborate(funcOp, graph);
  }
};

} // namespace cranelift
