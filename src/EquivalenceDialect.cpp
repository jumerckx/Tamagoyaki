//===- EquivalenceDialect.cpp - Equivalence dialect ---------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/IRMapping.h"
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
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
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

    // Collect all functions first, then process them
    SmallVector<func::FuncOp> functions;
    for (Operation &op : module.getBody()->getOperations()) {
      if (auto funcOp = dyn_cast<func::FuncOp>(op)) {
        functions.push_back(funcOp);
      }
    }

    // Process each function
    for (func::FuncOp funcOp : functions) {
      if (failed(transformFunction(funcOp, true))) {
        signalPassFailure();
      }
    }
  }

private:
  LogicalResult transformFunction(func::FuncOp funcOp,
                                  bool insertSingleElementEqs) {
    // Only transform single-block functions
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

    // Create the graphOp at the start of the block
    FunctionType funcType = funcOp.getFunctionType();
    OpBuilder builder(funcOp->getContext());
    auto graphOp = GraphOp::create(builder, loc, funcType.getResults(), {});

    // Put the single-block function body in the graphOp
    Region &graphBody = graphOp.getBody();
    graphBody.takeBody(funcBody);

    // Rewrite the func.return to a tama.yield
    builder.setInsertionPoint(returnOp);
    YieldOp::create(builder, returnOp.getLoc(), returnOp.getOperands());
    returnOp.erase();

    if (insertSingleElementEqs) {
      wrapValuesInClassOps(graphBody, builder);
    }

    // Create a new function body
    Block *newEntryBlock = builder.createBlock(
        &funcBody, funcBody.end(), funcType.getInputs(),
        SmallVector<Location>(funcType.getNumInputs(), loc));

    graphOp->setOperands(newEntryBlock->getArguments());

    // Insert the graphOp into the new block
    builder.setInsertionPointToStart(newEntryBlock);
    builder.insert(graphOp);

    // Create a return that returns the graphOp's results
    func::ReturnOp::create(builder, loc, graphOp->getResults());

    return success();
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

/// Get the base cost of a node from its cost attribute or default.
int64_t getNodeBaseCost(Operation *op, int64_t defaultCost) {
  if (auto attr = op->getAttrOfType<CostAttr>("equivalence.cost")) {
    return attr.getValue();
  }
  return defaultCost;
}

class EquivalenceSelectGreedy
    : public impl::EquivalenceSelectGreedyBase<EquivalenceSelectGreedy> {
public:
  using impl::EquivalenceSelectGreedyBase<
      EquivalenceSelectGreedy>::EquivalenceSelectGreedyBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    int64_t defaultCostVal = this->defaultCost;

    // Process each GraphOp separately
    module.walk([&](GraphOp graphOp) {
      // Collect all ClassOps in this graph
      SmallVector<ClassOp> classOps;
      graphOp.walk([&](ClassOp classOp) { classOps.push_back(classOp); });

      // Initialize base costs as attributes on operations within the graph
      // Only set cost if not already present (preserve manually specified
      // costs)
      graphOp.walk([&](Operation *op) {
        if (!isa<ClassOp>(op) && !isa<GraphOp>(op) && !isa<YieldOp>(op)) {
          if (!op->hasAttr("equivalence.cost")) {
            int64_t cost = (defaultCostVal < 0) ? -1 : defaultCostVal;
            op->setAttr("equivalence.cost",
                        CostAttr::get(op->getContext(), cost));
          }
        }
      });

      // Fixed-point iteration: repeatedly scan ClassOps until convergence
      bool changed = true;
      int maxIterations = 100;
      int iteration = 0;

      while (changed && iteration < maxIterations) {
        changed = false;
        iteration++;

        // Track e-class minimum costs in this iteration
        DenseMap<Value, int64_t> eclassCosts;

        // First pass: collect costs from ClassOps
        for (ClassOp classOp : classOps) {
          Value result = classOp.getResult();
          int64_t minCost = std::numeric_limits<int64_t>::max();
          int minIndex = -1;

          // Evaluate cost of each operand
          for (size_t i = 0; i < classOp.getInputs().size(); ++i) {
            Value operand = classOp.getInputs()[i];
            Operation *operandDef = operand.getDefiningOp();

            int64_t totalCost = 0;
            if (!operandDef) {
              // Block arguments are free
              totalCost = 0;
            } else if (auto classDefOp = dyn_cast<ClassOp>(operandDef)) {
              // Cost is from e-class map
              auto it = eclassCosts.find(classDefOp.getResult());
              if (it == eclassCosts.end()) {
                continue; // Skip if cost not yet computed
              }
              totalCost = it->second;
            } else {
              // Regular operation: base cost + dependency costs
              totalCost = getNodeBaseCost(operandDef, defaultCostVal);
              if (totalCost == -1) {
                continue; // Skip if no cost
              }
              for (Value dep : operandDef->getOperands()) {
                if (!dep.getDefiningOp()) {
                  // Block argument dependency is free
                  continue;
                }
                auto it = eclassCosts.find(dep);
                if (it != eclassCosts.end()) {
                  int64_t depCost = it->second;
                  if (depCost == -1) {
                    totalCost = -1;
                    break;
                  }
                  totalCost += depCost;
                }
                // If dep is not in eclassCosts and not a block arg, it's a
                // direct operation result - we need its cost
              }
              if (totalCost == -1) {
                continue; // Skip if dependency costs unavailable
              }
            }

            if (totalCost < minCost) {
              minCost = totalCost;
              minIndex = i;
            }
          }

          // Update e-class cost if minimum was found
          if (minIndex >= 0) {
            eclassCosts[result] = minCost;
          } else {
            eclassCosts[result] = -1;
          }

          // Update min_cost_index attribute if changed
          int64_t currentMinIndex = -1;
          if (auto attr =
                  classOp->getAttrOfType<IntegerAttr>("min_cost_index")) {
            currentMinIndex = attr.getValue().getSExtValue();
          }

          if (currentMinIndex != minIndex && minIndex >= 0) {
            OpBuilder builder(classOp);
            classOp->setAttr("min_cost_index",
                             builder.getI64IntegerAttr(minIndex));
            changed = true;
          }
        }
      }
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
