//===- MatchDialect.td - Match dialect ---------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_IR_MATCHDIALECT
#define MLIR_DIALECT_MATCH_IR_MATCHDIALECT

include "mlir/IR/OpBase.td"

def Match_Dialect : Dialect {
  let summary = "Intermediate constraint dialect between PDL and PDL_Interp";

  let name = "match";
  let cppNamespace = "::mlir::match";
  let dependentDialects = ["pdl::PDLDialect"];

  let useDefaultTypePrinterParser = 1;
  let extraClassDeclaration = [{
    void registerTypes();
  }];
}

#endif // MLIR_DIALECT_MATCH_IR_MATCHDIALECT
