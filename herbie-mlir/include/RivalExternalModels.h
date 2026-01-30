#ifndef HERBIE_MLIR_RIVAL_EXTERNAL_MODELS_H
#define HERBIE_MLIR_RIVAL_EXTERNAL_MODELS_H

#include "mlir/IR/DialectRegistry.h"

namespace herbie {
void registerRivalExternalModels(mlir::DialectRegistry &registry);
} // namespace herbie

#endif // HERBIE_MLIR_RIVAL_EXTERNAL_MODELS_H
