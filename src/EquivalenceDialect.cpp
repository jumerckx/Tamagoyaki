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

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/Location.h"
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
#include <cstddef>
#include <cstdint>
#include <limits>
#include <utility>

using namespace mlir;
using namespace mlir::equivalence;

#include "EquivalenceDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// Equivalence dialect.
//===----------------------------------------------------------------------===//

void EquivalenceDialect::initialize() {
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
RegionKind GraphOp::getRegionKind(unsigned index) { return RegionKind::Graph; }
} // namespace mlir::equivalence

LogicalResult ClassOp::verify() {
  if (getInputs().empty()) {
    return emitOpError("must have at least one operand");
  }

  for (Value operand : getInputs()) {
    Operation *defOp = operand.getDefiningOp();
    if (defOp && isa<ClassOp>(defOp)) {
      return emitOpError("result of a class operation cannot be used as an "
                         "operand of another class");
    }

    for (Operation *user : operand.getUsers()) {
      if (user != getOperation()) {
        return emitOpError("operands must only be used by the class operation");
      }
    }
  }

  return success();
}

//===----------------------------------------------------------------------===//
// Equivalence passes
//===----------------------------------------------------------------------===//

namespace mlir::equivalence {
#define GEN_PASS_DEF_EQUIVALENCEINSERTGRAPH
#define GEN_PASS_DEF_EQUIVALENCESWITCHBARFOO
#define GEN_PASS_DEF_EQUIVALENCESELECTGREEDY
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
            builder, arg.getLoc(), TypeRange{arg.getType()}, ValueRange{arg});
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
          auto classOp =
              ClassOp::create(builder, result.getLoc(),
                              TypeRange{result.getType()}, ValueRange{result});
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

    module.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, defaultCostVal); });
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

void EquivalenceDialect::registerTypes() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "EquivalenceTypes.cpp.inc"

      >();
}

void EquivalenceDialect::registerAttributes() {
  addAttributes<
#define GET_ATTRDEF_LIST
#include "EquivalenceAttrs.cpp.inc"

      >();
}

namespace mlir::equivalence {

static int64_t getNodeBaseCost(Operation *op, int64_t defaultCost) {
  if (auto attr = op->getAttrOfType<CostAttr>("equivalence.cost")) {
    return attr.getValue();
  }
  return defaultCost;
}

// Compute the total cost of a non-class operation given current known costs.
// Returns -1 if any dependency is unresolved.
static int64_t computeNodeCost(Operation *op, int64_t defaultCost,
                               DenseMap<Operation *, int64_t> &opCosts) {
  int64_t baseCost = getNodeBaseCost(op, defaultCost);
  if (baseCost == -1)
    return -1;

  int64_t totalCost = baseCost;
  for (Value dep : op->getOperands()) {
    Operation *defOp = dep.getDefiningOp();
    if (!defOp)
      continue; // block argument — free
    auto it = opCosts.find(defOp);
    if (it == opCosts.end() || it->second == -1)
      return -1;
    totalCost += it->second;
  }
  return totalCost;
}

void selectGreedy(GraphOp graphOp, int64_t defaultCost,
                  llvm::StringRef costAttributeName) {
  // Assign default costs to non-class operations.
  graphOp.walk([&](Operation *op) {
    if (!isa<ClassOp>(op) && !isa<GraphOp>(op) && !isa<YieldOp>(op)) {
      if (!op->hasAttr(costAttributeName)) {
        int64_t cost = (defaultCost < 0) ? -1 : defaultCost;
        op->setAttr(costAttributeName, CostAttr::get(op->getContext(), cost));
      }
    }
  });

  // Determine which operations need persistent cost tracking:
  //   1. ClassOps (e-class cost = cost of best candidate)
  //   2. Non-class ops that are NOT consumed by any ClassOp
  //      (their results are used by other non-class ops, YieldOp, etc.)
  // Candidate ops (consumed by a ClassOp) have their cost computed inline.

  SmallVector<Operation *> trackedOps;
  graphOp.walk([&](Operation *op) {
    if (isa<GraphOp>(op) || isa<YieldOp>(op))
      return;

    if (isa<ClassOp>(op)) {
      trackedOps.push_back(op);
      return;
    }

    // Check if all users are ClassOps — if so, this is a candidate and
    // doesn't need its own tracked cost.
    bool consumedByClass = llvm::all_of(
        op->getUsers(), [](Operation *user) { return isa<ClassOp>(user); });
    if (!consumedByClass)
      trackedOps.push_back(op);
  });

  DenseMap<Operation *, int64_t> opCosts;
  bool changed = true;
  int maxIterations = 100;
  int iteration = 0;

  while (changed && iteration < maxIterations) {
    changed = false;
    iteration++;

    for (Operation *op : trackedOps) {
      if (auto classOp = dyn_cast<ClassOp>(op)) {
        // ---- Class op: pick the minimum-cost candidate ----
        int64_t minCost = std::numeric_limits<int64_t>::max();
        int minIndex = -1;

        for (size_t i = 0; i < classOp.getInputs().size(); ++i) {
          Value operand = classOp.getInputs()[i];
          Operation *candidate = operand.getDefiningOp();
          if (!candidate)
            continue;

          // Compute candidate cost inline — it's consumed by this class,
          // so its total cost is not stored persistently.
          int64_t cost = computeNodeCost(candidate, defaultCost, opCosts);
          if (cost == -1)
            continue;

          if (cost < minCost) {
            minCost = cost;
            minIndex = i;
          }
        }

        if (minIndex >= 0) {
          auto it = opCosts.find(op);
          if (it == opCosts.end() || minCost < it->second) {
            opCosts[op] = minCost;
            changed = true;
          }

          int64_t currentMinIndex = -1;
          if (auto attr = classOp->getAttrOfType<IntegerAttr>("min_cost_index"))
            currentMinIndex = attr.getValue().getSExtValue();
          if (currentMinIndex != minIndex) {
            OpBuilder builder(classOp);
            classOp->setAttr("min_cost_index",
                             builder.getI64IntegerAttr(minIndex));
          }
        }
      } else {
        // ---- Non-class op not consumed by any class ----
        int64_t totalCost = computeNodeCost(op, defaultCost, opCosts);
        if (totalCost >= 0) {
          auto it = opCosts.find(op);
          if (it == opCosts.end() || totalCost < it->second) {
            opCosts[op] = totalCost;
            changed = true;
          }
        }
      }
    }
  }
}

LogicalResult insertGraphInFunction(func::FuncOp funcOp,
                                    bool insertSingleElementEqs) {
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

} // namespace mlir::equivalence
