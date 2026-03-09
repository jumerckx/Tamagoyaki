#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "HerbieMLIR.h"
#include "HerbieMLIROpInterfaces.h"
#include "IntervalSearch.h"
#include "LocalError.h"
#include "TamagoyakiTiming.h"
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
#include "mlir/Parser/Parser.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <math.h>
#include <mpfr.h>
#include <optional>
#include <rival.h>
#include <string>
#include <utility>
#include <vector>

#define DEBUG_TYPE "herbie"

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATEPASS
#define GEN_PASS_DEF_RIVALEVALUATEPASS
#define GEN_PASS_DEF_HERBIEPRINTTOPOSORT
#define GEN_PASS_DEF_HERBIEOPTIMIZEPASS
#define GEN_PASS_DEF_LOWERHERBIESOUNDOPSPASS
#define GEN_PASS_DEF_LOWERHERBIECONSTANTPASS
#include "HerbieMLIRPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;

// Helper function to map herbie.constant symbols to their floating-point values
static double getConstantValue(::herbie::Constant constantEnum) {
  switch (constantEnum) {
  case ::herbie::Constant::Const_E:
    return M_E;
  case ::herbie::Constant::Const_PI:
    return M_PI;
  case ::herbie::Constant::Const_M_2_SQRTPI:
    return M_2_SQRTPI;
  case ::herbie::Constant::Const_LOG2E:
    return M_LOG2E;
  case ::herbie::Constant::Const_PI_2:
    return M_PI_2;
  case ::herbie::Constant::Const_SQRT2:
    return M_SQRT2;
  case ::herbie::Constant::Const_LOG10E:
    return M_LOG10E;
  case ::herbie::Constant::Const_PI_4:
    return M_PI_4;
  case ::herbie::Constant::Const_SQRT1_2:
    return M_SQRT1_2;
  case ::herbie::Constant::Const_LN2:
    return M_LN2;
  case ::herbie::Constant::Const_M_1_PI:
    return M_1_PI;
  case ::herbie::Constant::Const_INFINITY:
    return INFINITY;
  case ::herbie::Constant::Const_LN10:
    return M_LN10;
  case ::herbie::Constant::Const_M_2_PI:
    return M_2_PI;
  }
  llvm_unreachable("Unknown herbie constant");
}

namespace {

class HerbieMLIRTemplatePass
    : public impl::HerbieMLIRTemplatePassBase<HerbieMLIRTemplatePass> {
public:
  using impl::HerbieMLIRTemplatePassBase<
      HerbieMLIRTemplatePass>::HerbieMLIRTemplatePassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();
    (void)module;

    llvm::errs() << "=== Rival Interval Arithmetic Demo ===\n";
    llvm::errs() << "Computing: f(x, y) = x^2 + y with x=1.5, y=2.0\n";
    llvm::errs() << "Expected: 1.5^2 + 2.0 = 4.25\n\n";

    mpfr_t x, y;
    mpfr_init2(x, 53);
    mpfr_init2(y, 53);
    mpfr_set_d(x, 1.5, MPFR_RNDN);
    mpfr_set_d(y, 2.0, MPFR_RNDN);

    const mpfr_t *args[] = {&x, &y};

    mpfr_t result;
    mpfr_init2(result, 53);
    mpfr_t *outs[] = {&result};

    RivalExprArena *arena = rival_expr_arena_new();
    if (!arena) {
      llvm::errs() << "Failed to create arena\n";
      return;
    }

    uint32_t var_x = rival_expr_var(arena, "x");
    uint32_t var_y = rival_expr_var(arena, "y");
    uint32_t x_sq = rival_expr_pow2(arena, var_x);
    uint32_t expr_root = rival_expr_add(arena, x_sq, var_y);

    const char *var_names[] = {"x", "y"};
    uint32_t roots[] = {expr_root};

    RivalDiscretization *disc = rival_disc_f64(53);
    RivalMachine *machine =
        rival_machine_new(arena, roots, 1, var_names, 2, disc, 200, 1000);

    if (!machine) {
      llvm::errs() << "Failed to create machine\n";
      rival_disc_free(disc);
      rival_expr_arena_free(arena);
      return;
    }

    RivalError err = rival_apply(machine, args, 2, outs, 1, nullptr, 10, 200);

    if (err == RIVAL_ERROR_OK) {
      double res = mpfr_get_d(result, MPFR_RNDN);
      llvm::errs() << "Result: " << res << "\n";
      if (res == 4.25) {
        llvm::errs() << "SUCCESS: Rival integration working!\n";
      }
    } else {
      llvm::errs() << "Evaluation failed with error: "
                   << rival_error_message(err) << "\n";
    }

    rival_machine_free(machine);
    rival_disc_free(disc);
    rival_expr_arena_free(arena);
    mpfr_clear(x);
    mpfr_clear(y);
    mpfr_clear(result);

    llvm::errs() << "=== End Rival Demo ===\n";
  }
};

