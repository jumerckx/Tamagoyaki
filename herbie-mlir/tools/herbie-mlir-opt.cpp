#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"

#include "HerbieMLIR.h"
#include "RivalExternalModels.h"

using namespace mlir::equivalence;
using namespace mlir::ematch;

namespace herbie {
#define GEN_PASS_REGISTRATION
#include "HerbieMLIRPasses.h.inc"
} // namespace herbie

int main(int argc, char **argv) {
  tamagoyaki::registerTimingCLOptions();

  mlir::registerAllPasses();
  mlir::equivalence::registerEquivalencePasses();
  mlir::ematch::registerEmatchPasses();

  mlir::DialectRegistry registry;
  registry
      .insert<herbie::HerbieMLIRDialect, mlir::equivalence::EquivalenceDialect,
              mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  // Register Rival external models for RivalCompileableInterface
  herbie::registerRivalExternalModels(registry);

  // Register herbie-mlir passes
  herbie::registerHerbieMLIRPasses();

  int result = mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Herbie", registry));

  tamagoyaki::printTimingReport();
  return result;
}
