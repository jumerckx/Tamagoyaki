#pragma once

#include "mlir/Pass/Pass.h"

namespace cranelift {

#define GEN_PASS_DECL
#include "CraneliftPasses.h.inc"

} // namespace cranelift