class RivalEvaluatePass
    : public impl::RivalEvaluatePassBase<RivalEvaluatePass> {
public:
  using impl::RivalEvaluatePassBase<RivalEvaluatePass>::RivalEvaluatePassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    module.walk([&](mlir::func::FuncOp funcOp) {
      auto iface =
          mlir::dyn_cast<RivalCompileableInterface>(funcOp.getOperation());
      if (!iface) {
        llvm::errs() << "Function " << funcOp.getName()
                     << " does not implement RivalCompileableInterface\n";
        return;
      }

      llvm::errs() << "=== Rival Evaluate: " << funcOp.getName() << " ===\n";

      RivalExprArena *arena = rival_expr_arena_new();
      if (!arena) {
        llvm::errs() << "Failed to create arena\n";
        return;
      }

      auto exprs = iface.compile(arena, {});
      if (exprs.size() != 1) {
        llvm::errs()
            << "Currently only single-result operations are supported\n";
      }
      auto exprRoot = exprs[0];

      size_t numArgs = funcOp.getNumArguments();
      std::vector<std::string> varNames;
      std::vector<const char *> varNamePtrs;
      varNames.reserve(numArgs);
      for (size_t i = 0; i < numArgs; ++i) {
        varNames.push_back("arg" + std::to_string(i));
      }
      varNamePtrs.reserve(varNames.size());
      for (auto &name : varNames) {
        varNamePtrs.push_back(name.c_str());
      }

      auto *args = new mpfr_t[numArgs];
      std::vector<const mpfr_t *> argPtrs(numArgs);
      for (size_t i = 0; i < numArgs; ++i) {
        mpfr_init2(args[i], 53);
        mpfr_set_d(args[i], 42.0, MPFR_RNDN);
        argPtrs[i] = &args[i];
      }

      mpfr_t result;
      mpfr_init2(result, 53);
      mpfr_t *outs[] = {&result};

      uint32_t roots[] = {exprRoot};
      RivalDiscretization *disc = rival_disc_f64(53);
      RivalMachine *machine = rival_machine_new(
          arena, roots, 1, varNamePtrs.data(), numArgs, disc, 200, 1000);

      if (!machine) {
        llvm::errs() << "Failed to create machine\n";
        rival_disc_free(disc);
        rival_expr_arena_free(arena);
        for (size_t i = 0; i < numArgs; ++i)
          mpfr_clear(args[i]);
        delete[] args;
        mpfr_clear(result);
        return;
      }

      RivalError err = rival_apply(machine, argPtrs.data(), numArgs, outs, 1,
                                   nullptr, 100, 2000);

      if (err == RIVAL_ERROR_OK) {
        double res = mpfr_get_d(result, MPFR_RNDN);
        llvm::errs() << "Result: " << res << "\n";
      } else {
        llvm::errs() << "Evaluation failed with error: "
                     << rival_error_message(err) << "\n";
      }

      rival_machine_free(machine);
      rival_disc_free(disc);
      rival_expr_arena_free(arena);
      for (size_t i = 0; i < numArgs; ++i)
        mpfr_clear(args[i]);
      delete[] args;
      mpfr_clear(result);

      llvm::errs() << "=== End Rival Evaluate ===\n";
    });
  }
};

