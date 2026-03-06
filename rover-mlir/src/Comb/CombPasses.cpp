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

#define GEN_PASS_DEF_ROVERSATURATEPASS
#define GEN_PASS_DEF_ROVEREXTRACTPASS
#include "CombPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;

#include <cassert>
#include <cstdint>

static unsigned ceilLog2(unsigned v) {
  assert(v > 0 && "undefined for zero");
  // for 32‑bit unsigned; use __builtin_clzll for 64‑bit
  return 32u - __builtin_clz(v - 1);
}

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

unsigned getBinaryOpCost(Value lhs, Value rhs) {
  auto lhsWidth = getZeroExtendedWidth(lhs);
  auto rhsWidth = getZeroExtendedWidth(rhs);

  if (!lhsWidth)
    lhsWidth = lhs.getType().getIntOrFloatBitWidth();

  if (!rhsWidth)
    rhsWidth = rhs.getType().getIntOrFloatBitWidth();

  // Cost is the maximum narrow width
  return (*lhsWidth) * (*rhsWidth);
}

static LogicalResult rewriterBuildPartialProduct(PatternRewriter &rewriter,
                                                 PDLResultList &results,
                                                 ArrayRef<PDLValue> args) {
  auto *mulOp = args[0].cast<Operation *>();

  // Operands of comb.mul
  Value lhs = mulOp->getOperand(0);
  Value rhs = mulOp->getOperand(1);
  unsigned width = lhs.getType().getIntOrFloatBitWidth();

  IntegerType elemTy = cast<IntegerType>(mulOp->getResult(0).getType());
  SmallVector<Type> ppResultTypes(width, elemTy);

  auto ppOp = datapath::PartialProductOp::create(
      rewriter, mulOp->getLoc(), ppResultTypes, ValueRange{lhs, rhs});

  // Hand the comb.add back to PDL so it can wire up the replacement.
  results.push_back(ppOp.getOperation());
  return success();
}

static LogicalResult rewriterBuildCompress(PatternRewriter &rewriter,
                                           PDLResultList &results,
                                           ArrayRef<PDLValue> args) {
  auto compressOperands = args[0].cast<ValueRange>();

  if (compressOperands.size() < 3)
    return failure();

  IntegerType elemTy = cast<IntegerType>(compressOperands[0].getType());

  SmallVector<Type> compressResultTypes(2, elemTy);

  auto compressOp =
      datapath::CompressOp::create(rewriter, compressOperands[0].getLoc(),
                                   compressResultTypes, compressOperands);

  // Hand the comb.add back to PDL so it can wire up the replacement.
  results.push_back(compressOp.getOperation());
  return success();
}

class RoverSaturatePass
    : public impl::RoverSaturatePassBase<RoverSaturatePass> {
public:
  using impl::RoverSaturatePassBase<RoverSaturatePass>::RoverSaturatePassBase;

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
      if (mlir::failed(mlir::equivalence::insertGraphInFunction(
              funcOp, /*insertSingleElementEqs=*/false))) {
        funcOp.emitError() << "Failed to insert equivalence graph";
        return signalPassFailure();
      }
    });

    // Run saturation
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternModule);

    patternModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternModule);
    pdlPattern.registerRewriteFunction("BuildPartialProduct",
                                       rewriterBuildPartialProduct);
    pdlPattern.registerRewriteFunction("BuildCompress", rewriterBuildCompress);
    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), std::move(pdlPattern), irModule, 3);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    }

    return;
  }
};

class RoverExtractPass : public impl::RoverExtractPassBase<RoverExtractPass> {
public:
  using impl::RoverExtractPassBase<RoverExtractPass>::RoverExtractPassBase;

  void getDependentDialects(mlir::DialectRegistry &registry) const override {
    registry.insert<mlir::equivalence::EquivalenceDialect>();
    registry.insert<mlir::func::FuncDialect>();
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
    registry.insert<datapath::DatapathDialect>();
  }

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!irModule)
      return;

    // select greedily:
    irModule.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "equivalence.cost"); });

    irModule.walk([&](GraphOp graphOp) {
      // clearSelection(graphOp, "rover.cost");

      graphOp.walk([&](Operation *op) {
        if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
          return;

        auto [area, delay] =
            llvm::TypeSwitch<Operation *, std::pair<unsigned, unsigned>>(op)
                .Case<comb::AddOp>([](comb::AddOp addOp) {
                  // Adder cost = width
                  auto addArea =
                      addOp.getResult().getType().getIntOrFloatBitWidth();
                  auto addDelay = ceilLog2(addArea);
                  (void)addDelay;
                  // return std::pair{addArea, addDelay};
                  return std::pair{1000, 1000};
                })
                .Case<comb::MulOp>([](comb::MulOp mulOp) {
                  // Multiplier cost = width(lhs) * width(rhs)
                  return std::pair{10000, 10000};
                })
                .Case<comb::ShlOp>([](comb::ShlOp shlOp) {
                  auto shlArea =
                      getBinaryOpCost(shlOp.getLhs(), shlOp.getRhs());
                  auto shiftBy = getZeroExtendedWidth(shlOp.getRhs());
                  if (shiftBy)
                    return std::pair{shlArea, *shiftBy};

                  return std::pair{
                      shlArea,
                      shlOp.getRhs().getType().getIntOrFloatBitWidth()};
                })
                .Case<datapath::PartialProductOp>(
                    [](datapath::PartialProductOp ppOp) {
                      // Partial product cost = width(lhs) * width(rhs)
                      // return getBinaryOpCost(ppOp.getLhs(), ppOp.getRhs());
                      // Delay is small
                      return std::pair{
                          getBinaryOpCost(ppOp.getLhs(), ppOp.getRhs()) /
                              ppOp.getNumResults(),
                          1};
                    })
                .Case<datapath::CompressOp>(
                    [](datapath::CompressOp compressOp) {
                      // Compress cost = num bits of array
                      auto compressCost = 0;
                      for (auto operand : compressOp.getInputs())
                        compressCost +=
                            operand.getType().getIntOrFloatBitWidth();

                      auto numOps = compressOp.getNumOperands();

                      return std::pair{compressCost / numOps, ceilLog2(numOps)};
                    })
                .Default([](auto) { return std::pair{0, 1}; });

        op->setAttr("equivalence.cost", CostAttr::get(op->getContext(), area));
      });

      selectGreedy(graphOp, /*defaultCost=*/-1, "equivalence.cost");
      llvm::errs() << "=== IR After Costing ===\n";
      irModule.print(llvm::errs());
      llvm::errs() << "\n";

      extractFromGraph(graphOp);
      graphOp.walk([&](Operation *op) {
        if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
          return;

        op->removeAttr("equivalence.cost");
        if (op->getUses().empty())
          op->erase();
      });
      inlineGraphOp(graphOp);

      // clearSelection(graphOp, "rover.cost");
    });
  }
};

} // namespace comb
