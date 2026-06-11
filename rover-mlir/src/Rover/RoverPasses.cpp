#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "Rover/Rover.h"
#include "circt/Dialect/Comb/CombDialect.h"
#include "circt/Dialect/Comb/CombOps.h"
#include "circt/Dialect/Datapath/DatapathDialect.h"
#include "circt/Dialect/Datapath/DatapathOps.h"
#include "circt/Dialect/HW/HWDialect.h"
#include "circt/Dialect/HW/HWOps.h"
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
#include <cstdint>
#include <limits>
#include <optional>
#include <utility>

namespace rover {

#define GEN_PASS_DEF_ROVERINSERTGRAPHPASS
#define GEN_PASS_DEF_ROVERSATURATEPASS
#define GEN_PASS_DEF_ROVEREXTRACTPASS
#include "RoverPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;
using namespace circt;

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

static Operation *rewriterBuildPartialProduct(PatternRewriter &rewriter,
                                              Operation *mulOp) {
  // Operands of comb.mul
  Value lhs = mulOp->getOperand(0);
  Value rhs = mulOp->getOperand(1);
  unsigned width = lhs.getType().getIntOrFloatBitWidth();

  IntegerType elemTy = cast<IntegerType>(mulOp->getResult(0).getType());
  SmallVector<Type> ppResultTypes(width, elemTy);

  auto ppOp = datapath::PartialProductOp::create(
      rewriter, mulOp->getLoc(), ppResultTypes, ValueRange{lhs, rhs});

  return ppOp.getOperation();
}

static Operation *rewriterBuildZero(PatternRewriter &rewriter,
                                    Operation *operation) {
  // Result type of the original op
  auto type = operation->getResult(0).getType();

  auto zero = hw::ConstantOp::create(rewriter, operation->getLoc(), type,
                                     rewriter.getIntegerAttr(type, 0));

  return zero.getOperation();
}

static Operation *rewriterBuildCompress(PatternRewriter &rewriter,
                                        ValueRange compressOperands) {
  IntegerType elemTy = cast<IntegerType>(compressOperands[0].getType());

  SmallVector<Type> compressResultTypes(2, elemTy);

  auto compressOp =
      datapath::CompressOp::create(rewriter, compressOperands[0].getLoc(),
                                   compressResultTypes, compressOperands);

  return compressOp.getOperation();
}
/// Wrap the body of an hw.module in an equivalence.graph operation, mirroring
/// insertGraphInFunction but for hw.module. Reuses the shared
/// insertGraphInRegion utility; the hw.output terminator's operands become the
/// graph outputs, and a fresh hw.output consuming the graph's results is
/// appended.
static LogicalResult insertGraphInHWModule(hw::HWModuleOp moduleOp) {
  Region &body = moduleOp.getBody();

  if (!body.hasOneBlock()) {
    return failure();
  }

  if (!isa<hw::OutputOp>(body.front().getTerminator())) {
    return moduleOp.emitOpError("hw.module must have an output operation");
  }

  GraphOp graphOp = insertGraphInRegion(body, /*insertSingleElementEqs=*/false);
  if (!graphOp) {
    return failure();
  }

  OpBuilder builder(moduleOp->getContext());
  builder.setInsertionPointToEnd(&body.front());
  hw::OutputOp::create(builder, moduleOp.getLoc(), graphOp->getResults());

  return success();
}

class RoverInsertGraphPass
    : public impl::RoverInsertGraphPassBase<RoverInsertGraphPass> {
public:
  using impl::RoverInsertGraphPassBase<
      RoverInsertGraphPass>::RoverInsertGraphPassBase;

  void runOnOperation() final {
    ModuleOp module = getOperation();

    module.walk([&](hw::HWModuleOp moduleOp) {
      if (failed(insertGraphInHWModule(moduleOp))) {
        signalPassFailure();
      }
    });
  }
};

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

    // Run saturation
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternModule);

    patternModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternModule);
    pdlPattern.registerRewriteFunction("BuildPartialProduct",
                                       rewriterBuildPartialProduct);
    pdlPattern.registerRewriteFunction("BuildCompress", rewriterBuildCompress);
    pdlPattern.registerRewriteFunction("BuildZero", rewriterBuildZero);
    if (failed(equivalence::restoreClassInvariants(irModule))) {
      signalPassFailure();
      return;
    }
    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), std::move(pdlPattern), irModule, maxIters,
        maxNodes);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    }
  }
};

