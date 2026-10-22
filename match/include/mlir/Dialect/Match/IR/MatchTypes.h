//===- MatchTypes.h - Match types -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_IR_MATCHTYPES_H_
#define MLIR_DIALECT_MATCH_IR_MATCHTYPES_H_

#include "mlir/IR/Types.h"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/Match/IR/MatchOpsTypes.h.inc"

#endif // MLIR_DIALECT_MATCH_IR_MATCHTYPES_H_
