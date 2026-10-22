//===- Passes.h - Match transform passes ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_TRANSFORMS_PASSES_H
#define MLIR_DIALECT_MATCH_TRANSFORMS_PASSES_H

#include "mlir/Pass/Pass.h"
#include <mlir/Support/LLVM.h>

namespace mlir {
class ModuleOp;

namespace match {
#define GEN_PASS_DECL
#include "mlir/Dialect/Match/Transforms/Passes.h.inc"

LogicalResult combineMatchers(ModuleOp module, bool groupByRoot = false,
                              bool deferLoops = false);

#define GEN_PASS_REGISTRATION
#include "mlir/Dialect/Match/Transforms/Passes.h.inc"

} // namespace match
} // namespace mlir

#endif // MLIR_DIALECT_MATCH_TRANSFORMS_PASSES_H
