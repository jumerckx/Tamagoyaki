#ifndef EMATCH_UTILS_H
#define EMATCH_UTILS_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"

namespace mlir::ematch {

/// Run equality saturation on the given IR module using the provided pattern
/// module. The patternModule is consumed (removed from parent).
/// Returns true on success.
bool runSaturation(MLIRContext *ctx, ModuleOp patternModule, ModuleOp irModule,
                   int maxIters);

} // namespace mlir::ematch

#endif // EMATCH_UTILS_H
