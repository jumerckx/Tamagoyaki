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

#include "HWDialect.h.inc"

// #include "HWMLIREnums.h.inc"

#define GET_ATTRDEF_CLASSES
#include "HWAttrs.h.inc"

#define GET_OP_CLASSES
#include "HWOps.h.inc"

namespace hw {

#define GEN_PASS_DECL
#include "HWPasses.h.inc"

} // namespace hw
