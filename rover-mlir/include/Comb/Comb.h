#pragma once

#include "CombDialect.h.inc"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

// #include "CombMLIREnums.h.inc"

#define GET_ATTRDEF_CLASSES
#include "CombAttrs.h.inc"

#define GET_OP_CLASSES
#include "CombOps.h.inc"
