//===- EquivalenceDialect.h - Equivalence dialect ------------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef EQUIVALENCE_EQUIVALENCEDIALECT_H
#define EQUIVALENCE_EQUIVALENCEDIALECT_H

// IWYU pragma: begin_keep
#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Pass/Pass.h"

#include <memory>
// IWYU pragma: end_keep

#include "EquivalenceDialect.h.inc"

#define GET_OP_CLASSES
#include "EquivalenceOps.h.inc"

namespace mlir::equivalence {
#define GEN_PASS_DECL
#include "EquivalencePasses.h.inc"

#define GEN_PASS_REGISTRATION
#include "EquivalencePasses.h.inc"
} // namespace mlir::equivalence

#define GET_TYPEDEF_CLASSES
#include "EquivalenceTypes.h.inc"

#define GET_ATTRDEF_CLASSES
#include "EquivalenceAttrs.h.inc"

#endif // EQUIVALENCE_EQUIVALENCEDIALECT_H
