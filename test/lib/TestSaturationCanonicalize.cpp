//===- TestSaturationCanonicalize.cpp - Saturation/canon comparison ------===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Test-only passes that measure the benefit of intertwining equality
// saturation with canonicalization, versus running saturation on its own.
//
//   * test-generate-equivalence-expr generates a function whose body is a
//     telescoping product of variables and their multiplicative inverses, e.g.
//     for two variables (a, b):  ((1/b) * (a * (1/a))) * b.  Such an expression
//     algebraically reduces to the constant 1 once associativity,
//     commutativity, the multiplicative inverse rule and `x * 1 -> x` are
//     applied.  The number of variables is configurable so the input program
//     can be scaled up.  This mirrors test/lit/canonicalize/basic2.mlir.
//
//   * test-saturation-canonicalize takes such a program and runs two flows on
//     it, reporting the e-graph size after every iteration:
//       Flow A (intertwined): repeatedly run one round of saturation followed
//         by select-constants / extract / canonicalize.  Canonicalization
//         shrinks the extracted IR between rounds, so fewer saturation rounds
//         are needed.
//       Flow B (saturation only): keep running rounds of saturation without
//         canonicalizing in between, probing after each round whether a single
//         extract+canonicalize would already collapse the graph to `1`.
//     Both flows stop once the program has been reduced to the constant 1.
//
// These passes are NOT part of the Tamagoyaki core; they are compiled into
// tamagoyaki-opt only when TAMAGOYAKI_INCLUDE_TESTS is enabled and exist purely
// to drive lit/FileCheck tests, mirroring MLIR's own test/lib/ pattern.
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Pass/PassManager.h"
#include "mlir/Transforms/Passes.h"

#include "llvm/Support/raw_ostream.h"
#include <llvm/ADT/STLExtras.h>
#include <llvm/Support/CommandLine.h>
#include <memory>
#include <mlir/IR/Block.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/DialectRegistry.h>
#include <mlir/IR/Value.h>
#include <mlir/Pass/PassRegistry.h>
#include <mlir/Support/LLVM.h>
#include <mlir/Support/TypeID.h>
#include <string>
#include <utility>

using namespace mlir;
using namespace mlir::equivalence;

namespace {

//===----------------------------------------------------------------------===//
// test-generate-equivalence-expr
//===----------------------------------------------------------------------===//

/// Generate `func.func @expr(%v0, ..., %vN-1 : f64) -> f64` whose body is a
/// telescoping product that reduces to 1. For N variables the body is built as
///   inner = v0 * (1/v0)
///   for i in 1..N-1:  cur = (1/vi) * cur;  cur = cur * vi
/// which for N == 2 is exactly ((1/b) * (a * (1/a))) * b.
struct TestGenerateEquivalenceExprPass
    : public PassWrapper<TestGenerateEquivalenceExprPass,
                         OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TestGenerateEquivalenceExprPass)

  TestGenerateEquivalenceExprPass() = default;
  TestGenerateEquivalenceExprPass(const TestGenerateEquivalenceExprPass &other)
      : PassWrapper(other) {}

  StringRef getArgument() const final {
    return "test-generate-equivalence-expr";
  }
  StringRef getDescription() const final {
    return "Generate a telescoping product of `num-vars` variables and their "
           "inverses that reduces to 1 (test only)";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<arith::ArithDialect, func::FuncDialect>();
  }

  Option<int> numVars{*this, "num-vars",
                      llvm::cl::desc("Number of variables in the generated "
                                     "expression (>= 1)"),
                      llvm::cl::init(2)};

  void runOnOperation() override {
    ModuleOp module = getOperation();

    // Replace any existing module contents with the freshly generated function.
    for (Operation &op :
         llvm::make_early_inc_range(module.getBody()->getOperations()))
      op.erase();

    int n = numVars;
    if (n < 1)
      n = 1;

    OpBuilder builder(module.getBodyRegion());
    builder.setInsertionPointToStart(module.getBody());
    Location loc = module.getLoc();
    Type f64 = builder.getF64Type();

    SmallVector<Type> argTypes(n, f64);
    auto funcType = builder.getFunctionType(argTypes, f64);
    auto func = func::FuncOp::create(builder, loc, "expr", funcType);

    Block *entry = func.addEntryBlock();
    builder.setInsertionPointToStart(entry);

    Value one = arith::ConstantOp::create(builder, loc, f64,
                                          builder.getF64FloatAttr(1.0));

    // inv[i] = 1.0 / vi
    SmallVector<Value> inv;
    for (int i = 0; i < n; ++i)
      inv.push_back(
          arith::DivFOp::create(builder, loc, one, entry->getArgument(i)));

    // cur = v0 * (1/v0)
    Value cur =
        arith::MulFOp::create(builder, loc, entry->getArgument(0), inv[0]);
    // Wrap each remaining variable's inverse on the left and the variable on
    // the right: cur = ((1/vi) * cur) * vi.
    for (int i = 1; i < n; ++i) {
      cur = arith::MulFOp::create(builder, loc, inv[i], cur);
      cur = arith::MulFOp::create(builder, loc, cur, entry->getArgument(i));
    }

    func::ReturnOp::create(builder, loc, cur);
  }
};

