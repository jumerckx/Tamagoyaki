#pragma once

#include "mlir/Pass/Pass.h"

namespace rover {

#define GEN_PASS_DECL
#include "RoverPasses.h.inc"

} // namespace rover
