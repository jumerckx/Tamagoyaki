#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "HerbieMLIR.h"

namespace herbie {
#define GEN_PASS_REGISTRATION
#include "HerbieMLIRPasses.h.inc"
} // namespace herbie

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;

  // Register all MLIR dialects
  registry.insert<mlir::func::FuncDialect>();
  registry.insert<mlir::arith::ArithDialect>();

  // Register herbie-mlir passes
  herbie::registerHerbieMLIRPasses();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Herbie", registry));
}
