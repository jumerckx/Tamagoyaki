//===- MatchOps.h - Match operations ----------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_IR_MATCHOPS_H_
#define MLIR_DIALECT_MATCH_IR_MATCHOPS_H_

#include "mlir/Bytecode/BytecodeOpInterface.h"
#include "mlir/Dialect/Match/IR/MatchTypes.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include <mlir/IR/OpDefinition.h>

namespace mlir {
namespace match {
template <typename ConcreteType>
class Question : public OpTrait::TraitBase<ConcreteType, Question> {};
} // namespace match
} // namespace mlir

#define GET_OP_CLASSES
#include "mlir/Dialect/Match/IR/MatchOps.h.inc"

#endif // MLIR_DIALECT_MATCH_IR_MATCHOPS_H_