class HerbiePrintTopoSort
    : public impl::HerbiePrintTopoSortBase<HerbiePrintTopoSort> {
public:
  using impl::HerbiePrintTopoSortBase<
      HerbiePrintTopoSort>::HerbiePrintTopoSortBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    module.walk([&](mlir::equivalence::GraphOp graphOp) {
      auto sortedOps = computeSelectedTopoSort(graphOp);

      llvm::errs() << "Topological order for graph at " << graphOp.getLoc()
                   << ":\n";
      for (mlir::Operation *op : sortedOps) {
        llvm::errs() << "  ";
        op->print(llvm::errs(), mlir::OpPrintingFlags().skipRegions());
        llvm::errs() << "\n";
      }
      llvm::errs() << "\n";
    });
  }
};

// ===----------------------------------------------------------------------===
// // Herbie Sound Ops lowering patterns (shared by LowerHerbieSoundOpsPass
// // and HerbieOptimizePass)
// ===----------------------------------------------------------------------===

struct LowerSoundDivPattern : public OpRewritePattern<SoundDivOp> {
  using OpRewritePattern<SoundDivOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(SoundDivOp op,
                                PatternRewriter &rewriter) const final {
    rewriter.replaceOpWithNewOp<arith::DivFOp>(op, op.getLhs(), op.getRhs());
    return success();
  }
};

struct LowerSoundPowPattern : public OpRewritePattern<SoundPowOp> {
  using OpRewritePattern<SoundPowOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(SoundPowOp op,
                                PatternRewriter &rewriter) const final {
    rewriter.replaceOpWithNewOp<math::PowFOp>(op, op.getLhs(), op.getRhs());
    return success();
  }
};

struct LowerSoundLogPattern : public OpRewritePattern<SoundLogOp> {
  using OpRewritePattern<SoundLogOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(SoundLogOp op,
                                PatternRewriter &rewriter) const final {
    rewriter.replaceOpWithNewOp<math::LogOp>(op, op.getValue());
    return success();
  }
};

static void populateLowerHerbieSoundOpsPatterns(RewritePatternSet &patterns) {
  patterns
      .add<LowerSoundDivPattern, LowerSoundPowPattern, LowerSoundLogPattern>(
          patterns.getContext());
}

// ===----------------------------------------------------------------------===
// // Herbie Constant Ops lowering patterns (shared by
// LowerHerbieConstantOpsPass
// // and HerbieOptimizePass)
// ===----------------------------------------------------------------------===

struct LowerHerbieConstantPattern : public OpRewritePattern<ConstantOp> {
  using OpRewritePattern<ConstantOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(ConstantOp herbieConstOp,
                                PatternRewriter &rewriter) const final {
    double value = getConstantValue(herbieConstOp.getSymbol());

    auto resultType = herbieConstOp.getResult().getType();
    auto floatAttr = rewriter.getFloatAttr(resultType, value);

    rewriter.replaceOpWithNewOp<arith::ConstantOp>(herbieConstOp, floatAttr);
    return success();
  }
};

static void populateLowerHerbieConstantPatterns(RewritePatternSet &patterns) {
  patterns.add<LowerHerbieConstantPattern>(patterns.getContext());
}

