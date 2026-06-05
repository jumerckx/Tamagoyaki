//===- EquivalenceDialect.cpp - Equivalence dialect ---------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "TamagoyakiTiming.h"
#include "mlir/Analysis/TopologicalSortUtils.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Matchers.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/TypeSwitch.h"
#include "llvm/Support/Casting.h"
#include <cstddef>
#include <cstdint>
#include <limits>
#include <llvm/ADT/SmallVector.h>
#include <mlir/IR/OpDefinition.h>
#include <string>
#include <utility>

using namespace mlir;
using namespace mlir::equivalence;

#include "EquivalenceDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// Equivalence dialect.
//===----------------------------------------------------------------------===//

void mlir::equivalence::EquivalenceDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "EquivalenceOps.cpp.inc"

      >();
  registerTypes();
  registerAttributes();
}

//===----------------------------------------------------------------------===//
// Equivalence ops
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "EquivalenceOps.cpp.inc"

namespace mlir::equivalence {
mlir::RegionKind GraphOp::getRegionKind(unsigned index) {
  return mlir::RegionKind::Graph;
}
} // namespace mlir::equivalence

mlir::LogicalResult mlir::equivalence::ClassOp::verify() {
  // verify() only enforces the structural invariants that must always hold for
  // a class op to be meaningful. The stronger normal-form properties — a class
  // result is never an operand of another class, a class's operands are used
  // only by the class, and operands are unique — are *not* checked here: they
  // are transiently broken by other ops' canonicalizations (e.g. `c1 + 0 -> c1`
  // floats a class result into a class operand, and rerouting external uses can
  // collapse two operands to the same value) and are the responsibility of the
  // `equivalence-restore-invariants` normalization pass, not of well-formedness.
  if (getInputs().empty()) {
    return emitOpError("must have at least one operand");
  }

  if (Value leader = getLeader()) {
    Operation *defOp = leader.getDefiningOp();
    if (!defOp || !isa<ClassOp>(defOp)) {
      return emitOpError("leader must be the result of a class operation");
    }
  }

  return success();
}

mlir::OpFoldResult mlir::equivalence::ClassOp::fold(FoldAdaptor adaptor) {
  // A class that lists its own result as an operand: that operand is redundant
  // and can be dropped in place.
  for (auto [idx, input] : llvm::enumerate(getInputs())) {
    auto innerClass = input.getDefiningOp<ClassOp>();
    if (innerClass == getOperation()) {
      getInputsMutable().erase(static_cast<unsigned>(idx));
      return getResult();
    }
  }

  // Drop duplicate operands. A value appearing more than once adds nothing to
  // the equivalence set, and the verifier requires operands to be unique.
  SmallPtrSet<Value, 8> seen;
  for (auto [idx, input] : llvm::enumerate(getInputs())) {
    if (!seen.insert(input).second) {
      getInputsMutable().erase(static_cast<unsigned>(idx));
      // A precomputed selection refers to operands by index, so it is now
      // stale.
      (*this)->removeAttr("min_cost_index");
      return getResult();
    }
  }

  // A trivial e-class — a single input — is interchangeable with that input.
  if (!getLeader() && (getInputs().size() == 1))
    return getInputs().front();

  return {};
}

