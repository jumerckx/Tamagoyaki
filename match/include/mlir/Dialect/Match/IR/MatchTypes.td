//===- MatchTypes.td - Match types -------------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_IR_MATCHTYPES
#define MLIR_DIALECT_MATCH_IR_MATCHTYPES

include "mlir/IR/AttrTypeBase.td"
include "mlir/Dialect/Match/IR/MatchDialect.td"

class Match_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<Match_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def Match_Optional : Match_Type<"Optional", "optional"> {
  let summary = "Optional wrapper for a PDL type";
  let parameters = (ins "Type":$innerType);

  let builders = [
    TypeBuilderWithInferredContext<(ins "Type":$innerType), [{
      return $_get(innerType.getContext(), innerType);
    }]>,
  ];
  let genVerifyDecl = 1;
  let assemblyFormat = "`<` $innerType `>`";
  let skipDefaultBuilders = 1;
}

def Match_OptionalType : Type<
  CPred<"::llvm::isa<::mlir::match::OptionalType>($_self)">,
  "match optional type",
  "::mlir::match::OptionalType">;

#endif // MLIR_DIALECT_MATCH_IR_MATCHTYPES
