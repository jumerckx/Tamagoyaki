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
#include "llvm/Support/Debug.h"
#include <cassert>
#include <cstddef>
#include <functional>
#include <utility>

#define DEBUG_TYPE "cranelift"

namespace cranelift {

#define GEN_PASS_DECL_CRANELIFTOPTIMIZEPASS
#define GEN_PASS_DEF_CRANELIFTOPTIMIZEPASS
#include "CraneliftPasses.h.inc"

class CraneliftOptimizePass
    : public impl::CraneliftOptimizePassBase<CraneliftOptimizePass> {
public:
  using impl::CraneliftOptimizePassBase<
      CraneliftOptimizePass>::CraneliftOptimizePassBase;

  /// Process a region iteratively for SoN conversion: traverse blocks in
  /// domtree pre-order, visit inner regions first, then move speculatable
  /// non-terminator operations to the graph block and hash-cons them.
  static void processRegion(mlir::Region &region, mlir::Block *graphBlock,
                            mlir::ematch::HashConsPatternRewriter &rewriter) {
    if (region.empty())
      return;
  
    // Each frame represents one region currently being processed; the stack
    // replaces the C call stack of the original recursive implementation.
    struct Frame {
      llvm::SmallVector<mlir::Block *, 4> blocks; // blocks in traversal order
      size_t blockIdx;                            // index of the current block
      mlir::Block::iterator opIter;               // next op in that block
      mlir::Operation *pendingOp;                 // op to revisit after its
                                                  // nested regions are done
    };
  
    // Compute the order in which to visit blocks of a region: domtree pre-order
    // for multi-block regions, or just the single block. This matches the
    // original code, which avoided DominanceInfo for single-block regions to
    // dodge an assertion.
    auto computeBlockOrder =
        [](mlir::Region &r) -> llvm::SmallVector<mlir::Block *, 4> {
      llvm::SmallVector<mlir::Block *, 4> blocks;
      if (r.hasOneBlock()) {
        blocks.push_back(&r.front());
      } else {
        mlir::DominanceInfo domInfo(r.getParentOp());
        for (auto *domNode : llvm::depth_first(domInfo.getRootNode(&r)))
          blocks.push_back(domNode->getBlock());
      }
      return blocks;
    };
  
    // Build a frame for a non-empty region. Caller must ensure !r.empty().
    auto makeFrame = [&](mlir::Region &r) -> Frame {
      Frame f;
      f.blocks = computeBlockOrder(r);
      f.blockIdx = 0;
      f.opIter = f.blocks.front()->begin();
      f.pendingOp = nullptr;
      return f;
    };
  
    // Move + hash-cons step from the original inner conditional.
    auto tryCanonicalize = [&](mlir::Operation *op) {
      if (mlir::isSpeculatable(op) &&
          !op->hasTrait<mlir::OpTrait::IsTerminator>()) {
        op->moveBefore(graphBlock, graphBlock->end());
        if (mlir::Operation *existing = rewriter.lookup(op)) {
          op->replaceAllUsesWith(existing);
          op->erase();
        } else {
          (void)rewriter.insert(op);
        }
      }
    };
  
    llvm::SmallVector<Frame, 8> stack;
    stack.push_back(makeFrame(region));
  
    while (!stack.empty()) {
      Frame &top = stack.back();
  
      // We came back to this frame after finishing the nested regions of
      // `pendingOp`; now process the op itself, matching the original ordering
      // (inner regions first, then the parent op).
      if (top.pendingOp) {
        mlir::Operation *op = top.pendingOp;
        top.pendingOp = nullptr;
        tryCanonicalize(op);
        continue;
      }
  
      // Done with this region's blocks: pop.
      if (top.blockIdx >= top.blocks.size()) {
        stack.pop_back();
        continue;
      }
  
      // Advance past the end of the current block to the next one.
      mlir::Block *block = top.blocks[top.blockIdx];
      if (top.opIter == block->end()) {
        ++top.blockIdx;
        if (top.blockIdx < top.blocks.size())
          top.opIter = top.blocks[top.blockIdx]->begin();
        continue;
      }
  
      // Iterative equivalent of make_early_inc_range: capture the op and
      // step the iterator before doing anything that might move or erase it.
      mlir::Operation *op = &*top.opIter;
      ++top.opIter;
  
      // If any nested region is non-empty, recurse into them first. Push in
      // reverse so the stack pops them in source order (region 0, then 1, ...).
      bool hasNested = false;
      for (mlir::Region &nested : op->getRegions()) {
        if (!nested.empty()) {
          hasNested = true;
          break;
        }
      }
      if (hasNested) {
        top.pendingOp = op;
        for (mlir::Region &nested : llvm::reverse(op->getRegions())) {
          if (!nested.empty())
            stack.push_back(makeFrame(nested));
        }
        // `top` may now dangle due to vector reallocation; we don't touch it
        // again this iteration.
        continue;
      }
  
      // Leaf op: no nested regions to descend into.
      tryCanonicalize(op);
    }
  }

  mlir::equivalence::GraphOp convertToSoN(mlir::FunctionOpInterface funcOp) {
    // 1. Traverse and deduplicate into a temporary decoupled region.
    mlir::Region tempRegion;
    mlir::Block *tempBlock = new mlir::Block();
    tempRegion.push_back(tempBlock);

    mlir::ematch::HashConsPatternRewriter rewriter(funcOp->getContext());
    rewriter.createRootScope(&tempRegion);

    for (mlir::Region &region : funcOp->getRegions()) {
      processRegion(region, tempBlock, rewriter);
    }

    if (tempBlock->empty())
      return nullptr;

    // Helper to determine if an operation logically resides within a target
    // block (accounting for potentially arbitrarily deeply nested regions).
    auto isInside = [&](mlir::Operation *op, mlir::Block *targetBlock) {
      while (op) {
        if (op->getBlock() == targetBlock)
          return true;
        op = op->getParentOp();
      }
      return false;
    };

    // 2. Identify escaping values (used by operations outside of the
    // tempBlock).
    llvm::SmallVector<mlir::Value> escapingValues;
    llvm::SmallVector<mlir::Type> resultTypes;

    for (mlir::Operation &op : *tempBlock) {
      for (mlir::Value result : op.getResults()) {
        bool escapes = false;
        for (mlir::Operation *user : result.getUsers()) {
          if (!isInside(user, tempBlock)) {
            escapes = true;
            break;
          }
        }
        if (escapes) {
          escapingValues.push_back(result);
          resultTypes.push_back(result.getType());
        }
      }
    }

    // 3. Create the single, top-level GraphOp natively bridging out results.
    mlir::OpBuilder builder(funcOp->getContext());
    builder.setInsertionPoint(funcOp);
    mlir::Location loc = funcOp->getLoc();

    auto graphOp = mlir::equivalence::GraphOp::create(
        builder, loc, resultTypes, /*operands=*/mlir::ValueRange{});
    mlir::Block *graphBody = builder.createBlock(&graphOp.getBody());

    // Transfer everything out of the temporary block context over to the
    // GraphOp.
    graphBody->getOperations().splice(graphBody->begin(),
                                      tempBlock->getOperations());

    // 4. Conclude the GraphOp with yielded definitions.
    builder.setInsertionPointToEnd(graphBody);
    mlir::equivalence::YieldOp::create(builder, loc, escapingValues);

    // 5. Redirect external uses to map to GraphOp results.
    // Internal uses (including nested regions of extracted ops, and the YieldOp
    // itself) remain referencing the original source.
    for (auto [escapingVal, graphResult] :
         llvm::zip(escapingValues, graphOp.getResults())) {
      escapingVal.replaceUsesWithIf(graphResult, [&](mlir::OpOperand &use) {
        return !isInside(use.getOwner(), graphBody);
      });
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
    LLVM_DEBUG({
      llvm::dbgs() << "Graph:\n";
      graph->dump();
      llvm::dbgs() << "\nSkeleton:\n";
      funcOp.dump();
    });

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
