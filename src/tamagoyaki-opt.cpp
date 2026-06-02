//===- tamagoyaki-opt.cpp ---------------------------------------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"

#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

using namespace mlir;
using namespace mlir::equivalence;
using namespace mlir::ematch;

#ifdef TAMAGOYAKI_INCLUDE_TESTS
// Test-only passes defined in test/lib/. They have no public header and are
// only available when the build is configured with TAMAGOYAKI_INCLUDE_TESTS.
namespace mlir::test {
void registerTestEquivalenceUtilsPasses();
} // namespace mlir::test

static void registerTestPasses() {
  mlir::test::registerTestEquivalenceUtilsPasses();
}
#endif

int main(int argc, char **argv) {
  tamagoyaki::registerTimingCLOptions();

  mlir::registerAllPasses();
  mlir::equivalence::registerEquivalencePasses();
  mlir::ematch::registerEmatchPasses();
#ifdef TAMAGOYAKI_INCLUDE_TESTS
  registerTestPasses();
#endif
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  int result = mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Tamagoyaki optimizer driver\n", registry));

  tamagoyaki::printTimingReport();
  return result;
}