/// Compute the cost of a single operand given precomputed opCosts.
/// Block arguments (no defining op) are free (cost 0).
/// Returns -1 if the defining op is not in the cost map.
static int64_t
lookupOperandCost(Value operand,
                  const DenseMap<Operation *, int64_t> &opCosts) {
  Operation *defOp = operand.getDefiningOp();
  if (!defOp)
    return 0;
  auto it = opCosts.find(defOp);
  if (it == opCosts.end())
    return -1;
  return it->second;
}

/// Prune each ClassOp in the graph to only keep operands that achieve the
/// minimum total cost under the given cost attribute and reduction function.
/// This is a rover-specific e-graph pruning step: it removes non-optimal
/// operands from each e-class without fully extracting the graph.
static void pruneGraphByCost(GraphOp graphOp, int64_t defaultCost,
                             llvm::StringRef costAttributeName,
                             const CostReductionFn &reductionFn) {
  DenseMap<Operation *, int64_t> opCosts =
      computeGraphCosts(graphOp, defaultCost, costAttributeName, reductionFn);

  // Prune: for each ClassOp, keep only operands with minimum cost.
  SmallVector<ClassOp> classOps;
  graphOp.walk([&](ClassOp classOp) { classOps.push_back(classOp); });

  for (ClassOp classOp : classOps) {
    if (classOp.getInputs().size() <= 1)
      continue;

    int64_t minCost = std::numeric_limits<int64_t>::max();
    for (Value operand : classOp.getInputs()) {
      int64_t cost = lookupOperandCost(operand, opCosts);
      if (cost >= 0)
        minCost = std::min(minCost, cost);
    }

    if (minCost == std::numeric_limits<int64_t>::max())
      continue;

    SmallVector<unsigned> toErase;
    for (auto [i, operand] : llvm::enumerate(classOp.getInputs())) {
      int64_t cost = lookupOperandCost(operand, opCosts);
      if (cost == -1 || cost > minCost)
        toErase.push_back(i);
    }

    // Erase in reverse to preserve indices.
    auto mutableInputs = classOp.getInputsMutable();
    for (auto it = toErase.rbegin(); it != toErase.rend(); ++it)
      mutableInputs.erase(*it);
  }

  // Clear min_cost_index so the next selectGreedy starts fresh.
  clearSelection(graphOp, costAttributeName);
}

class RoverExtractPass : public impl::RoverExtractPassBase<RoverExtractPass> {
public:
  using impl::RoverExtractPassBase<RoverExtractPass>::RoverExtractPassBase;

  void runOnOperation() final {
    ModuleOp module = getOperation();

    // select greedily:
    module.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "equivalence.cost"); });

    module.walk([&](GraphOp graphOp) {
      // clearSelection(graphOp, "rover.cost");

      graphOp.walk([&](Operation *op) {
        if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
          return;

        auto [area, delay] =
            llvm::TypeSwitch<Operation *, std::pair<unsigned, unsigned>>(op)
                .Case<comb::AddOp>([](comb::AddOp addOp) {
                  auto numOps = addOp.getNumOperands();
                  // Adder cost = width
                  int addArea =
                      getBinaryOpCost(addOp.getOperand(0), addOp.getOperand(1));
                  auto lhsWidth = getZeroExtendedWidth(addOp.getOperand(0));
                  auto rhsWidth = getZeroExtendedWidth(addOp.getOperand(1));
                  int addDelay = ceilLog2(std::max(
                      lhsWidth, rhsWidth)); // assume a tree of 2-input adders
                  return std::pair{addArea, addDelay + ceilLog2(numOps)};
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
                .Case<comb::AndOp>(
                    [](comb::AndOp andOp) { return std::pair{1, 1}; })
                .Case<comb::OrOp>(
                    [](comb::OrOp andOp) { return std::pair{1, 1}; })
                .Case<comb::MuxOp>(
                    [](comb::MuxOp muxOp) { return std::pair{3, 3}; })
                .Default([](auto) { return std::pair{0, 0}; });

        op->setAttr("equivalence.delay",
                    CostAttr::get(op->getContext(), delay));
        op->setAttr("equivalence.area", CostAttr::get(op->getContext(), area));
      });

      if (extractDelay) {
        pruneGraphByCost(graphOp, /*defaultCost=*/-1, "equivalence.delay",
                         costReductionMax);
        if (debugExtract) {
          llvm::errs() << "=== IR After Delay Pruning ===\n";
          module.print(llvm::errs());
          llvm::errs() << "\n";
        }
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
