//===- MatchConversionPasses.h - Match conversion passes --------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Registration of the match conversion passes. Upstream, these are registered
// through mlir/Conversion/Passes.h.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_MATCHCONVERSIONPASSES_H
#define MLIR_CONVERSION_MATCHCONVERSIONPASSES_H

#include "mlir/Conversion/MatchToPDLInterp/MatchToPDLInterp.h"
#include "mlir/Conversion/PDLToMatch/PDLToMatch.h"

namespace mlir {

#define GEN_PASS_REGISTRATION
#include "mlir/Conversion/MatchConversionPasses.h.inc"

} // namespace mlir

#endif // MLIR_CONVERSION_MATCHCONVERSIONPASSES_H
