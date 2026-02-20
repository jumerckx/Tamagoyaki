#include "Comb.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "mlir/Analysis/TopologicalSortUtils.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <optional>
#include <string>
#include <utility>
#include <vector>

namespace comb {

#define GEN_PASS_DEF_ROVEROPTIMIZEPASS
#include "CombPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;

class RoverOptimizePass
    : public impl::RoverOptimizePassBase<RoverOptimizePass> {
public:
  using impl::RoverOptimizePassBase<RoverOptimizePass>::RoverOptimizePassBase;

  void getDependentDialects(mlir::DialectRegistry &registry) const override {
    registry.insert<mlir::equivalence::EquivalenceDialect>();
    registry.insert<mlir::func::FuncDialect>();
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    ModuleOp patternModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternModule || !irModule)
      return;

    // Run saturation
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternModule);
    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), patternModule, irModule, 4);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    } else {
      llvm::errs() << "  Saturation completed\n";
    }

    llvm::errs() << "=== End Rover Optimize ===\n";
  }
};

// ===----------------------------------------------------------------------===
// // LowerHerbieSoundOpsPass
// ===----------------------------------------------------------------------===
// //

} // namespace comb
