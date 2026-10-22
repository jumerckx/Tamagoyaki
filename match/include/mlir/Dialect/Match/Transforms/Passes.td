//===- Passes.td - Match transform passes ------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_TRANSFORMS_PASSES
#define MLIR_DIALECT_MATCH_TRANSFORMS_PASSES

include "mlir/Pass/PassBase.td"

def MatchCombineMatchersPass
    : Pass<"match-combine-matchers", "ModuleOp"> {
  let summary = "Combine multiple match.matcher ops into a single one";
  let dependentDialects = ["match::MatchDialect"];
  let options = [
    Option<"groupByRoot", "group-by-root", "bool", /*default=*/"false",
           "Combine the matchers with the same root operation name into "
           "one matcher per root operation name">,
    // Not upstream (yet): added for the out-of-tree copy in Tamagoyaki.
    Option<"deferLoops", "defer-loops", "bool", /*default=*/"false",
           "Enter a `match.foreach` only after every predicate that does not "
           "depend on it (or on a later loop), so that loops are nested "
           "under the checks of earlier loops instead of hoisted above them">
  ];
}

#endif // MLIR_DIALECT_MATCH_TRANSFORMS_PASSES