//===----------------------------------------------------------------------===//
// test-saturation-canonicalize
//===----------------------------------------------------------------------===//

/// Sum the e-class / e-node counts of every graph in a module.
static GraphSize moduleGraphSize(ModuleOp module) {
  GraphSize total;
  module.walk([&](GraphOp graph) {
    GraphSize s = computeGraphSize(graph);
    total.classes += s.classes;
    total.nodes += s.nodes;
  });
  return total;
}

/// A program has been reduced to `1` when the value yielded by its graph is the
/// floating-point constant 1.0.
static bool isReducedToOne(ModuleOp module) {
  bool reduced = false;
  module.walk([&](YieldOp yield) {
    if (yield.getValues().size() != 1)
      return;
    Operation *def = yield.getValues()[0].getDefiningOp();
    if (!def || def->getName().getStringRef() != "arith.constant")
      return;
    if (auto f = dyn_cast_or_null<FloatAttr>(def->getAttr("value")))
      if (f.getValueAsDouble() == 1.0)
        reduced = true;
  });
  return reduced;
}

struct TestSaturationCanonicalizePass
    : public PassWrapper<TestSaturationCanonicalizePass,
                         OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TestSaturationCanonicalizePass)

  TestSaturationCanonicalizePass() = default;
  TestSaturationCanonicalizePass(const TestSaturationCanonicalizePass &other)
      : PassWrapper(other) {}

  StringRef getArgument() const final { return "test-saturation-canonicalize"; }
  StringRef getDescription() const final {
    return "Compare intertwining saturation with canonicalization against "
           "saturation only, reporting e-graph size per iteration (test only)";
  }

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<arith::ArithDialect, func::FuncDialect,
                    EquivalenceDialect, ematch::EmatchDialect,
                    pdl_interp::PDLInterpDialect>();
  }

  Option<std::string> patternsFile{
      *this, "patterns-file",
      llvm::cl::desc("Path to the MLIR file containing the rewrite patterns")};
  Option<int> maxRounds{
      *this, "max-rounds",
      llvm::cl::desc("Safety cap on the number of saturation rounds per flow"),
      llvm::cl::init(32)};

  /// Run a single pass on `module`, returning success/failure.
  LogicalResult runPass(ModuleOp module, std::unique_ptr<Pass> pass) {
    PassManager pm(module.getContext(), module.getOperationName());
    pm.addPass(std::move(pass));
    return pm.run(module);
  }

  std::unique_ptr<Pass> saturateOnce() {
    ematch::EmatchSaturatePassOptions opts;
    opts.maxIters = 1;
    opts.patternsFile = patternsFile;
    return ematch::createEmatchSaturatePass(opts);
  }

  /// select-constants, extract, canonicalize -- the simplification half of one
  /// round. Applied in place to `module`.
  LogicalResult simplify(ModuleOp module) {
    PassManager pm(module.getContext(), module.getOperationName());
    pm.addPass(createEquivalenceSelectConstants());
    pm.addPass(createEquivalenceExtract());
    pm.addPass(createCanonicalizerPass());
    return pm.run(module);
  }

  void runOnOperation() override {
    ModuleOp module = getOperation();

    if (patternsFile.empty()) {
      module.emitError("test-saturation-canonicalize requires patterns-file");
      return signalPassFailure();
    }

    // Establish the shared starting point: wrap the generated function in a
    // graph. Both flows start from a clone of this.
    OwningOpRef<ModuleOp> base(module.clone());
    if (failed(runPass(base.get(), createEquivalenceInsertGraph()))) {
      module.emitError("failed to insert graph");
      return signalPassFailure();
    }

    int numVars = 0;
    base->walk([&](func::FuncOp f) { numVars = f.getNumArguments(); });

    GraphSize start = moduleGraphSize(base.get());

    // --- Flow A: intertwine saturation and canonicalization. ---
    SmallVector<GraphSize> flowA;
    int roundsA = -1;
    {
      OwningOpRef<ModuleOp> work(base->clone());
      for (int round = 1; round <= maxRounds; ++round) {
        if (failed(runPass(work.get(), saturateOnce()))) {
          module.emitError("flow A saturation failed");
          return signalPassFailure();
        }
        // Record the peak e-graph size reached this round, before the
        // simplification half shrinks it back down.
        flowA.push_back(moduleGraphSize(work.get()));
        if (failed(simplify(work.get()))) {
          module.emitError("flow A simplification failed");
          return signalPassFailure();
        }
        if (isReducedToOne(work.get())) {
          roundsA = round;
          break;
        }
      }
    }

    // --- Flow B: saturation only, probing after each round. ---
    SmallVector<GraphSize> flowB;
    int roundsB = -1;
    {
      OwningOpRef<ModuleOp> work(base->clone());
      for (int round = 1; round <= maxRounds; ++round) {
        if (failed(runPass(work.get(), saturateOnce()))) {
          module.emitError("flow B saturation failed");
          return signalPassFailure();
        }
        flowB.push_back(moduleGraphSize(work.get()));

        // Probe: would a single extract+canonicalize collapse it to 1?
        OwningOpRef<ModuleOp> probe(work->clone());
        if (failed(simplify(probe.get()))) {
          module.emitError("flow B probe failed");
          return signalPassFailure();
        }
        if (isReducedToOne(probe.get())) {
          roundsB = round;
          break;
        }
      }
    }

    // --- Report. ---
    llvm::outs() << "=== saturation vs. canonicalization ===\n";
    llvm::outs() << "variables: " << numVars << "\n";
    llvm::outs() << "initial graph: " << start.classes << " e-classes, "
                 << start.nodes << " e-nodes\n\n";

    auto report = [](StringRef name, ArrayRef<GraphSize> sizes, int rounds) {
      llvm::outs() << name << ":\n";
      for (auto [i, s] : llvm::enumerate(sizes))
        llvm::outs() << "  round " << (i + 1) << ": " << s.classes
                     << " e-classes, " << s.nodes << " e-nodes\n";
      if (rounds > 0)
        llvm::outs() << "  reduced to 1 after " << rounds << " round(s)\n";
      else
        llvm::outs() << "  did NOT reduce to 1 within the round cap\n";
      llvm::outs() << "\n";
    };

    report("flow A (saturation + canonicalization)", flowA, roundsA);
    report("flow B (saturation only)", flowB, roundsB);

    if (roundsA > 0 && roundsB > 0)
      llvm::outs() << "summary: intertwining canonicalization took " << roundsA
                   << " round(s) vs. " << roundsB
                   << " round(s) for saturation only\n";
  }
};

} // namespace

namespace mlir {
namespace test {
void registerTestSaturationCanonicalizePasses() {
  PassRegistration<TestGenerateEquivalenceExprPass>();
  PassRegistration<TestSaturationCanonicalizePass>();
}
} // namespace test
} // namespace mlir
