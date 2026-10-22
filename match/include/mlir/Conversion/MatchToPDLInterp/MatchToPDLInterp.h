//===- MatchToPDLInterp.h - Match to PDL interpreter lowering ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_MATCHTOPDLINTERP_MATCHTOPDLINTERP_H
#define MLIR_CONVERSION_MATCHTOPDLINTERP_MATCHTOPDLINTERP_H

#include "mlir/Pass/Pass.h"
#include "mlir/Support/LLVM.h"

namespace mlir {
class ModuleOp;
class PDLPatternConfigSet;

#define GEN_PASS_DECL_CONVERTMATCHTOPDLINTERPPASS
#include "mlir/Conversion/MatchConversionPasses.h.inc"

LogicalResult convertMatchToPDLInterp(
    ModuleOp module,
    DenseMap<Operation *, PDLPatternConfigSet *> *configMap = nullptr);

} // namespace mlir

#endif // MLIR_CONVERSION_MATCHTOPDLINTERP_MATCHTOPDLINTERP_H
