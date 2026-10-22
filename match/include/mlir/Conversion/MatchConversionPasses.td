//===-- MatchConversionPasses.td - Match conversion passes -*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Upstream, these passes are declared in mlir/Conversion/Passes.td. The
// out-of-tree copy cannot extend that file, so they live here instead.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_MATCHCONVERSIONPASSES
#define MLIR_CONVERSION_MATCHCONVERSIONPASSES

include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// PDLToMatch
//===----------------------------------------------------------------------===//

def ConvertPDLToMatchPass : Pass<"convert-pdl-to-match", "ModuleOp"> {
  let summary = "Convert PDL patterns to match matchers";
  let dependentDialects = ["match::MatchDialect"];
}

//===----------------------------------------------------------------------===//
// MatchToPDLInterp
//===----------------------------------------------------------------------===//

def ConvertMatchToPDLInterpPass
    : Pass<"convert-match-to-pdl-interp", "ModuleOp"> {
  let summary = "Lower match matchers to PDL interpreter ops";
  let dependentDialects = ["pdl_interp::PDLInterpDialect"];
}

#endif // MLIR_CONVERSION_MATCHCONVERSIONPASSES
