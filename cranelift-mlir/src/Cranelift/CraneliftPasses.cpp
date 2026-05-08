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
#include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/Region.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/Visitors.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/LoopLikeInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DepthFirstIterator.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/ScopedHashTable.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Debug.h"
#include <cassert>
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

  mlir::equivalence::GraphOp convertToSoN(mlir::FunctionOpInterface funcOp) {
    mlir::OpBuilder builder(funcOp->getContext());
    mlir::Region &funcBody = funcOp.getFunctionBody();

    // Collected in processing order (innermost-first by construction). The
    // set is for fast membership tests during escape analysis.
    llvm::SmallVector<mlir::Operation *> opsToProcess;
    llvm::SmallPtrSet<mlir::Operation *, 16> opsInGraph;

    // Collect speculatable non-terminator ops from a single region in
    // dominator-tree block order. Ops nested inside a child region are NOT
    // visited here; the LoopLikeInterface walk below handles those first.
    auto collectFromRegion = [&](mlir::Region &region) {
      if (region.empty())
        return;
      auto take = [&](mlir::Block *block) {
        for (mlir::Operation &op : block->without_terminator()) {
          if (mlir::isSpeculatable(&op)) {
            opsToProcess.push_back(&op);
            opsInGraph.insert(&op);
          }
        }
      };
      if (region.hasOneBlock()) {
        take(&region.front());
        return;
      }
      mlir::DominanceInfo domInfo(region.getParentOp());
      for (auto *domNode : llvm::depth_first(domInfo.getRootNode(&region)))
        take(domNode->getBlock());
    };

    // Walk loop-like ops in post-order so nested loop bodies are drained
    // before their enclosing loop. The loop op itself is collected later,
    // when its surrounding region is processed; by then, its body contains
    // only the yield (assuming all body ops were speculatable).
    funcOp.walk<mlir::WalkOrder::PostOrder>(
        [&](mlir::LoopLikeOpInterface loop) {
          for (mlir::Region *body : loop.getLoopRegions())
            collectFromRegion(*body);
        });
    collectFromRegion(funcBody);

    // An op ends up in the graph if itself or any ancestor (up to but not
    // including funcOp) is being moved. A non-speculatable op inside a
    // speculatable loop body is carried into the graph by its enclosing
    // loop op even though it isn't in `opsInGraph` directly.
    auto endsUpInGraph = [&](mlir::Operation *op) {
      for (mlir::Operation *cur = op; cur && cur != funcOp;
           cur = cur->getParentOp())
        if (opsInGraph.contains(cur))
          return true;
      return false;
    };

    // A result escapes if any use is by an op that does NOT end up in the
    // graph.
    llvm::SmallVector<mlir::Value> escapingValues;
    llvm::SmallVector<mlir::Type> resultTypes;
    for (mlir::Operation *op : opsToProcess)
      for (mlir::Value result : op->getResults())
        for (mlir::OpOperand &use : result.getUses())
          if (!endsUpInGraph(use.getOwner())) {
            escapingValues.push_back(result);
            resultTypes.push_back(result.getType());
            break;
          }

    // Create the GraphOp once with the correct result types.
    builder.setInsertionPoint(funcOp);
    auto graphOp = mlir::equivalence::GraphOp::create(builder, funcOp.getLoc(),
                                                      resultTypes, {});
    builder.createBlock(&graphOp.getBody());
    auto yieldOp = mlir::equivalence::YieldOp::create(builder, funcOp.getLoc(),
                                                      escapingValues);

    // Redirect external uses of escaping values to the corresponding GraphOp
    // result. Uses that will end up inside the graph -- including the yield
    // we just created -- keep pointing at the original SSA value.
    for (auto [escapingVal, graphResult] :
         llvm::zip(escapingValues, graphOp.getResults()))
      escapingVal.replaceUsesWithIf(graphResult, [&](mlir::OpOperand &use) {
        mlir::Operation *owner = use.getOwner();
        return owner != yieldOp && !endsUpInGraph(owner);
      });

    // Set up hash-cons for the graph region.
    mlir::ematch::HashConsPatternRewriter rewriter(funcOp->getContext());
    rewriter.createRootScope(&graphOp.getBody());

    // Move ops into the graph block (before the yield) and hash-cons. The
    // collection order guarantees inner-region ops move first, so when an
    // enclosing loop op finally moves, it carries an already-drained body.
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

  void elaborate(mlir::FunctionOpInterface funcOp,
                 mlir::equivalence::GraphOp graphOp) {
    auto yieldOp = mlir::cast<mlir::equivalence::YieldOp>(
        graphOp.getBody().front().getTerminator());

    // Map each graphOp result to the graph-internal value it forwards.
    llvm::DenseMap<mlir::Value, mlir::Value> resultToGraphValue;
    for (auto [graphResult, yieldOperand] :
         llvm::zip(graphOp.getResults(), yieldOp.getValues()))
      resultToGraphValue[graphResult] = yieldOperand;

    // Scoped map: graph-internal Value -> elaborated Value in funcOp.
    // Scopes are pushed both per-block (for the dominator tree of a region)
    // and on every nested-region descent (for structured control flow).
    // Together they ensure an elaborated value is reused only at locations
    // dominated by the point at which it was first elaborated.
    llvm::ScopedHashTable<mlir::Value, mlir::Value> elaborated;

    auto isInsideGraph = [&](mlir::Operation *op) {
      for (mlir::Operation *cur = op; cur; cur = cur->getParentOp())
        if (cur == graphOp)
          return true;
      return false;
    };

    // Recursively clone a graph value (and transitive graph-defined
    // dependencies) into funcOp at the builder's current insertion point.
    // builder.clone deep-copies regions verbatim, so after each clone we
    // walk the cloned regions and rewrite any operand still referencing a
    // graph-internal value -- the canonical offender is a body terminator
    // (e.g. a loop yield) holding onto a value that was hoisted out during
    // saturation.
    std::function<mlir::Value(mlir::Value, mlir::OpBuilder &)> elaborateValue;
    std::function<void(mlir::Region &, mlir::Region &)> elaborateClonedRegion;
    std::function<void(mlir::Block *, mlir::Block *, mlir::DominanceInfo *,
                       const llvm::DenseMap<mlir::Block *, mlir::Block *> &)>
        elaborateClonedBlock;

    // True for any value (op result or block argument) whose definition
    // sits structurally inside graphOp.
    auto isGraphInternalValue = [&](mlir::Value v) {
      if (mlir::Operation *defOp = v.getDefiningOp())
        return isInsideGraph(defOp);
      auto blockArg = mlir::cast<mlir::BlockArgument>(v);
      mlir::Operation *parentOp = blockArg.getOwner()->getParentOp();
      return parentOp && isInsideGraph(parentOp);
    };

    elaborateValue = [&](mlir::Value v,
                         mlir::OpBuilder &builder) -> mlir::Value {
      if (mlir::Value cached = elaborated.lookup(v))
        return cached;

      mlir::Operation *defOp = v.getDefiningOp();
      assert(defOp && "graph value without a defining op");

      mlir::IRMapping mapping;
      // Recurse on operands defined inside the graph -- including block
      // args of an enclosing graph-internal region. For block args the
      // recursive elaborateValue call short-circuits at the cache lookup
      // (the cache was pre-populated on entry to the cloned region).
      for (mlir::Value operand : defOp->getOperands()) {
        if (isGraphInternalValue(operand))
          mapping.map(operand, elaborateValue(operand, builder));
      }

      mlir::Operation *cloned = builder.clone(*defOp, mapping);

      for (auto [origRes, clonedRes] :
           llvm::zip(defOp->getResults(), cloned->getResults()))
        elaborated.insert(origRes, clonedRes);

      // Fix up operands inside any cloned region: clone's IRMapping only
      // knows about the operands we passed in plus this region's own block
      // args; values from elsewhere in the graph come through unchanged
      // and need to be re-elaborated at a point inside the clone.
      for (auto [origRegion, clonedRegion] :
           llvm::zip(defOp->getRegions(), cloned->getRegions()))
        elaborateClonedRegion(origRegion, clonedRegion);

      return cloned->getResult(mlir::cast<mlir::OpResult>(v).getResultNumber());
    };

    // Walk a cloned block in parallel with its original. For each cloned
    // op, re-point operands that still reference graph-internal values
    // through elaborateValue, which clones the necessary support ops at
    // the builder's insertion point (i.e. inside the cloned region).
    elaborateClonedBlock =
        [&](mlir::Block *origBlock, mlir::Block *clonedBlock,
            mlir::DominanceInfo *domInfo,
            const llvm::DenseMap<mlir::Block *, mlir::Block *> &clonedToOrig) {
          // Per-block scope. Pre-populate the cache with mappings from each
          // original block argument (iter_args, induction var, ...) to its
          // cloned counterpart so that hoisted-out ops referring to them
          // resolve at elaborateValue's top-of-function cache lookup.
          llvm::ScopedHashTableScope<mlir::Value, mlir::Value> blockScope(
              elaborated);
          for (auto [origArg, clonedArg] : llvm::zip(
                   origBlock->getArguments(), clonedBlock->getArguments()))
            elaborated.insert(origArg, clonedArg);

          mlir::OpBuilder builder(funcOp->getContext());
          // Iterate ops in parallel by raw ilist iterators. elaborateValue may
          // splice new ops in before the current clonedOp, but ilist iterators
          // are stable across insertions of unrelated nodes, so the parallel
          // walk stays in lockstep with the (untouched) original block.
          auto origIt = origBlock->begin(), origEnd = origBlock->end();
          auto clonedIt = clonedBlock->begin(), clonedEnd = clonedBlock->end();
          for (; origIt != origEnd && clonedIt != clonedEnd;
               ++origIt, ++clonedIt) {
            mlir::Operation &origOp = *origIt;
            mlir::Operation &clonedOp = *clonedIt;
            builder.setInsertionPoint(&clonedOp);
            for (mlir::OpOperand &operand : clonedOp.getOpOperands()) {
              mlir::Value v = operand.get();
              if (isGraphInternalValue(v))
                operand.set(elaborateValue(v, builder));
            }
            // Recurse into this op's own nested regions (e.g. an scf.if inside
            // an scf.for body). Each region descent gets a fresh scope so
            // elaborations inside don't leak to siblings.
            for (auto [origNested, clonedNested] :
                 llvm::zip(origOp.getRegions(), clonedOp.getRegions()))
              elaborateClonedRegion(origNested, clonedNested);
          }

          // Multi-block region: continue down the dominator tree, each child
          // block getting its own pushed scope on entry.
          if (domInfo) {
            auto *domNode = domInfo->getNode(clonedBlock);
            for (auto *child : domNode->children()) {
              mlir::Block *childCloned = child->getBlock();
              auto it = clonedToOrig.find(childCloned);
              assert(it != clonedToOrig.end() &&
                     "missing orig/cloned block pair");
              elaborateClonedBlock(it->second, childCloned, domInfo,
                                   clonedToOrig);
            }
          }
        };

    elaborateClonedRegion = [&](mlir::Region &origRegion,
                                mlir::Region &clonedRegion) {
      if (clonedRegion.empty())
        return;
      if (clonedRegion.hasOneBlock()) {
        llvm::DenseMap<mlir::Block *, mlir::Block *> clonedToOrig;
        elaborateClonedBlock(&origRegion.front(), &clonedRegion.front(),
                             /*domInfo=*/nullptr, clonedToOrig);
        return;
      }
      // Multi-block region: build a cloned-block -> orig-block map (the
      // block lists are 1:1 in the same order after cloning) and walk in
      // dominator-tree order on the clone side.
      llvm::DenseMap<mlir::Block *, mlir::Block *> clonedToOrig;
      auto origBlockIt = origRegion.begin();
      auto clonedBlockIt = clonedRegion.begin();
      for (; origBlockIt != origRegion.end() &&
             clonedBlockIt != clonedRegion.end();
           ++origBlockIt, ++clonedBlockIt)
        clonedToOrig[&*clonedBlockIt] = &*origBlockIt;
      mlir::DominanceInfo domInfo(clonedRegion.getParentOp());
      elaborateClonedBlock(&origRegion.front(), &clonedRegion.front(), &domInfo,
                           clonedToOrig);
    };

    // visitRegion walks the entry block of `region`; visitBlock then
    // recurses through the dominator tree of that region (with a per-block
    // scope) and into nested regions of every op (with a fresh scope per
    // region descent).
    std::function<void(mlir::Region &)> visitRegion;
    std::function<void(mlir::Block *, mlir::DominanceInfo *)> visitBlock;

    visitBlock = [&](mlir::Block *block, mlir::DominanceInfo *domInfo) {
      llvm::ScopedHashTableScope<mlir::Value, mlir::Value> blockScope(
          elaborated);
      mlir::OpBuilder builder(funcOp->getContext());

      for (mlir::Operation &op : *block) {
        builder.setInsertionPoint(&op);
        for (mlir::OpOperand &operand : op.getOpOperands()) {
          auto it = resultToGraphValue.find(operand.get());
          if (it != resultToGraphValue.end())
            operand.set(elaborateValue(it->second, builder));
        }
        // Descend into nested regions (loop bodies, if/else arms, ...) so
        // operands inside structured ops are also re-elaborated. The scoped
        // hashtable prevents elaborations made inside from leaking back to
        // siblings or to enclosing scopes.
        for (mlir::Region &nested : op.getRegions())
          visitRegion(nested);
      }

      if (domInfo) {
        auto *domNode = domInfo->getNode(block);
        for (auto *child : domNode->children())
          visitBlock(child->getBlock(), domInfo);
      }
    };

    visitRegion = [&](mlir::Region &region) {
      if (region.empty())
        return;
      if (region.hasOneBlock()) {
        visitBlock(&region.front(), nullptr);
        return;
      }
      mlir::DominanceInfo domInfo(region.getParentOp());
      visitBlock(&region.front(), &domInfo);
    };

    visitRegion(funcOp.getFunctionBody());
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