mlir::LogicalResult
mlir::equivalence::ClassOp::canonicalize(ClassOp op,
                                         PatternRewriter &rewriter) {
  // Drop self-referential and duplicate operands.
  {
    SmallPtrSet<Value, 8> seen;
    SmallVector<Value> unique;
    for (Value input : op.getInputs()) {
      if (input.getDefiningOp() == op.getOperation())
        continue; // self-reference
      if (seen.insert(input).second)
        unique.push_back(input);
    }
    if (!unique.empty() && unique.size() != op.getInputs().size()) {
      rewriter.modifyOpInPlace(op, [&] {
        // Operand indices change, so any precomputed selection is stale.
        op->removeAttr("min_cost_index");
        op.getInputsMutable().assign(unique);
      });
      return success();
    }
  }

  // Merge a nested e-class into this one. If an operand is itself the result of
  // another class, the two classes denote the same equivalence set and can be
  // collapsed: the inner class absorbs this class's remaining operands and this
  // class is replaced by the inner class result. This is the structural rewrite
  // that establishes "a class result is never an operand of another class".
  if (!op.getLeader()) {
    for (auto [idx, input] : llvm::enumerate(op.getInputs())) {
      auto innerClass = input.getDefiningOp<ClassOp>();
      if (!innerClass || innerClass == op.getOperation())
        continue;

      SmallVector<Value> merged = llvm::to_vector(innerClass.getInputs());
      SmallPtrSet<Value, 8> seen(merged.begin(), merged.end());
      for (auto [j, other] : llvm::enumerate(op.getInputs())) {
        if (j == idx)
          continue;
        if (seen.insert(other).second)
          merged.push_back(other);
      }

      rewriter.modifyOpInPlace(innerClass, [&] {
        // Operand indices change, so any precomputed selection is stale.
        innerClass->removeAttr("min_cost_index");
        innerClass.getInputsMutable().assign(merged);
      });
      rewriter.replaceOp(op, innerClass.getResult());
      return success();
    }
  }

  Value result = op.getResult();
  bool changed = false;

  // Every operand of an e-class is, by definition, equivalent to the class
  // itself. Any other operation that still refers to the operand directly
  // should instead route through the class result. Rewriting these uses
  // establishes the invariant that a class's operands are used only by the
  // class operation.
  for (Value input : op.getInputs()) {
    rewriter.replaceUsesWithIf(input, result, [&](OpOperand &use) {
      if (use.getOwner() == op.getOperation())
        return false;
      changed = true;
      return true;
    });
  }

  return success(changed);
}

mlir::LogicalResult mlir::equivalence::GraphOp::verify() {
  auto walkResult = getBody().walk([&](Operation *op) -> WalkResult {
    if (isa<YieldOp>(op))
      return WalkResult::advance();
    if (!mlir::isSpeculatable(op) &&
        !op->hasAttrOfType<UnitAttr>("equivalence.allow_unspeculatable")) {
      return op->emitOpError(
          "operation in equivalence.graph region must be "
          "speculatable or carry the "
          "`equivalence.allow_unspeculatable` unit attribute");
    }
    return WalkResult::advance();
  });
  return failure(walkResult.wasInterrupted());
}

//===----------------------------------------------------------------------===//
// Equivalence passes
//===----------------------------------------------------------------------===//

namespace mlir::equivalence {
#define GEN_PASS_DEF_EQUIVALENCEINSERTGRAPH
#define GEN_PASS_DEF_EQUIVALENCESWITCHBARFOO
#define GEN_PASS_DEF_EQUIVALENCESELECTGREEDY
#define GEN_PASS_DEF_EQUIVALENCESELECTCONSTANTS
#define GEN_PASS_DEF_EQUIVALENCEEXTRACT
#define GEN_PASS_DEF_EQUIVALENCEGRAPHSIZE
#define GEN_PASS_DEF_EQUIVALENCERESTOREINVARIANTS
#include "EquivalencePasses.h.inc"

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

class EquivalenceInsertGraph
    : public impl::EquivalenceInsertGraphBase<EquivalenceInsertGraph> {
public:
  using impl::EquivalenceInsertGraphBase<
      EquivalenceInsertGraph>::EquivalenceInsertGraphBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();

    module->walk([&](mlir::func::FuncOp funcOp) {
      if (failed(insertGraphInFunction(funcOp, false))) {
        signalPassFailure();
      }
    });
  }
};

class EquivalenceSwitchBarFooRewriter : public OpRewritePattern<func::FuncOp> {
public:
  using OpRewritePattern<func::FuncOp>::OpRewritePattern;
  LogicalResult matchAndRewrite(func::FuncOp f_op,
                                PatternRewriter &rewriter) const final {
    for (Operation &op : f_op.getOps()) {
      if (isSpeculatable(&op)) {
        op.setAttr("speculatable", rewriter.getAttr<UnitAttr>());
      }
      if (isMemoryEffectFree(&op)) {
        op.setAttr("memoryeffectfree", rewriter.getAttr<UnitAttr>());
      }
    }
    if (f_op.getSymName() == "bar") {
      rewriter.modifyOpInPlace(f_op, [&f_op]() { f_op.setSymName("foo"); });
      return success();
    }
    return failure();
  }
};

