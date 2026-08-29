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
#include "TamagoyakiTiming.h"

#include "Rover/Rover.h"
#include "circt/Dialect/Comb/CombDialect.h"
#include "circt/Dialect/Comb/CombPasses.h"
#include "circt/Dialect/Datapath/DatapathDialect.h"
#include "circt/Dialect/Datapath/DatapathPasses.h"
#include "circt/Dialect/HW/HWDialect.h"

using namespace circt;
using namespace mlir::equivalence;
using namespace mlir::ematch;

namespace rover {
#define GEN_PASS_REGISTRATION
#include "RoverPasses.h.inc"
} // namespace rover

namespace cl = llvm::cl;

using namespace mlir;
using namespace mlir::equivalence;

//===----------------------------------------------------------------------===//
// Command-line options declaration
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Main Tool Logic
//===----------------------------------------------------------------------===//

int main(int argc, char **argv) {
  // Must precede MlirOptMain, which parses the command line.
  tamagoyaki::registerTimingCLOptions();

  mlir::registerAllPasses();
  // The CIRCT passes the evaluation runs over a persisted e-graph
  // (--canonicalize --comb-int-range-narrowing). circt-opt cannot be used for
  // that: it does not know the equivalence dialect.
  circt::comb::registerPasses();
  circt::datapath::registerPasses();
  mlir::equivalence::registerEquivalencePasses();

  mlir::DialectRegistry registry;
  registry.insert<comb::CombDialect, hw::HWDialect, datapath::DatapathDialect,
                  mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  // Register rover passes
  rover::registerRoverPasses();

  int result = mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Rover", registry));

  tamagoyaki::printTimingReport();
  return result;
}
