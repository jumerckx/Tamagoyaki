#include "EquivalenceDialect.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Dominance.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Region.h"
#include "mlir/IR/Value.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/SmallVector.h"

namespace cranelift {

#define GEN_PASS_DEF_CRANELIFTDUMMYPASS
#include "CraneliftPasses.h.inc"

class CraneliftDummyPass
    : public impl::CraneliftDummyPassBase<CraneliftDummyPass> {
public:
  using impl::CraneliftDummyPassBase<
      CraneliftDummyPass>::CraneliftDummyPassBase;

  mlir::equivalence::GraphOp convertToSoN(mlir::FunctionOpInterface funcOp) {
    mlir::OpBuilder builder(funcOp->getContext());
    builder.setInsertionPoint(funcOp);

    // Create a GraphOp with no results (results will be wired up later).
    auto graphOp = mlir::equivalence::GraphOp::create(builder, funcOp.getLoc(),
                                                      mlir::TypeRange{}, {});
    // GraphOp's region is empty when created detached; add the required block
    // with its implicit YieldOp terminator.
    mlir::Block *graphBlock = builder.createBlock(&graphOp.getBody());
    mlir::equivalence::YieldOp::create(builder, funcOp.getLoc());

    // Set up hashcons with a root scope for the graph region.
    mlir::ematch::HashConsPatternRewriter rewriter(funcOp->getContext());
    rewriter.createRootScope(&graphOp.getBody());

    // Traverse blocks in domtree preorder.
    mlir::Region &funcBody = funcOp.getFunctionBody();

    // Build dominator tree iteration order.  For single-block regions the
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

    for (mlir::Block *block : blockOrder) {
      // Collect ops first to avoid iterator invalidation.
      llvm::SmallVector<mlir::Operation *> opsToProcess;
      for (mlir::Operation &op : *block) {
        if (mlir::isSpeculatable(&op) &&
            !op.hasTrait<mlir::OpTrait::IsTerminator>()) {
          opsToProcess.push_back(&op);
        }
      }

      for (mlir::Operation *op : opsToProcess) {
        // Move op into the graph block (before the YieldOp terminator)
        // so that lookup works within the graph region's scope.
        op->moveBefore(graphBlock->getTerminator());

        if (mlir::Operation *existing = rewriter.lookup(op)) {
          // Duplicate found: replace uses with the existing one and erase.
          op->replaceAllUsesWith(existing);
          op->erase();
        } else {
          // New unique op: insert into hashcons and keep in graph.
          (void)rewriter.insert(op);
        }
      }
    }

    // Collect values defined inside the graph that are used outside it.
    llvm::SmallVector<mlir::Value> escapingValues;
    for (mlir::Operation &op : *graphBlock) {
      for (mlir::Value result : op.getResults()) {
        for (mlir::OpOperand &use : result.getUses()) {
          if (!graphOp->isAncestor(use.getOwner())) {
            escapingValues.push_back(result);
            break;
          }
        }
      }
    }

    // Update the YieldOp to yield the escaping values.
    auto yieldOp =
        mlir::cast<mlir::equivalence::YieldOp>(graphBlock->getTerminator());
    yieldOp->setOperands(escapingValues);

    // Rebuild the GraphOp with the correct result types.
    llvm::SmallVector<mlir::Type> resultTypes;
    for (mlir::Value v : escapingValues)
      resultTypes.push_back(v.getType());

    builder.setInsertionPoint(graphOp);
    auto newGraphOp = mlir::equivalence::GraphOp::create(
        builder, graphOp.getLoc(), resultTypes, {});
    newGraphOp.getBody().takeBody(graphOp.getBody());

    // Replace external uses of the escaping values with the new GraphOp
    // results.
    for (auto [escapingVal, graphResult] :
         llvm::zip(escapingValues, newGraphOp.getResults())) {
      escapingVal.replaceUsesWithIf(graphResult, [&](mlir::OpOperand &use) {
        return !newGraphOp->isAncestor(use.getOwner());
      });
    }

    graphOp->erase();
    return newGraphOp;
  }

  void runOnOperation() final {
    mlir::FunctionOpInterface funcOp = getOperation();
    mlir::equivalence::GraphOp graph = convertToSoN(funcOp);

    funcOp.dump();
    graph.dump();

    // ...run rewrites...

    // selectGreedy
    // scoped elaboration
  }
};

} // namespace cranelift
