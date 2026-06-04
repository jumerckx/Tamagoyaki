//===- EmatchDialect.h - Ematch dialect -----------------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef EMATCH_EMATCHDIALECT_H
#define EMATCH_EMATCHDIALECT_H

// IWYU pragma: begin_keep
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Pass/Pass.h"

#include <memory>
// IWYU pragma: end_keep

#include "EmatchDialect.h.inc"

#define GET_OP_CLASSES
#include "EmatchOps.h.inc"

namespace mlir::ematch {
#define GEN_PASS_DECL
#include "EmatchPasses.h.inc"

#define GEN_PASS_REGISTRATION
#include "EmatchPasses.h.inc"
} // namespace mlir::ematch

#endif // EMATCH_EMATCHDIALECT_H
