#include "Comb/Comb.h"
#include "Datapath/Datapath.h"
#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "HW/HW.h"
#include "Rover/Rover.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/TypeSwitch.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>
#include <cstddef>
#include <optional>
#include <utility>

namespace rover {

#define GEN_PASS_DEF_ROVERSATURATEPASS
#define GEN_PASS_DEF_ROVEREXTRACTPASS
#include "RoverPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;

static unsigned ceilLog2(unsigned v) {
  assert(v > 0 && "undefined for zero");
  // for 32‑bit unsigned; use __builtin_clzll for 64‑bit
  return 32u - __builtin_clz(v - 1);
}

// Helper to get the narrow width if value is zero-extended
unsigned getZeroExtendedWidth(Value val) {
  auto width = val.getType().getIntOrFloatBitWidth();
  auto concat = val.getDefiningOp<comb::ConcatOp>();
  if (!concat)
    return width;

  auto inputs = concat.getInputs();
  if (inputs.size() != 2)
    return width;

  // Check first input is constant zero
  auto prefix = inputs[0].getDefiningOp<hw::ConstantOp>();
  if (!prefix || !prefix.getValue().isZero())
    return width;

  // Return width of the base (non-extended) value
  auto baseType = llvm::dyn_cast<IntegerType>(inputs[1].getType());
  if (!baseType)
    return width;

  return baseType.getWidth();
}

unsigned getBinaryOpCost(Value lhs, Value rhs) {
  auto lhsWidth = getZeroExtendedWidth(lhs);
  auto rhsWidth = getZeroExtendedWidth(rhs);

  // Cost is the maximum narrow width
  return lhsWidth * rhsWidth;
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

static LogicalResult rewriterBuildZero(PatternRewriter &rewriter,
                                       PDLResultList &results,
                                       ArrayRef<PDLValue> args) {
  auto operation = args[0].cast<Operation *>();

  // Operands of comb.mul
  auto type = operation->getResult(0).getType();
  auto zero = hw::ConstantOp::create(rewriter, operation->getLoc(), type,
                                     rewriter.getIntegerAttr(type, 0));

  // Hand the comb.add back to PDL so it can wire up the replacement.
  results.push_back(zero.getOperation());
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

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    ModuleOp patternModule;
    ModuleOp irModule;
    OwningOpRef<ModuleOp> parsedPatternsModule;

    if (!patternsFile.empty()) {
      // Parse patterns from external file; the input module is the IR module.
      irModule = module;
      parsedPatternsModule =
          parseSourceFile<ModuleOp>(patternsFile, module.getContext());
      if (!parsedPatternsModule) {
        emitError(module.getLoc())
            << "failed to parse patterns file: " << patternsFile;
        return signalPassFailure();
      }
      patternModule = parsedPatternsModule.release();
    } else {
      patternModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "patterns"));
      irModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "ir"));

      if (!patternModule || !irModule)
        return;
    }

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
    pdlPattern.registerRewriteFunction("BuildZero", rewriterBuildZero);
    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), std::move(pdlPattern), irModule, maxIters,
        maxNodes);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    }
  }
};

class RoverExtractPass : public impl::RoverExtractPassBase<RoverExtractPass> {
public:
  using impl::RoverExtractPassBase<RoverExtractPass>::RoverExtractPassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    // Check if the top-level module is named "ir"
    if (!irModule && module.getName() == "ir") {
      irModule = module;
    }

    if (!irModule) {
      llvm::errs() << "=== IR Module Not Detected ===\n";
      module.print(llvm::errs());
      llvm::errs() << "\n";
      return;
    }

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
                  if (addOp.getNumOperands() == 2 &&
                      addOp.getOperand(0) == addOp.getOperand(1)) {
                    return std::pair{0, 0};
                  }
                  int addArea =
                      addOp.getResult().getType().getIntOrFloatBitWidth();
                  auto lhsWidth = getZeroExtendedWidth(addOp.getOperand(0));
                  auto rhsWidth = getZeroExtendedWidth(addOp.getOperand(1));
                  int addDelay = ceilLog2(std::max(
                      lhsWidth, rhsWidth)); // assume a tree of 2-input adders
                  return std::pair{addArea, addDelay};
                  // return std::pair{10000, addDelay};
                })
                .Case<comb::MulOp>([](comb::MulOp mulOp) {
                  // Multiplier cost = width(lhs) * width(rhs)
                  auto lhsWidth = getZeroExtendedWidth(mulOp.getOperand(0));
                  auto rhsWidth = getZeroExtendedWidth(mulOp.getOperand(1));

                  auto maxWidth = std::max(lhsWidth, rhsWidth);

                  return std::pair{10000, maxWidth};
                })
                .Case<comb::ShlOp>([](comb::ShlOp shlOp) {
                  auto shlArea =
                      getBinaryOpCost(shlOp.getLhs(), shlOp.getRhs());
                  auto shiftBy = getZeroExtendedWidth(shlOp.getRhs());
                  return std::pair{shlArea, shiftBy};
                })
                .Case<datapath::PartialProductOp>(
                    [](datapath::PartialProductOp ppOp) {
                      // Partial product cost = width(lhs) * width(rhs)
                      // Delay is single gate
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
                      auto numRes = compressOp.getNumResults();

                      return std::pair{compressCost / numRes, ceilLog2(numOps)};
                    })
                .Case<comb::ExtractOp>(
                    [](comb::ExtractOp extractOp) { return std::pair{0, 0}; })
                .Case<comb::ConcatOp>(
                    [](comb::ConcatOp concatOp) { return std::pair{0, 0}; })
                .Default([](auto) { return std::pair{0, 1}; });

        op->setAttr("equivalence.delay",
                    CostAttr::get(op->getContext(), delay));
        op->setAttr("equivalence.area", CostAttr::get(op->getContext(), area));
      });

      if (extractDelay) {
        selectGreedy(graphOp, /*defaultCost=*/-1, "equivalence.delay",
                     costReductionMax);
        extractFromGraph(graphOp, true);
        llvm::errs() << "=== IR After Costing ===\n";
        irModule.print(llvm::errs());
        llvm::errs() << "\n";
      }

      selectGreedy(graphOp, /*defaultCost=*/-1, "equivalence.area");
      extractFromGraph(graphOp);

      graphOp.walk([&](Operation *op) {
        if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
          return;

        op->removeAttr("equivalence.area");
        op->removeAttr("equivalence.delay");
        if (op->getUses().empty())
          op->erase();
      });
      inlineGraphOp(graphOp);

      // clearSelection(graphOp, "rover.cost");
    });
  }
};

} // namespace rover
