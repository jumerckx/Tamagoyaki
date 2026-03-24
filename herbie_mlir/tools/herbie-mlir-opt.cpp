#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"

#include "BatchEvaluateExternalModels.h"
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

  // Ensure the herbie, math and arith dialects are loaded whenever the
  // ematch dialect is loaded. This is needed because ematch-saturate
  // executes PDL bytecode that may create herbie ops from these dialects.
  registry.addExtension(
      +[](mlir::MLIRContext *ctx, mlir::ematch::EmatchDialect *) {
        ctx->getOrLoadDialect<herbie::HerbieMLIRDialect>();
        ctx->getOrLoadDialect<mlir::math::MathDialect>();
        ctx->getOrLoadDialect<mlir::arith::ArithDialect>();
      });

  // Register Rival external models for RivalCompileableInterface
  herbie::registerRivalExternalModels(registry);

  // Register BatchEvaluate external models for sample-based evaluation
  herbie::registerBatchEvaluateExternalModels(registry);

  // Register herbie-mlir passes
  herbie::registerHerbieMLIRPasses();

  int result = mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Herbie", registry));

  tamagoyaki::printTimingReport();
  return result;
}