class EquivalenceSwitchBarFoo
    : public impl::EquivalenceSwitchBarFooBase<EquivalenceSwitchBarFoo> {
public:
  using impl::EquivalenceSwitchBarFooBase<
      EquivalenceSwitchBarFoo>::EquivalenceSwitchBarFooBase;
  void runOnOperation() final {
    RewritePatternSet patterns(&getContext());
    patterns.add<EquivalenceSwitchBarFooRewriter>(&getContext());
    FrozenRewritePatternSet patternSet(std::move(patterns));
    GreedyRewriteConfig config = GreedyRewriteConfig();
    config.enableConstantCSE(false);
    config.enableFolding(false);
    if (failed(applyPatternsGreedily(getOperation(), patternSet, config)))
      signalPassFailure();
  }
};

class EquivalenceSelectGreedy
    : public impl::EquivalenceSelectGreedyBase<EquivalenceSelectGreedy> {
public:
  using impl::EquivalenceSelectGreedyBase<
      EquivalenceSelectGreedy>::EquivalenceSelectGreedyBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    int64_t defaultCostVal = this->defaultCost;
    std::string costAttributeName = this->costAttributeName;

    module.walk([&](GraphOp graphOp) {
      selectGreedy(graphOp, defaultCostVal, costAttributeName);
    });
  }
};

class EquivalenceSelectConstants
    : public impl::EquivalenceSelectConstantsBase<EquivalenceSelectConstants> {
public:
  using impl::EquivalenceSelectConstantsBase<
      EquivalenceSelectConstants>::EquivalenceSelectConstantsBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    module.walk([&](GraphOp graphOp) { selectConstants(graphOp); });
  }
};

class EquivalenceExtract
    : public impl::EquivalenceExtractBase<EquivalenceExtract> {
public:
  using impl::EquivalenceExtractBase<
      EquivalenceExtract>::EquivalenceExtractBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();

    module.walk([&](GraphOp graphOp) {
      extractFromGraph(graphOp);

      if (this->removeGraphs) {
        Block &block = graphOp.getBody().front();
        bool hasClassOps = false;
        block.walk([&](ClassOp) { hasClassOps = true; });
        if (!hasClassOps)
          inlineGraphOp(graphOp);
      }
    });
  }
};

class EquivalenceRestoreInvariants
    : public impl::EquivalenceRestoreInvariantsBase<
          EquivalenceRestoreInvariants> {
public:
  using impl::EquivalenceRestoreInvariantsBase<
      EquivalenceRestoreInvariants>::EquivalenceRestoreInvariantsBase;
  void runOnOperation() final {
    if (failed(restoreClassInvariants(getOperation())))
      signalPassFailure();
  }
};

class EquivalenceGraphSize
    : public impl::EquivalenceGraphSizeBase<EquivalenceGraphSize> {
public:
  using impl::EquivalenceGraphSizeBase<
      EquivalenceGraphSize>::EquivalenceGraphSizeBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    module.walk([&](GraphOp graphOp) {
      GraphSize size = computeGraphSize(graphOp);
      llvm::outs() << "Graph has " << size.classes << " e-classes and "
                   << size.nodes << " e-nodes.\n";
    });
  }
};

} // namespace
} // namespace mlir::equivalence

//===----------------------------------------------------------------------===//
// Equivalence types
//===----------------------------------------------------------------------===//

#define GET_TYPEDEF_CLASSES
#include "EquivalenceTypes.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "EquivalenceAttrs.cpp.inc"

void mlir::equivalence::EquivalenceDialect::registerTypes() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "EquivalenceTypes.cpp.inc"

      >();
}

void mlir::equivalence::EquivalenceDialect::registerAttributes() {
  addAttributes<
#define GET_ATTRDEF_LIST
#include "EquivalenceAttrs.cpp.inc"

      >();
}

namespace mlir::equivalence {

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
        if (!(result.hasOneUse() &&
              dyn_cast<ClassOp>(*result.user_begin()))) {
          size.classes += 1;
        }
      }
    }
  });
  return size;
}

