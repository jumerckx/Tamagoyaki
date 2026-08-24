//===- EquivalenceTransforms.cpp - Equivalence transforms & analyses -*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the equivalence transform & analysis library declared in
// EquivalenceUtils.h. These free functions are the reusable building blocks the
// equivalence passes (EquivalencePasses.cpp) drive over `equivalence.graph`s,
// following the e-graph lifecycle: graph insertion, cost modelling, selection,
// extraction, plus the graph-size analysis and class-invariant restoration.
//
//===----------------------------------------------------------------------===//

#include "EquivalenceUtils.h"

#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"
#include "mlir/Analysis/TopologicalSortUtils.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Matchers.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Casting.h"
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <limits>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/OperationSupport.h>
#include <mlir/Interfaces/FunctionInterfaces.h>
#include <utility>

using namespace mlir;
using namespace mlir::equivalence;

namespace mlir::equivalence {

//===----------------------------------------------------------------------===//
// Graph insertion
//===----------------------------------------------------------------------===//

namespace {

/// Recursively wraps all values (block arguments and operation results) in
/// ClassOps. For each value, creates a ClassOp and replaces all uses of the
/// original value with the ClassOp's result.
void wrapValuesInClassOps(Region &region, OpBuilder &builder) {
  for (Block &block : region) {
    // Wrap block arguments at the start of the block
    if (!block.getArguments().empty()) {
      builder.setInsertionPointToStart(&block);
      for (BlockArgument arg : block.getArguments()) {
        auto classOp = ClassOp::create(
            builder, arg.getLoc(), TypeRange{arg.getType()}, ValueRange{arg},
            /*leader=*/Value{}, /*min_cost_index=*/nullptr);
        arg.replaceAllUsesExcept(classOp.getResult(), classOp);
      }
    }

    // Collect operations to avoid iterator invalidation when inserting
    SmallVector<Operation *> ops;
    for (Operation &op : block) {
      ops.push_back(&op);
    }

    for (Operation *op : ops) {
      // Skip ClassOp to avoid wrapping ClassOp results (which would violate
      // verification)
      if (isa<ClassOp>(op))
        continue;

      // Recursively process nested regions first
      for (Region &nestedRegion : op->getRegions()) {
        wrapValuesInClassOps(nestedRegion, builder);
      }

      // Wrap each operation result in a ClassOp
      if (op->getNumResults() > 0) {
        builder.setInsertionPointAfter(op);
        for (OpResult result : op->getResults()) {
          auto classOp = ClassOp::create(builder, result.getLoc(),
                                         TypeRange{result.getType()},
                                         ValueRange{result}, /*leader=*/Value{},
                                         /*min_cost_index=*/nullptr);
          result.replaceAllUsesExcept(classOp.getResult(), classOp);
        }
      }
    }
  }
}

// Wrap the single-block body of `region` in a GraphOp, then give `region` a
// fresh entry block containing the graph followed by a clone of the original
// terminator (now consuming the graph's results). Returns the graph, or
// nullptr if `region` is not single-block. Non-recursive.
GraphOp wrapRegionBodyInGraph(Region &region, bool insertSingleElementEqs) {
  if (!region.hasOneBlock()) {
    return nullptr;
  }

  Operation *terminator = region.front().getTerminator();

  // Snapshot everything about the terminator before it's replaced.
  OperationName termName = terminator->getName();
  Location termLoc = terminator->getLoc();
  SmallVector<NamedAttribute> termAttrs(terminator->getAttrs());

  Location loc = region.getParentOp()->getLoc();
  OpBuilder builder(region.getContext());

  // The graph's outputs mirror the operands of the region's terminator.
  auto graphOp =
      GraphOp::create(builder, loc, terminator->getOperandTypes(), {});
  Region &graphBody = graphOp.getBody();
  graphBody.takeBody(region);

  // Replace the original terminator (now inside the graph) with a YieldOp.
  builder.setInsertionPoint(terminator);
  YieldOp::create(builder, terminator->getLoc(), terminator->getOperands());
  terminator->erase();

  if (insertSingleElementEqs)
    wrapValuesInClassOps(graphBody, builder);

  // Recreate the region's entry block, taking over the original block
  // arguments (GraphOp captures them implicitly).
  Block &innerBlock = graphBody.front();
  SmallVector<Type> argTypes(innerBlock.getArgumentTypes());
  SmallVector<Location> argLocs;
  argLocs.reserve(innerBlock.getNumArguments());
  for (BlockArgument arg : innerBlock.getArguments()) {
    argLocs.push_back(arg.getLoc());
  }

  Block *newEntryBlock =
      builder.createBlock(&region, region.end(), argTypes, argLocs);

  unsigned numArgs = innerBlock.getNumArguments();
  for (unsigned i = 0; i < numArgs; ++i) {
    innerBlock.getArgument(i).replaceAllUsesWith(newEntryBlock->getArgument(i));
  }
  innerBlock.eraseArguments(0, numArgs);

  // Populate the new entry block: the graph, then the re-created terminator.
  builder.setInsertionPointToStart(newEntryBlock);
  builder.insert(graphOp);
  builder.setInsertionPointToEnd(newEntryBlock);
  OperationState state(termLoc, termName);
  state.addOperands(graphOp->getResults());
  state.addAttributes(termAttrs);
  builder.create(state);

  // The block arguments the graph captures (function args, region args like an
  // scf.for induction variable) are defined outside the graph. Wrap each used
  // capture in a ClassOp at the start of the graph body so its e-class lives
  // inside the graph.
  // When insertSingleElementEqs is set, wrapValuesInClassOps already wrapped
  // these block arguments, so we skip them here.
  if (!insertSingleElementEqs) {
    builder.setInsertionPointToStart(&graphBody.front());
    for (BlockArgument arg : newEntryBlock->getArguments()) {
      if (arg.use_empty())
        continue;
      auto classOp = ClassOp::create(
          builder, arg.getLoc(), TypeRange{arg.getType()}, ValueRange{arg},
          /*leader=*/Value{}, /*min_cost_index=*/nullptr);
      arg.replaceAllUsesExcept(classOp.getResult(), classOp);
    }
  }

  return graphOp;
}

// Recurse into the single-block regions of the speculatable operations in
// `block`, wrapping each in its own nested graph.
void insertNestedGraphsInBlock(Block &block, bool insertSingleElementEqs) {
  // Snapshot first: wrapping inserts fresh entry blocks we don't want to
  // revisit.
  SmallVector<Operation *> ops;
  for (Operation &op : block)
    ops.push_back(&op);

  for (Operation *op : ops) {
    if (!mlir::isSpeculatable(op))
      continue;
    for (Region &nested : op->getRegions())
      insertNestedGraphs(nested, insertSingleElementEqs);
  }
}

} // namespace

void insertNestedGraphs(Region &region, bool insertSingleElementEqs) {
  if (GraphOp graphOp = wrapRegionBodyInGraph(region, insertSingleElementEqs)) {
    // Single-block region: now wrapped in a graph. Descend into its body.
    insertNestedGraphsInBlock(graphOp.getBody().front(),
                              insertSingleElementEqs);
    return;
  }

  // Multi-block (or empty) region: it cannot be wrapped in a single graph, but
  // its blocks may still hold wrappable nested regions.
  for (Block &block : region)
    insertNestedGraphsInBlock(block, insertSingleElementEqs);
}

LogicalResult insertGraphInFunction(FunctionOpInterface funcOp,
                                    bool insertSingleElementEqs) {
  TAMAGOYAKI_SCOPED_TIMER("insertGraphInFunction");
  Region &funcBody = funcOp.getFunctionBody();
  if (funcBody.empty())
    return success();

  // A single-block body is wrapped in a graph; a multi-block (CFG) body cannot
  // be, but insertNestedGraphs still descends into any wrappable nested
  // regions. Either way this is not a failure.
  insertNestedGraphs(funcBody, insertSingleElementEqs);

  return success();
}

//===----------------------------------------------------------------------===//
// Graph size analysis
//===----------------------------------------------------------------------===//

GraphSize computeGraphSize(GraphOp graphOp) {
  GraphSize size;
  graphOp.walk([&](Operation *op) {
    if (op == graphOp) {
      return;
    }
    if (dyn_cast<ClassOp>(op)) {
      size.classes += 1;
    } else {
      size.nodes += op->getNumResults();
      for (auto result : op->getResults()) {
        if (!(result.hasOneUse() && dyn_cast<ClassOp>(*result.user_begin()))) {
          size.classes += 1;
        }
      }
    }
  });
  return size;
}

//===----------------------------------------------------------------------===//
// Cost model and selection
//===----------------------------------------------------------------------===//

static int64_t getNodeBaseCost(Operation *op, const NodeCostFn &nodeCostFn,
                               llvm::StringRef costAttributeName) {
  if (auto attr = op->getAttrOfType<CostAttr>(costAttributeName)) {
    return attr.getValue();
  }
  return nodeCostFn(op);
}

// Values outside of the graph do not carry a cost.
static bool isFreeLeaf(Value v, Region *graphRegion) {
  Operation *defOp = v.getDefiningOp();
  return !defOp || !graphRegion->isAncestor(defOp->getParentRegion());
}

// Compute the total cost of a non-class operation given current known costs.
// Returns -1 if any dependency is unresolved.
static int64_t computeNodeCost(Operation *op, Region *graphRegion,
                               const NodeCostFn &nodeCostFn,
                               DenseMap<Operation *, int64_t> &opCosts,
                               const CostReductionFn &reductionFn,
                               llvm::StringRef costAttributeName) {
  int64_t baseCost = getNodeBaseCost(op, nodeCostFn, costAttributeName);
  if (baseCost == -1)
    return -1;

  SmallVector<int64_t> childCosts;
  for (Value dep : op->getOperands()) {
    if (isFreeLeaf(dep, graphRegion))
      continue;
    auto it = opCosts.find(dep.getDefiningOp());
    if (it == opCosts.end() || it->second == -1)
      return -1;
    childCosts.push_back(it->second);
  }

  return reductionFn(baseCost, childCosts);
}

DenseMap<Operation *, int64_t>
computeGraphCosts(GraphOp graphOp, const NodeCostFn &nodeCostFn,
                  llvm::StringRef costAttributeName,
                  const CostReductionFn &reductionFn) {
  TAMAGOYAKI_SCOPED_TIMER("computeGraphCosts");

  SmallVector<ClassOp> classOps;
  SmallVector<Operation *> otherTrackedOps;

  graphOp.walk([&](Operation *op) {
    if (isa<GraphOp>(op) || isa<YieldOp>(op))
      return;

    if (auto classOp = dyn_cast<ClassOp>(op)) {
      classOps.push_back(classOp);
      return;
    }

    // Check if all users are ClassOps — if so, this is a candidate and
    // doesn't need its own tracked cost.
    bool consumedByClass = llvm::all_of(
        op->getUsers(), [](Operation *user) { return isa<ClassOp>(user); });
    if (!consumedByClass)
      otherTrackedOps.push_back(op);
  });

  Region *graphRegion = &graphOp.getBody();

  DenseMap<Operation *, int64_t> opCosts;
  bool changed = true;
  int maxIterations = 100;
  int iteration = 0;

  while (changed && iteration < maxIterations) {
    changed = false;
    iteration++;

    // ---- Process ClassOps: pick the minimum-cost candidate ----
    for (ClassOp classOp : classOps) {
      int64_t minCost = std::numeric_limits<int64_t>::max();

      for (Value operand : classOp.getInputs()) {
        // Free leaves are free, and get no entry in the cost map.
        int64_t cost = 0;
        if (!isFreeLeaf(operand, graphRegion)) {
          Operation *candidate = operand.getDefiningOp();
          cost = computeNodeCost(candidate, graphRegion, nodeCostFn, opCosts,
                                 reductionFn, costAttributeName);
          if (cost == -1)
            continue;
          // Store candidate cost so callers can look it up.
          auto it = opCosts.find(candidate);
          if (it == opCosts.end() || cost < it->second) {
            opCosts[candidate] = cost;
          }
        }

        minCost = std::min(minCost, cost);
      }

      if (minCost < std::numeric_limits<int64_t>::max()) {
        auto it = opCosts.find(classOp);
        if (it == opCosts.end() || minCost < it->second) {
          opCosts[classOp] = minCost;
          changed = true;
        }
      }
    }

    // ---- Process other tracked (non-class) ops ----
    for (Operation *op : otherTrackedOps) {
      int64_t totalCost = computeNodeCost(op, graphRegion, nodeCostFn, opCosts,
                                          reductionFn, costAttributeName);
      if (totalCost >= 0) {
        auto it = opCosts.find(op);
        if (it == opCosts.end() || totalCost < it->second) {
          opCosts[op] = totalCost;
          changed = true;
        }
      }
    }
  }

  return opCosts;
}

void selectGreedy(GraphOp graphOp, const NodeCostFn &nodeCostFn,
                  llvm::StringRef costAttributeName,
                  const CostReductionFn &reductionFn) {
  TAMAGOYAKI_SCOPED_TIMER("selectGreedy");

  DenseMap<Operation *, int64_t> opCosts =
      computeGraphCosts(graphOp, nodeCostFn, costAttributeName, reductionFn);

  Region *graphRegion = &graphOp.getBody();

  // Set min_cost_index on each ClassOp based on the computed costs.
  graphOp.walk([&](ClassOp classOp) {
    int64_t minCost = std::numeric_limits<int64_t>::max();
    int minIndex = -1;

    for (size_t i = 0; i < classOp.getInputs().size(); ++i) {
      Value operand = classOp.getInputs()[i];
      // Free leaves are free, and the cost map only tracks graph nodes.
      int64_t cost = 0;
      if (!isFreeLeaf(operand, graphRegion)) {
        auto it = opCosts.find(operand.getDefiningOp());
        if (it == opCosts.end() || it->second == -1)
          continue;
        cost = it->second;
      }

      if (cost < minCost) {
        minCost = cost;
        minIndex = i;
      }
    }

    if (minIndex >= 0) {
      int64_t currentMinIndex = -1;
      if (auto attr = classOp->getAttrOfType<IntegerAttr>("min_cost_index"))
        currentMinIndex = attr.getValue().getSExtValue();
      if (currentMinIndex != minIndex) {
        OpBuilder builder(classOp);
        classOp->setAttr("min_cost_index", builder.getI64IntegerAttr(minIndex));
      }
    }
  });
}

void selectConstants(GraphOp graphOp) {
  TAMAGOYAKI_SCOPED_TIMER("selectConstants");

  graphOp.walk([&](ClassOp classOp) {
    // Leave classes that already have a selection alone.
    if (classOp->hasAttr("min_cost_index"))
      return;

    // Select the first constant operand, if any.
    for (size_t i = 0; i < classOp.getInputs().size(); ++i) {
      if (matchPattern(classOp.getInputs()[i], m_Constant())) {
        OpBuilder builder(classOp);
        classOp.setMinCostIndex(i);
        break;
      }
    }
  });
}

void clearSelection(GraphOp graphOp, llvm::StringRef costAttributeName) {
  TAMAGOYAKI_SCOPED_TIMER("clearSelection");
  graphOp.walk([&](Operation *op) {
    if (auto classOp = dyn_cast<ClassOp>(op)) {
      classOp->removeAttr("min_cost_index");
    } else if (!isa<GraphOp>(op) && !isa<YieldOp>(op)) {
      op->removeAttr(costAttributeName);
    }
  });
}

//===----------------------------------------------------------------------===//
// Extraction
//===----------------------------------------------------------------------===//

void extractFromGraph(GraphOp graphOp) {
  TAMAGOYAKI_SCOPED_TIMER("extractFromGraph");
  Block &block = graphOp.getBody().front();

  SmallVector<ClassOp> classOps;
  block.walk([&](Operation *op) {
    if (auto classOp = llvm::dyn_cast<ClassOp>(op)) {
      classOps.push_back(classOp);
    } else {
      op->removeAttr("equivalence.cost");
    }
  });

  for (ClassOp classOp : classOps) {
    if (classOp.getResult().use_empty()) {
      SmallVector<Operation *> toErase;
      toErase.push_back(classOp);
      for (Value operand : classOp.getInputs()) {
        if (Operation *defOp = operand.getDefiningOp())
          toErase.push_back(defOp);
      }
      for (Operation *op : toErase)
        op->erase();
      continue;
    }

    auto minCostIndexAttr =
        classOp->getAttrOfType<IntegerAttr>("min_cost_index");
    if (!minCostIndexAttr)
      continue;

    int64_t minIndex = minCostIndexAttr.getValue().getSExtValue();
    Value selected = classOp.getInputs()[minIndex];

    classOp.getResult().replaceAllUsesWith(selected);

    SmallVector<Operation *> toErase;
    toErase.push_back(classOp);
    for (auto [i, operand] : llvm::enumerate(classOp.getInputs())) {
      if (static_cast<int64_t>(i) != minIndex) {
        if (Operation *defOp = operand.getDefiningOp())
          toErase.push_back(defOp);
      }
    }
    for (Operation *op : toErase)
      op->erase();
  }
}

void inlineGraphOp(GraphOp graphOp) {
  TAMAGOYAKI_SCOPED_TIMER("inlineGraphOp");
  Block &graphBlock = graphOp.getBody().front();

  auto yieldOp = cast<YieldOp>(graphBlock.getTerminator());
  SmallVector<Value> yieldedValues(yieldOp.getValues());
  yieldOp->erase();

  Block *parentBlock = graphOp->getBlock();

  auto &parentOps = parentBlock->getOperations();
  auto insertPos = Block::iterator(graphOp);

  SmallVector<Operation *> inlinedOps;
  for (Operation &op : graphBlock)
    inlinedOps.push_back(&op);

  parentOps.splice(insertPos, graphBlock.getOperations());

  computeTopologicalSorting(inlinedOps);

  for (Operation *op : inlinedOps)
    op->moveBefore(graphOp);

  for (auto [graphResult, yieldedValue] :
       llvm::zip(graphOp.getOutputs(), yieldedValues)) {
    graphResult.replaceAllUsesWith(yieldedValue);
  }

  graphOp->erase();
}

SmallVector<Operation *> computeSelectedTopoSort(GraphOp graphOp) {
  TAMAGOYAKI_SCOPED_TIMER("computeSelectedTopoSort");
  Block &block = graphOp.getBody().front();

  DenseSet<Operation *> excludedOps;

  for (Operation &op : block) {
    bool anyResultNeeded = false;
    for (Value result : op.getResults()) {
      for (OpOperand &use : result.getUses()) {
        Operation *user = use.getOwner();
        auto classOp = dyn_cast<ClassOp>(user);
        if (!classOp) {
          anyResultNeeded = true;
          break;
        }
        if (auto minCostAttr =
                classOp->getAttrOfType<IntegerAttr>("min_cost_index")) {
          int64_t minIdx = minCostAttr.getInt();
          if (minIdx >= 0 &&
              static_cast<size_t>(minIdx) < classOp.getInputs().size() &&
              classOp.getInputs()[minIdx] == result) {
            anyResultNeeded = true;
            break;
          }
        } else {
          anyResultNeeded = true;
          break;
        }
      }
      if (anyResultNeeded)
        break;
    }

    if (!anyResultNeeded)
      excludedOps.insert(&op);
  }

  SmallVector<Operation *> opsToSort;
  for (Operation &op : block) {
    if (!excludedOps.contains(&op))
      opsToSort.push_back(&op);
  }

  auto isOperandReady = [&](Value value, Operation *) -> bool {
    Operation *defOp = value.getDefiningOp();
    return !defOp || excludedOps.contains(defOp);
  };

  computeTopologicalSorting(opsToSort, isOperandReady);

  return opsToSort;
}

//===----------------------------------------------------------------------===//
// Class-invariant restoration
//===----------------------------------------------------------------------===//

LogicalResult restoreClassInvariants(Operation *root) {
  TAMAGOYAKI_SCOPED_TIMER("restoreClassInvariants");

  RewritePatternSet patterns(root->getContext());
  ClassOp::getCanonicalizationPatterns(patterns, root->getContext());
  FrozenRewritePatternSet patternSet(std::move(patterns));

  // Run the class canonicalizer to a genuine fixpoint. The cleanup (merge
  // nested classes, reroute external uses, deduplicate operands) is a monotone
  // rewrite, so lifting the greedy driver's iteration/rewrite caps lets it
  // converge rather than bailing out after the default iteration budget.
  //
  // Folding and constant CSE are deliberately disabled: those are *optimizing*
  // rewrites (e.g. collapsing a single-element class to its operand, hoisting
  // constants) that are not part of the normal form and would destroy e-graph
  // structure callers rely on. Only the invariant-restoring canonicalization
  // patterns run.
  GreedyRewriteConfig config;
  config.setMaxIterations(GreedyRewriteConfig::kNoLimit);
  config.setMaxNumRewrites(GreedyRewriteConfig::kNoLimit);
  config.enableFolding(false);
  config.enableConstantCSE(false);

  return applyPatternsGreedily(root, patternSet, config);
}

} // namespace mlir::equivalence
