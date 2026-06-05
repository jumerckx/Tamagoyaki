//===- TestEquivalenceUtils.cpp - Test passes for EquivalenceUtils --------===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains test-only passes that exercise the internal helpers in
// EquivalenceUtils.h which are not otherwise reachable from a production pass.
// These passes are NOT part of the Tamagoyaki core; they are compiled into
// tamagoyaki-opt only when TAMAGOYAKI_INCLUDE_TESTS is enabled and exist purely
// to drive lit/FileCheck tests, mirroring MLIR's own test/lib/ pattern.
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"

using namespace mlir;
using namespace mlir::equivalence;

namespace {
/// Exercises EquivalenceUtils::computeGraphCosts with the `costReductionMax`
/// reduction and a uniform per-node cost of 1. The returned cost map is written
/// back onto each operation as a `test.cost` integer attribute so the result
/// can be checked with FileCheck. No production pass uses the max-reduction, so
/// this verifies that internal helper independently of the rest of the
/// pipeline.
struct TestEquivalenceGraphCostPass
    : public PassWrapper<TestEquivalenceGraphCostPass,
                         OperationPass<ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TestEquivalenceGraphCostPass)

  StringRef getArgument() const final { return "test-equivalence-graph-cost"; }
  StringRef getDescription() const final {
    return "Annotate each op in every equivalence.graph with the max-reduction "
           "cost computed by EquivalenceUtils (test only)";
  }

  void runOnOperation() override {
    getOperation().walk([](GraphOp graphOp) {
      DenseMap<Operation *, int64_t> costs =
          computeGraphCosts(graphOp, /*defaultCost=*/1,
                            /*costAttributeName=*/"test.cost", costReductionMax);
      for (auto &[op, cost] : costs)
        op->setAttr("test.cost", Builder(op).getI64IntegerAttr(cost));
    });
  }
};
} // namespace

namespace mlir {
namespace test {
void registerTestEquivalenceUtilsPasses() {
  PassRegistration<TestEquivalenceGraphCostPass>();
}
} // namespace test
} // namespace mlir
