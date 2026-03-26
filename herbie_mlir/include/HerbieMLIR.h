#pragma once

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Pass/Pass.h"

#include "HerbieMLIRDialect.h.inc"

#include "HerbieMLIREnums.h.inc"

#define GET_ATTRDEF_CLASSES
#include "HerbieMLIRAttrs.h.inc"

#define GET_OP_CLASSES
#include "HerbieMLIROps.h.inc"

namespace herbie {

#define GEN_PASS_DECL
#include "HerbieMLIRPasses.h.inc"

} // namespace herbie
