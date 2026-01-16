#pragma once

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Pass/Pass.h"

namespace herbie {

// Forward declarations for passes
#define GEN_PASS_DECL
#include "HerbieMLIRPasses.h.inc"

} // namespace herbie
