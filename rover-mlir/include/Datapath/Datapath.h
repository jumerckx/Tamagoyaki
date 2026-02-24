#pragma once

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/StringExtras.h"

#include "DatapathDialect.h.inc"

// #include "DatapathMLIREnums.h.inc"

#define GET_ATTRDEF_CLASSES
#include "DatapathAttrs.h.inc"

#define GET_OP_CLASSES
#include "DatapathOps.h.inc"

namespace datapath {

#define GEN_PASS_DECL
#include "DatapathPasses.h.inc"

// mlir::ParseResult
// parseCompressFormat(mlir::OpAsmParser &parser,
//                     llvm::SmallVectorImpl<mlir::Type> &inputTypes,
//                     llvm::SmallVectorImpl<mlir::Type> &resultTypes);

// void printCompressFormat(mlir::OpAsmPrinter &printer, mlir::Operation *op,
//                          mlir::TypeRange inputTypes,
//                          mlir::TypeRange resultTypes);

} // namespace datapath
