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

#include "mlir/Conversion/MatchConversionPasses.h"
#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/Transforms/Passes.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

using namespace mlir;
using namespace mlir::equivalence;
using namespace mlir::ematch;

int main(int argc, char **argv) {
  tamagoyaki::registerTimingCLOptions();

  mlir::registerAllPasses();
  mlir::equivalence::registerEquivalencePasses();
  mlir::ematch::registerEmatchPasses();
  mlir::registerMatchConversionPasses();
  mlir::match::registerMatchPasses();
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect, mlir::match::MatchDialect>();
  registerAllDialects(registry);

  int result = mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Tamagoyaki optimizer driver\n", registry));

  tamagoyaki::printTimingReport();
  return result;
}