class HerbieOptimizePass
    : public impl::HerbieOptimizePassBase<HerbieOptimizePass> {
public:
  using impl::HerbieOptimizePassBase<
      HerbieOptimizePass>::HerbieOptimizePassBase;

  void runOnOperation() final {
    TAMAGOYAKI_SCOPED_TIMER("HerbieOptimizePass");
    mlir::ModuleOp module = getOperation();

    ModuleOp patternsModule;
    ModuleOp irModule;
    OwningOpRef<ModuleOp> parsedPatternsModule;

    if (!patternsFile.empty()) {
      irModule = module;
      parsedPatternsModule =
          parseSourceFile<ModuleOp>(patternsFile, module.getContext());
      if (!parsedPatternsModule) {
        emitError(module.getLoc())
            << "failed to parse patterns file: " << patternsFile;
        return signalPassFailure();
      }
      patternsModule = parsedPatternsModule.release();
    } else {
      patternsModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "patterns"));
      irModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "ir"));

      if (!patternsModule || !irModule)
        return;
    }

    IntervalSearchConfig intervalConfig;
    intervalConfig.maxSearchDepth = maxSearchDepth;
    intervalConfig.maxRegions = maxRegions;
    intervalConfig.analysisPrecision = analysisPrecision;
    intervalConfig.maxRivalPrecision = maxRivalPrecision;
    intervalConfig.maxRivalIterations = maxRivalIterations;

    RivalExprArena *arena = rival_expr_arena_new();
    if (!arena) {
      llvm::errs() << "Failed to create rival expression arena\n";
      return signalPassFailure();
    }

    DenseMap<Value, uint32_t> valueToExpr;
    DenseMap<Value, size_t> valueToRootIdx;
    std::vector<std::string> varNameStorage;
    SmallVector<uint32_t> roots;
    SmallVector<FunctionIntervalResult> intervalResults;
    SmallVector<SmallVector<Operation *>> allSortedOps;

    // Step 1: Run interval search and insert equivalence graphs
    {
      irModule.walk([&](mlir::func::FuncOp funcOp) {
        auto &intervalResult = intervalResults.emplace_back(
            runIntervalSearchOnFunction(funcOp, intervalConfig));

        if (!intervalResult.success) {
          funcOp.emitWarning() << "Interval search failed, continuing anyway";
        } else {
          LLVM_DEBUG({
            llvm::dbgs() << "Interval search for " << funcOp.getName() << ": "
                         << intervalResult.searchResult.sampleableRegions.size()
                         << " sampleable regions, valid fraction: "
                         << intervalResult.searchResult.statistics.validFraction
                         << "\n";
          });
        }

        if (mlir::failed(mlir::equivalence::insertGraphInFunction(
                funcOp, /*insertSingleElementEqs=*/false))) {
          funcOp.emitError() << "Failed to insert equivalence graph";
          return signalPassFailure();
        }

        // Map function arguments to rival variables and register as roots
        for (auto [i, arg] : llvm::enumerate(funcOp.getArguments())) {
          std::string name = "arg" + std::to_string(i);
          varNameStorage.push_back(name);
          uint32_t varExpr =
              rival_expr_var(arena, varNameStorage.back().c_str());
          valueToExpr[arg] = varExpr;

          size_t idx = roots.size();
          roots.push_back(varExpr);
          valueToRootIdx[arg] = idx;
        }
      });
    }

    // Step 2: Run equality saturation
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternsModule);

    patternsModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternsModule);

    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), std::move(pdlPattern), irModule,
        maxSaturationIters);

    if (!saturationSuccess) {
      LLVM_DEBUG(llvm::dbgs() << "Warning: Saturation returned false\n");
    }

    // Lower herbie sound ops introduced during saturation
    {
      TAMAGOYAKI_SCOPED_TIMER("LowerHerbieSoundOpsPatterns");
      RewritePatternSet patterns(irModule.getContext());
      populateLowerHerbieSoundOpsPatterns(patterns);
      populateLowerHerbieConstantPatterns(patterns);
      GreedyRewriteConfig config;
      config.enableConstantCSE(false);
      config.enableFolding(false);
      (void)applyPatternsGreedily(irModule, std::move(patterns), config);
    }

    // Step 3: Initial greedy selection
    irModule.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "herbie.cost"); });

    // Step 4: Compile selected operations to rival expressions in
    // topological order, then build the rival machine
    irModule.walk([&](mlir::equivalence::GraphOp graphOp) {
      auto sortedOps = computeSelectedTopoSort(graphOp);

      LLVM_DEBUG({
        llvm::dbgs() << "Topological order (" << sortedOps.size()
                     << " operations):\n";
        for (mlir::Operation *op : sortedOps) {
          llvm::dbgs() << "  ";
          op->print(llvm::dbgs(), mlir::OpPrintingFlags().skipRegions());
          llvm::dbgs() << "\n";
        }
      });

      // Compile each operation in topological order so that operand
      // expressions are already present in valueToExpr when needed.
      // Register every result as a rival root so we can look up exact
      // values for local error computation.
      for (mlir::Operation *op : sortedOps) {
        if (auto eclass = dyn_cast<ClassOp>(op)) {
          std::optional<uint64_t> mci = eclass.getMinCostIndex();
          assert(mci.has_value());
          Value selectedOperand = eclass->getOperand(mci.value());
          valueToExpr[eclass.getResult()] = valueToExpr[selectedOperand];
          if (valueToRootIdx.contains(selectedOperand)) {
            valueToRootIdx[eclass.getResult()] =
                valueToRootIdx[selectedOperand];
          }
          continue;
        }

        auto iface = dyn_cast<RivalCompileableInterface>(op);
        if (!iface) {
          LLVM_DEBUG(llvm::dbgs()
                     << "Skipping op without RivalCompileableInterface: "
                     << op->getName() << "\n");
          continue;
        }

        SmallVector<uint32_t> operandExprs{};
        for (auto operand : op->getOperands()) {
          assert(valueToExpr.contains(operand));
          operandExprs.push_back(valueToExpr[operand]);
        }
        auto resultExprs = iface.compile(arena, operandExprs);
        assert(op->getNumResults() == resultExprs.size());
        for (auto [val, expr] : llvm::zip(op->getResults(), resultExprs)) {
          valueToExpr[val] = expr;

          size_t idx = roots.size();
          roots.push_back(expr);
          valueToRootIdx[val] = idx;
        }
      }

      // Collect ALL non-class, non-yield operations for local error
      // computation.  Operations that were not part of the toposort
      // (i.e. non-selected eclass members) don't have their own rival
      // root, but each such operation is used by exactly one
      // equivalence.class whose result *does* have a root.  Map the
      // non-selected op's result to that class's root index so that
      // computeLocalErrors can look up the exact (high-precision)
      // ground-truth value.
      SmallVector<Operation *> allOps;
      for (Operation &op : graphOp.getBody().front()) {
        if (isa<ClassOp, YieldOp>(&op))
          continue;

        for (Value result : op.getResults()) {
          if (!valueToRootIdx.contains(result)) {
            bool mapped = false;
            for (OpOperand &use : result.getUses()) {
              if (auto classOp = dyn_cast<ClassOp>(use.getOwner())) {
                assert(valueToRootIdx.contains(classOp.getResult()) &&
                       "ClassOp result must have a rival root index");
                valueToRootIdx[result] =
                    valueToRootIdx.lookup(classOp.getResult());
                mapped = true;
                break;
              }
            }
            assert(mapped &&
                   "Non-selected op result must be used by a ClassOp");
          }
        }

        allOps.push_back(&op);
      }
      allSortedOps.push_back(std::move(allOps));
    });

    // Step 5: Build variable name pointers for rival
    std::vector<const char *> varNamePtrs;
    varNamePtrs.reserve(varNameStorage.size());
    for (auto &name : varNameStorage) {
      varNamePtrs.push_back(name.c_str());
    }

    LLVM_DEBUG(llvm::dbgs()
               << "Preparing per-root evaluation (" << roots.size()
               << " roots, " << varNamePtrs.size() << " variables)\n");

    RivalDiscretization *disc = rival_disc_f64(analysisPrecision);

    // Step 6: Sample points and evaluate per-root
    if (intervalResults.empty() || !intervalResults[0].success) {
      LLVM_DEBUG(llvm::dbgs() << "No valid interval result; skipping sampling "
                                 "and error analysis\n");
    } else {
      auto &intervalResult = intervalResults[0];

      SamplingResult samplingResult;
      {
        TAMAGOYAKI_SCOPED_TIMER("SampleAndEvaluate");
        samplingResult = sampleAndEvaluate(
            arena, roots, varNamePtrs, disc, intervalResult.searchResult,
            intervalResult.floatBitWidths, /*numSamples=*/256,
            /*evalMaxIterations=*/100,
            /*evalMaxPrecision=*/2000, analysisPrecision);
      }

      LLVM_DEBUG(llvm::dbgs()
                 << "Sampled " << samplingResult.sampled << " / 256 points"
                 << " (skipped " << samplingResult.skipped << ")\n");

      // Step 7: Compute local error for each operation
      DenseMap<Operation *, double> opSumDistances;

      {
        TAMAGOYAKI_SCOPED_TIMER("ComputeLocalErrors");
        for (auto &sortedOps : allSortedOps) {
          auto localErrors =
              computeLocalErrors(sortedOps, valueToRootIdx, samplingResult);

          for (auto &errInfo : localErrors) {
            if (errInfo.count == 0)
              continue;

            opSumDistances[errInfo.op] = errInfo.sumUlp;

            LLVM_DEBUG({
              llvm::dbgs() << "  ";
              errInfo.op->print(llvm::dbgs(),
                                mlir::OpPrintingFlags().skipRegions());
              llvm::dbgs() << "\n    max_ulp=" << errInfo.maxUlp
                           << " mean_ulp=" << errInfo.meanUlp()
                           << " samples=" << errInfo.count;
              if (errInfo.foldFailures > 0)
                llvm::dbgs() << " fold_failures=" << errInfo.foldFailures;
              llvm::dbgs() << "\n";
            });
          }
        }
      }

      // Step 8: Re-select with error-based costs, extract, and inline
      irModule.walk([&](GraphOp graphOp) {
        clearSelection(graphOp, "equivalence.cost");

        graphOp.walk([&](Operation *op) {
          if (isa<ClassOp>(op) || isa<GraphOp>(op) || isa<YieldOp>(op))
            return;

          auto it = opSumDistances.find(op);
          if (it != opSumDistances.end()) {
            int64_t cost =
                static_cast<int64_t>(std::round(std::log2(it->second + 1.0))) +
                1;
            op->setAttr("equivalence.cost",
                        CostAttr::get(op->getContext(), cost));
            LLVM_DEBUG({
              llvm::dbgs() << "cost=" << cost << " for ";
              op->print(llvm::dbgs(), mlir::OpPrintingFlags().skipRegions());
              llvm::dbgs() << "\n";
            });
          }
        });

        selectGreedy(graphOp, /*defaultCost=*/-1, "equivalence.cost");
        extractFromGraph(graphOp);
        inlineGraphOp(graphOp);
      });
    }

    rival_disc_free(disc);
    rival_expr_arena_free(arena);
  }
};