static int64_t getNodeBaseCost(Operation *op, const NodeCostFn &nodeCostFn,
                               llvm::StringRef costAttributeName) {
  if (auto attr = op->getAttrOfType<CostAttr>(costAttributeName)) {
    return attr.getValue();
  }
  return nodeCostFn(op);
}

// Compute the total cost of a non-class operation given current known costs.
// Returns -1 if any dependency is unresolved.
static int64_t computeNodeCost(Operation *op, const NodeCostFn &nodeCostFn,
                               DenseMap<Operation *, int64_t> &opCosts,
                               const CostReductionFn &reductionFn,
                               llvm::StringRef costAttributeName) {
  int64_t baseCost = getNodeBaseCost(op, nodeCostFn, costAttributeName);
  if (baseCost == -1)
    return -1;

  SmallVector<int64_t> childCosts;
  for (Value dep : op->getOperands()) {
    Operation *defOp = dep.getDefiningOp();
    if (!defOp)
      continue; // block argument — free
    auto it = opCosts.find(defOp);
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
        Operation *candidate = operand.getDefiningOp();
        // Block arguments have no defining op and are free (cost 0).
        int64_t cost = 0;
        if (candidate) {
          cost = computeNodeCost(candidate, nodeCostFn, opCosts, reductionFn,
                                 costAttributeName);
          // Store candidate cost so callers can look it up.
          if (cost >= 0)
            opCosts.try_emplace(candidate, cost);
        }
        if (cost == -1)
          continue;

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
      int64_t totalCost = computeNodeCost(op, nodeCostFn, opCosts, reductionFn,
                                          costAttributeName);
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

  // Set min_cost_index on each ClassOp based on the computed costs.
  graphOp.walk([&](ClassOp classOp) {
    int64_t minCost = std::numeric_limits<int64_t>::max();
    int minIndex = -1;

    for (size_t i = 0; i < classOp.getInputs().size(); ++i) {
      Value operand = classOp.getInputs()[i];
      Operation *candidate = operand.getDefiningOp();
      int64_t cost = 0;
      if (candidate) {
        auto it = opCosts.find(candidate);
        if (it == opCosts.end())
          continue;
        cost = it->second;
        if (cost == -1)
          continue;
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

LogicalResult insertGraphInFunction(func::FuncOp funcOp,
                                    bool insertSingleElementEqs) {
  TAMAGOYAKI_SCOPED_TIMER("insertGraphInFunction");
  Region &funcBody = funcOp.getFunctionBody();

  if (!funcBody.hasOneBlock()) {
    return failure();
  }

  Block &entryBlock = funcBody.front();
  auto returnOp = dyn_cast<func::ReturnOp>(*entryBlock.getTerminator());

  if (!returnOp) {
    return funcOp.emitOpError("function must have a return operation");
  }

  Location loc = funcOp.getLoc();
  FunctionType funcType = funcOp.getFunctionType();
  OpBuilder builder(funcOp->getContext());

  auto graphOp = GraphOp::create(builder, loc, funcType.getResults(), {});

  Region &graphBody = graphOp.getBody();
  graphBody.takeBody(funcBody);

  builder.setInsertionPoint(returnOp);
  YieldOp::create(builder, returnOp.getLoc(), returnOp.getOperands());
  returnOp.erase();

  if (insertSingleElementEqs) {
    wrapValuesInClassOps(graphBody, builder);
  }

  Block *newEntryBlock =
      builder.createBlock(&funcBody, funcBody.end(), funcType.getInputs(),
                          SmallVector<Location>(funcType.getNumInputs(), loc));

  // Remap the inner block arguments (which were the original function
  // arguments) to the new outer function arguments, as GraphOp captures them
  // implicitly.
  Block &innerBlock = graphBody.front();
  unsigned numArgs = innerBlock.getNumArguments();
  for (unsigned i = 0; i < numArgs; ++i) {
    innerBlock.getArgument(i).replaceAllUsesWith(newEntryBlock->getArgument(i));
  }
  innerBlock.eraseArguments(0, numArgs);

  builder.setInsertionPointToStart(newEntryBlock);
  builder.insert(graphOp);

  func::ReturnOp::create(builder, loc, graphOp->getResults());

  return success();
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
