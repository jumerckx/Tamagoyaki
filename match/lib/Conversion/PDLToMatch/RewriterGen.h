//===- RewriterGen.h - PDL rewriter generation ------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_LIB_CONVERSION_PDLTOMATCH_REWRITERGEN_H_
#define MLIR_LIB_CONVERSION_PDLTOMATCH_REWRITERGEN_H_

#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/PDL/IR/PDLOps.h"
#include "mlir/IR/SymbolTable.h"

namespace mlir {
namespace pdl_to_match {

match::RewriterOp
generateRewriter(pdl::PatternOp pattern, SymbolTable &rewriterSymbolTable,
                 SmallVectorImpl<Value> &usedMatchValues,
                 function_ref<bool(StringRef)> canInferResultTypes = nullptr);

} // namespace pdl_to_match
} // namespace mlir

#endif // MLIR_LIB_CONVERSION_PDLTOMATCH_REWRITERGEN_H_