class LowerHerbieSoundOpsPass
    : public impl::LowerHerbieSoundOpsPassBase<LowerHerbieSoundOpsPass> {
public:
  using impl::LowerHerbieSoundOpsPassBase<
      LowerHerbieSoundOpsPass>::LowerHerbieSoundOpsPassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    RewritePatternSet patterns(module.getContext());
    populateLowerHerbieSoundOpsPatterns(patterns);
    GreedyRewriteConfig config;
    config.enableConstantCSE(false);
    config.enableFolding(false);
    (void)applyPatternsGreedily(module, std::move(patterns), config);
  }
};

// ===----------------------------------------------------------------------===
// // LowerHerbieConstantPass
// ===----------------------------------------------------------------------===

class LowerHerbieConstantPass
    : public impl::LowerHerbieConstantPassBase<LowerHerbieConstantPass> {
public:
  using impl::LowerHerbieConstantPassBase<
      LowerHerbieConstantPass>::LowerHerbieConstantPassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    RewritePatternSet patterns(module.getContext());
    populateLowerHerbieConstantPatterns(patterns);
    GreedyRewriteConfig config;
    config.enableConstantCSE(false);
    config.enableFolding(false);
    (void)applyPatternsGreedily(module, std::move(patterns), config);
  }
};

} // namespace

} // namespace herbie
