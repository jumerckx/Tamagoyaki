#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"

#include "EmatchDialect.h"
#include "EquivalenceDialect.h"

#include "Cranelift/Cranelift.h"

namespace cranelift {
#define GEN_PASS_REGISTRATION
#include "CraneliftPasses.h.inc"
} // namespace cranelift

int main(int argc, char **argv) {
  mlir::registerAllPasses();
  mlir::DialectRegistry registry;
  registry.insert<mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  mlir::registerAllDialects(registry);

  // Register cranelift passes
  cranelift::registerCraneliftPasses();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Cranelift", registry));
}
