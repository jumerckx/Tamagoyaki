#include "Comb.h"
#include "Datapath/Datapath.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "HW/HW.h"
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
#include "llvm/ADT/TypeSwitch.h"
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

// Helper to get the narrow width if value is zero-extended
std::optional<unsigned> getZeroExtendedWidth(Value val) {
  auto concat = val.getDefiningOp<comb::ConcatOp>();
  if (!concat)
    return std::nullopt;

  auto inputs = concat.getInputs();
  if (inputs.size() != 2)
    return std::nullopt;

  // Check first input is constant zero
  auto prefix = inputs[0].getDefiningOp<hw::ConstantOp>();
  if (!prefix || !prefix.getValue().isZero())
    return std::nullopt;

  // Return width of the base (non-extended) value
  auto baseType = llvm::dyn_cast<IntegerType>(inputs[1].getType());
  if (!baseType)
    return std::nullopt;

  return baseType.getWidth();
}

unsigned getMulOpCost(comb::MulOp mulOp) {
  auto lhsWidth = getZeroExtendedWidth(mulOp.getOperand(0));
  auto rhsWidth = getZeroExtendedWidth(mulOp.getOperand(1));

  if (!lhsWidth)
    lhsWidth = mulOp.getOperand(0).getType().getIntOrFloatBitWidth();

  if (!rhsWidth)
    rhsWidth = mulOp.getOperand(1).getType().getIntOrFloatBitWidth();

  // Cost is the maximum narrow width
  return (*lhsWidth) * (*rhsWidth);
}

static LogicalResult rewriterBuildPartialProductTree(PatternRewriter &rewriter,
                                                     PDLResultList &results,
                                                     ArrayRef<PDLValue> args) {
  auto *mulOp = args[0].cast<Operation *>();

  // Operands of comb.mul
  Value lhs = mulOp->getOperand(0);
  Value rhs = mulOp->getOperand(1);
  unsigned width = lhs.getType().getIntOrFloatBitWidth();

  IntegerType elemTy = cast<IntegerType>(mulOp->getResult(0).getType());

  auto addOp = comb::AddOp::create(rewriter, mulOp->getLoc(), elemTy,
                                   ValueRange{lhs, rhs});

  // Hand the comb.add back to PDL so it can wire up the replacement.
  results.push_back(addOp.getOperation());
  return success();
}

// static Operation *rewriterBuildPartialProductTree(PatternRewriter &rewriter,
//                                                   Operation *mulOp) {
//   // auto *mulOp = args[0].cast<Operation *>();

//   // Operands of comb.mul
//   Value lhs = mulOp->getOperand(0);
//   Value rhs = mulOp->getOperand(1);
//   unsigned width = lhs.getType().getIntOrFloatBitWidth();

//   IntegerType elemTy = cast<IntegerType>(mulOp->getResult(0).getType());
//   // rewriter.setInsertionPoint(mulOp);
//   auto addOp = comb::AddOp::create(rewriter, mulOp->getLoc(), elemTy,
//                                    ValueRange{lhs, rhs});

//   return addOp;
// }

class RoverOptimizePass
    : public impl::RoverOptimizePassBase<RoverOptimizePass> {
public:
  using impl::RoverOptimizePassBase<RoverOptimizePass>::RoverOptimizePassBase;

  void getDependentDialects(mlir::DialectRegistry &registry) const override {
    registry.insert<mlir::equivalence::EquivalenceDialect>();
    registry.insert<mlir::func::FuncDialect>();
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
    registry.insert<datapath::DatapathDialect>();
  }

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    ModuleOp patternModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternModule || !irModule)
      return;

    irModule.walk([&](mlir::func::FuncOp funcOp) {
      llvm::errs() << "Step 2: Inserting equivalence graph...\n";

      if (mlir::failed(mlir::equivalence::insertGraphInFunction(
              funcOp, /*insertSingleElementEqs=*/false))) {
        funcOp.emitError() << "Failed to insert equivalence graph";
        return signalPassFailure();
      }

      llvm::errs() << "  Graph inserted successfully\n";
    });

    // Run saturation
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternModule);

    patternModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternModule);
    pdlPattern.registerRewriteFunction("BuildPartialProduct",
                                       rewriterBuildPartialProductTree);
    bool saturationSuccess = mlir::ematch::runSaturationWithPDL(
        irModule->getContext(), std::move(pdlPattern), irModule, 1);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    } else {
      llvm::errs() << "  Saturation completed\n";
    }
    llvm::errs() << "=== IR After Saturation ===\n";
    irModule.print(llvm::errs());
    llvm::errs() << "\n";
    // select greedily:
    irModule.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "rover.cost"); });

    irModule.walk([&](GraphOp graphOp) {
      // clearSelection(graphOp, "rover.cost");

      graphOp.walk([&](Operation *op) {
        if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
          return;

        unsigned cost = llvm::TypeSwitch<Operation *, unsigned>(op)
                            .Case<comb::AddOp>([](auto) { return 1; })
                            .Case<comb::MulOp>([](comb::MulOp mulOp) {
                              return getMulOpCost(mulOp);
                            })
                            .Case<comb::SubOp>([](auto) { return 1; })
                            .Case<comb::ShlOp>([](auto) { return 2; })
                            .Default([](auto) { return 1; });
        op->setAttr("rover.cost", CostAttr::get(op->getContext(), cost));
      });

      selectGreedy(graphOp, /*defaultCost=*/-1, "rover.cost");
      // extractFromGraph(graphOp);
      // inlineGraphOp(graphOp);
    });
    llvm::errs() << "=== IR After Saturation ===\n";
    irModule.print(llvm::errs());
    llvm::errs() << "\n";
    llvm::errs() << "=== End Rover Optimize ===\n";
  }
};

// ===----------------------------------------------------------------------===
// // LowerHerbieSoundOpsPass
// ===----------------------------------------------------------------------===
// //

} // namespace comb
