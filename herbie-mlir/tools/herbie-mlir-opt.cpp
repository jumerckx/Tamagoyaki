#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "EquivalenceDialect.h"
#include "TamatchDialect.h"

#include "HerbieMLIR.h"
#include "RivalExternalModels.h"

using namespace mlir::equivalence;
using namespace mlir::tamatch;

namespace herbie {
#define GEN_PASS_REGISTRATION
#include "HerbieMLIRPasses.h.inc"
} // namespace herbie

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::tamatch::TamatchDialect>();
  registerAllDialects(registry);

  // Register Rival external models for RivalCompileableInterface
  herbie::registerRivalExternalModels(registry);

  // Register herbie-mlir passes
  herbie::registerHerbieMLIRPasses();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Herbie", registry));
}
