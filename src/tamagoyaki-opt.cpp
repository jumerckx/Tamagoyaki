//===- tamagoyaki-opt.cpp ---------------------------------------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "TamatchDialect.h"

#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

using namespace mlir;
using namespace mlir::equivalence;
using namespace mlir::tamatch;

namespace mlir::tamatch {
void registerPasses();
}

int main(int argc, char **argv) {
  mlir::registerAllPasses();
  mlir::equivalence::registerPasses();
  mlir::tamatch::registerPasses();
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::tamatch::TamatchDialect>();
  registerAllDialects(registry);

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "Tamagoyaki optimizer driver\n", registry));
}
