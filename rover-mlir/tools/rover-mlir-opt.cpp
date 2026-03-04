#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
#include "mlir/InitAllPasses.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Support/FileUtilities.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "llvm/Support/SourceMgr.h"

#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "Comb/Comb.h"
#include "Datapath/Datapath.h"
#include "HW/HW.h"

using namespace mlir::equivalence;
using namespace mlir::ematch;

namespace comb {
#define GEN_PASS_REGISTRATION
#include "CombPasses.h.inc"
} // namespace comb

namespace cl = llvm::cl;

using namespace mlir;
using namespace mlir::equivalence;
using namespace comb;

//===----------------------------------------------------------------------===//
// Command-line options declaration
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Main Tool Logic
//===----------------------------------------------------------------------===//

int main(int argc, char **argv) {
  mlir::registerAllPasses();
  mlir::DialectRegistry registry;
  registry.insert<comb::CombDialect, hw::HWDialect, datapath::DatapathDialect,
                  mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  MLIRContext context(registry);

  // Register herbie-mlir passes
  comb::registerCombPasses();

  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Rover", registry));
}
