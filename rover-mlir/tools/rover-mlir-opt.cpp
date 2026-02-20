#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Dialect.h"
#include "mlir/InitAllDialects.h"
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
  mlir::DialectRegistry registry;
  registry.insert<comb::CombDialect, hw::HWDialect,
                  mlir::equivalence::EquivalenceDialect,
                  mlir::ematch::EmatchDialect>();
  registerAllDialects(registry);

  MLIRContext context(registry);

  // Register herbie-mlir passes
  comb::registerCombPasses();
  // Set up the input file.
  //   std::unique_ptr<llvm::MemoryBuffer> input;

  //   {
  //     std::string errorMessage;
  //     input = openInputFile(inputFilename, &errorMessage);
  //     if (!input) {
  //       llvm::errs() << errorMessage << "\n";
  //       return 0;
  //     }
  //   }

  //   llvm::SourceMgr sourceMgr;
  //   sourceMgr.AddNewSourceBuffer(std::move(input), llvm::SMLoc());
  //   OwningOpRef<ModuleOp> module;
  //   { module = parseSourceFile<ModuleOp>(sourceMgr, &context); }
  //   if (!module)
  //     return 0;
  // Register rover-mlir passes
  //   rover::registerHerbieMLIRPasses();
  //   mlir::ModuleOp module = getOperation();

  //   ModuleOp patternModule = module.lookupSymbol<ModuleOp>(
  //       StringAttr::get(module->getContext(), "patterns"));
  //   ModuleOp irModule = module.lookupSymbol<ModuleOp>(
  //       StringAttr::get(module->getContext(), "ir"));

  //   if (!patternModule || !irModule)
  //     return;

  // Run saturation
  //   mlir::ematch::convertEmatchOpsToApplyRewrites(patternModule);
  //   bool saturationSuccess = mlir::ematch::runSaturation(
  //       irModule->getContext(), patternModule, irModule, 10);
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MLIR optimizer for Rover", registry));
}
