//===- tamagoyaki-opt.cpp ---------------------------------------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"

#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

using namespace mlir;
using namespace mlir::equivalence;
using namespace mlir::ematch;

int main(int argc, char **argv) {
  mlir::registerAllPasses();
  mlir::equivalence::registerEquivalencePasses();
  mlir::ematch::registerEmatchPasses();
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Tamagoyaki optimizer driver\n", registry));
}
