//===- EmatchDialect.cpp - Ematch dialect -----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Definition of the ematch dialect: op registration and type asm hooks. The
// transforms (lowering, saturation) live in EmatchTransforms.cpp and the pass
// drivers in EmatchPasses.cpp.
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"

#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/StringRef.h"

using namespace mlir;
using namespace mlir::ematch;

#include "EmatchDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// Ematch dialect.
//===----------------------------------------------------------------------===//

void mlir::ematch::EmatchDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "EmatchOps.cpp.inc"

      >();
}

mlir::Type
mlir::ematch::EmatchDialect::parseType(mlir::DialectAsmParser &parser) const {
  StringRef typeName;
  if (parser.parseKeyword(&typeName))
    return Type();
  return {};
}

void mlir::ematch::EmatchDialect::printType(mlir::Type type,
                                            mlir::DialectAsmPrinter &os) const {
  os << "unknown";
}

//===----------------------------------------------------------------------===//
// Ematch ops
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "EmatchOps.cpp.inc"
