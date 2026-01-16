#include "mlir/IR/Dialect.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "herbie-mlir/HerbieMLIR.h"

int main(int argc, char **argv) {
  mlir::DialectRegistry registry;

  // Register all MLIR dialects
  registry.insert<mlir::func::FuncDialect>();
  registry.insert<mlir::arith::ArithDialect>();

  // Register herbie-mlir passes
  herbie::registerPasses();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Herbie", registry));
}
