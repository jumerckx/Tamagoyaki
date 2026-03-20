#ifndef HERBIE_MLIR_BATCH_EVALUATE_EXTERNAL_MODELS_H
#define HERBIE_MLIR_BATCH_EVALUATE_EXTERNAL_MODELS_H

#include "mlir/IR/DialectRegistry.h"

namespace herbie {
void registerBatchEvaluateExternalModels(mlir::DialectRegistry &registry);
} // namespace herbie

#endif // HERBIE_MLIR_BATCH_EVALUATE_EXTERNAL_MODELS_H
