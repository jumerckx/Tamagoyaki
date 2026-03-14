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
#include "mlir/IR/Attributes.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/WalkResult.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
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

/// Compute ULP distance between two double-precision values.
static double ulpDistance(double a, double b) {
  if (a == b)
    return 0.0;
  if (std::isnan(a) || std::isnan(b))
    return static_cast<double>(1ULL << 62);
  if (std::isinf(a) != std::isinf(b))
    return static_cast<double>(1ULL << 62);
  if (std::isinf(a) && std::isinf(b))
    return (a == b) ? 0.0 : static_cast<double>(1ULL << 62);

  int64_t ai, bi;
  std::memcpy(&ai, &a, sizeof(double));
  std::memcpy(&bi, &b, sizeof(double));
  // Map negative-zero / negative values into a linear integer order.
  if (ai < 0)
    ai = INT64_MIN - ai;
  if (bi < 0)
    bi = INT64_MIN - bi;
  int64_t diff = ai - bi;
  return static_cast<double>(diff < 0 ? -diff : diff);
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

class OriginalOpTracker : public mlir::RewriterBase::Listener {
public:
  void trackOriginal(mlir::Operation *op) { ops.insert(op); }

  void notifyOperationReplaced(mlir::Operation *op,
                               mlir::ValueRange newValues) override {
    if (!ops.erase(op))
      return;
    if (!newValues.empty())
      if (auto *newOp = newValues[0].getDefiningOp())
        ops.insert(newOp);
  }

  void notifyOperationErased(mlir::Operation *op) override { ops.erase(op); }

  bool isOriginal(mlir::Operation *op) const { return ops.contains(op); }

  const llvm::DenseSet<mlir::Operation *> &getOps() const { return ops; }

private:
  llvm::DenseSet<mlir::Operation *> ops;
};

/// Recursively evaluate a single Value by walking backwards through the
/// selected program.  ClassOps forward to their selected operand;
/// ordinary ops are folded from their operands.  Results are cached in
/// \p valueMap so each Value is computed at most once.
static std::optional<Attribute>
evalValue(Value v, DenseMap<Value, Attribute> &valueMap) {
  // Already computed (or seeded as a function argument)?
  auto it = valueMap.find(v);
  if (it != valueMap.end())
    return it->second;

  Operation *op = v.getDefiningOp();
  if (!op)
    return std::nullopt; // Block argument that wasn't seeded – shouldn't
                         // happen.

  // ClassOps just forward their selected operand's value.
  if (auto classOp = dyn_cast<ClassOp>(op)) {
    auto mci = classOp.getMinCostIndex();
    if (!mci)
      return std::nullopt;
    Value selected = classOp->getOperand(*mci);
    auto result = evalValue(selected, valueMap);
    if (!result)
      return std::nullopt;
    valueMap[classOp.getResult()] = *result;
    return *result;
  }

  // Recursively evaluate operands.
  SmallVector<Attribute> constOperands;
  for (Value operand : op->getOperands()) {
    auto operandAttr = evalValue(operand, valueMap);
    if (!operandAttr)
      return std::nullopt;
    constOperands.push_back(*operandAttr);
  }

  // Fold this op on concrete constants.
  SmallVector<OpFoldResult> foldResults;
  if (failed(op->fold(constOperands, foldResults)))
    return std::nullopt;

  // Map each result to its folded attribute.
  for (auto [val, fr] : llvm::zip(op->getResults(), foldResults)) {
    auto attr = fr.dyn_cast<Attribute>();
    if (!attr)
      return std::nullopt;
    valueMap[val] = attr;
  }

  // Return the attribute for the specific result we were asked about.
  auto found = valueMap.find(v);
  if (found == valueMap.end())
    return std::nullopt;
  return found->second;
}

/// Evaluate the currently-selected program inside `graphOp` on a single
/// sample point.  Function arguments are mapped to the doubles in
/// `inputValues`.
static std::optional<double> foldSelectedProgram(GraphOp graphOp,
                                                 ArrayRef<Value> funcArgs,
                                                 ArrayRef<double> inputValues) {
  DenseMap<Value, Attribute> valueMap;

  // Seed function arguments with concrete FloatAttr values.
  for (auto [arg, val] : llvm::zip(funcArgs, inputValues))
    valueMap[arg] = FloatAttr::get(arg.getType(), val);

  // Read the graph's output from its yield operand.
  auto yieldOp = cast<YieldOp>(graphOp.getBody().front().getTerminator());
  if (yieldOp.getNumOperands() == 0)
    return std::nullopt;

  auto result = evalValue(yieldOp.getOperand(0), valueMap);
  if (!result)
    return std::nullopt;

  if (auto floatAttr = dyn_cast<FloatAttr>(*result))
    return floatAttr.getValueAsDouble();
  return std::nullopt;
}

// ===----------------------------------------------------------------------===
// // HerbieOptimizePass
// ===----------------------------------------------------------------------===

class HerbieOptimizePass
    : public impl::HerbieOptimizePassBase<HerbieOptimizePass> {
public:
  using impl::HerbieOptimizePassBase<
      HerbieOptimizePass>::HerbieOptimizePassBase;

  /// Compile the original (flat) function body to a set of Rival
  /// expression roots suitable for ground-truth evaluation.
  LogicalResult compileGroundTruth(mlir::func::FuncOp funcOp,
                                   RivalExprArena *arena,
                                   std::vector<std::string> &varNameStorage,
                                   SmallVectorImpl<uint32_t> &roots) {
    DenseMap<Value, uint32_t> valToExpr;

    for (auto [i, arg] : llvm::enumerate(funcOp.getArguments())) {
      std::string name = "arg" + std::to_string(i);
      varNameStorage.push_back(name);
      valToExpr[arg] = rival_expr_var(arena, varNameStorage.back().c_str());
    }

    for (Operation &op : funcOp.front()) {
      if (isa<mlir::func::ReturnOp>(&op))
        continue;

      auto iface = dyn_cast<RivalCompileableInterface>(&op);
      if (!iface) {
        LLVM_DEBUG(llvm::dbgs()
                   << "Ground-truth compile: skipping " << op.getName()
                   << " (no RivalCompileableInterface)\n");
        continue;
      }

      SmallVector<uint32_t> operandExprs;
      for (Value operand : op.getOperands()) {
        if (!valToExpr.contains(operand))
          return op.emitError()
                 << "operand not compiled prior to use in ground-truth";
        operandExprs.push_back(valToExpr[operand]);
      }
      auto resultExprs = iface.compile(arena, operandExprs);
      for (auto [v, e] : llvm::zip(op.getResults(), resultExprs))
        valToExpr[v] = e;
    }

    funcOp.walk([&](mlir::func::ReturnOp retOp) {
      for (Value operand : retOp.getOperands()) {
        assert(valToExpr.contains(operand));
        roots.push_back(valToExpr[operand]);
      }
    });

    if (roots.empty())
      return funcOp.emitError() << "function has no return values to optimize";

    return success();
  }

  /// Run the full optimization pipeline on a single function:
  /// interval search, ground-truth evaluation, equality saturation,
  /// alternative evaluation, and extraction.
  LogicalResult processFunction(mlir::func::FuncOp funcOp,
                                ModuleOp convertedPatterns) {
    LLVM_DEBUG(llvm::dbgs()
               << "=== Optimizing " << funcOp.getName() << " ===\n");

    IntervalSearchOptions intervalConfig;
    intervalConfig.maxSearchDepth = maxSearchDepth;
    intervalConfig.analysisPrecision = analysisPrecision;
    intervalConfig.maxRivalPrecision = maxRivalPrecision;
    intervalConfig.maxRivalIterations = maxRivalIterations;

    // ---------------------------------------------------------------
    // Step 1: Interval search on the original (flat) function.
    // ---------------------------------------------------------------
    auto intervalResult = runIntervalSearchOnFunction(funcOp, intervalConfig);
    if (!intervalResult.success)
      return funcOp.emitError() << "interval search failed";

    LLVM_DEBUG({
      llvm::dbgs() << "Interval search: "
                   << intervalResult.searchResult.sampleableRegions.size()
                   << " sampleable regions, valid fraction: "
                   << intervalResult.searchResult.statistics.validFraction
                   << "\n";
    });

    // ---------------------------------------------------------------
    // Step 2: Compile the original body to Rival and evaluate
    //         ground truth at high precision.
    // ---------------------------------------------------------------
    SamplingResult groundTruth;
    {
      TAMAGOYAKI_SCOPED_TIMER("GroundTruthCompileAndEvaluate");

      RivalExprArena *gtArena = rival_expr_arena_new();
      if (!gtArena)
        return funcOp.emitError() << "failed to create rival expression arena";

      std::vector<std::string> varNameStorage;
      SmallVector<uint32_t> gtRoots;

      if (failed(
              compileGroundTruth(funcOp, gtArena, varNameStorage, gtRoots))) {
        rival_expr_arena_free(gtArena);
        return failure();
      }

      std::vector<const char *> varNamePtrs;
      varNamePtrs.reserve(varNameStorage.size());
      for (auto &name : varNameStorage)
        varNamePtrs.push_back(name.c_str());

      RivalDiscretization *disc = rival_disc_f64(analysisPrecision);
      groundTruth = sampleAndEvaluate(
          gtArena, gtRoots, varNamePtrs, disc, intervalResult.searchResult,
          intervalResult.floatBitWidths,
          /*numSamples=*/256,
          /*evalMaxIterations=*/100,
          /*evalMaxPrecision=*/2000, analysisPrecision);
      rival_disc_free(disc);
      rival_expr_arena_free(gtArena);

      if (groundTruth.sampled == 0 || groundTruth.results.empty())
        return funcOp.emitError()
               << "ground-truth evaluation produced no valid samples";

      LLVM_DEBUG(llvm::dbgs()
                 << "Ground truth: " << groundTruth.sampled
                 << " / 256 points (skipped " << groundTruth.skipped << ")\n");
    }

    // ---------------------------------------------------------------
    // Step 3: Insert equivalence graph, track original operations.
    // ---------------------------------------------------------------
    if (failed(mlir::equivalence::insertGraphInFunction(
            funcOp, /*insertSingleElementEqs=*/false)))
      return funcOp.emitError() << "failed to insert equivalence graph";

    OriginalOpTracker tracker;
    funcOp.walk([&](equivalence::GraphOp graphOp) {
      graphOp.walk([&](Operation *op) {
        if (!isa<equivalence::ClassOp, equivalence::GraphOp,
                 equivalence::YieldOp>(op))
          tracker.trackOriginal(op);
      });
    });

    // ---------------------------------------------------------------
    // Step 4: Equality saturation with a fresh clone of the patterns.
    // ---------------------------------------------------------------
    {
      TAMAGOYAKI_SCOPED_TIMER("EqualitySaturation");

      // auto clonedPatterns =
      //     cast<ModuleOp>(convertedPatterns->clone());
      PDLPatternModule pdlPattern(convertedPatterns);

      ModuleOp parentModule = funcOp->getParentOfType<ModuleOp>();
      bool ok = mlir::ematch::runSaturation(
          parentModule->getContext(), std::move(pdlPattern), parentModule,
          maxSaturationIters, maxNodes, &tracker);
      if (!ok)
        return funcOp.emitError() << "equality saturation failed";
    }

    // Lower herbie sound ops / constants introduced during saturation.
    {
      TAMAGOYAKI_SCOPED_TIMER("LowerHerbieSoundOpsPatterns");
      RewritePatternSet patterns(funcOp->getContext());
      populateLowerHerbieSoundOpsPatterns(patterns);
      populateLowerHerbieConstantPatterns(patterns);
      GreedyRewriteConfig config;
      config.enableConstantCSE(false);
      config.enableFolding(false);
      (void)applyPatternsGreedily(funcOp, std::move(patterns), config);
    }

    // ---------------------------------------------------------------
    // Step 5: Greedy initial selection.
    // ---------------------------------------------------------------
    funcOp.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "herbie.cost"); });

    // for each original operation, collect its class (deduplicate classes).
    // for each class:
    //   for each operand in class:
    //     * set min_cost_index of class to point to this operand
    //     * evaluate the "selected" program on the samples
    //       do this by collecting the operations to execute through a backwards
    //       walk (from yield to operands) put the loop over samples innermost:
    //       for op in operations { for sample in samples: run op}
    //     * compute the cost as the ulp difference with groundtruth.
    // When all classes are processed, pick the single min_cost_index which has
    // the lowest total ulp. Finally, extract the graph.

    // ---------------------------------------------------------------
    // Step 6: Per-class alternative evaluation and extraction.
    // ---------------------------------------------------------------
    {
      TAMAGOYAKI_SCOPED_TIMER("PerClassAlternativeEvaluation");

      SmallVector<Value> funcArgs(funcOp.getArguments());

      funcOp.walk([&](GraphOp graphOp) {
        // Collect equivalence classes that contain original alternatives.
        struct ClassCandidate {
          ClassOp classOp;
          SmallVector<unsigned> originalIndices;
        };
        llvm::DenseMap<Operation *, ClassCandidate> candidateMap;

        for (Operation *origOp : tracker.getOps()) {
          for (Value result : origOp->getResults()) {
            for (OpOperand &use : result.getUses()) {
              auto classOp = dyn_cast<ClassOp>(use.getOwner());
              if (!classOp || classOp->getParentOp() != graphOp.getOperation())
                continue;
              unsigned idx = use.getOperandNumber();
              auto &entry = candidateMap[classOp.getOperation()];
              if (!entry.classOp)
                entry.classOp = classOp;
              entry.originalIndices.push_back(idx);
            }
          }
        }

        LLVM_DEBUG(llvm::dbgs()
                   << "Alternative evaluation: " << candidateMap.size()
                   << " classes with original ops\n");

        struct BestChoice {
          ClassOp classOp;
          unsigned bestIndex;
        };
        SmallVector<BestChoice> bestChoices;

        for (auto &[_, cand] : candidateMap) {
          std::optional<uint64_t> savedMCI = cand.classOp.getMinCostIndex();

          // Evaluate the current (greedy) selection as the baseline.
          double baselineError = 0.0;
          for (size_t s = 0; s < groundTruth.points.size(); ++s) {
            auto computed =
                foldSelectedProgram(graphOp, funcArgs, groundTruth.points[s]);
            if (!computed)
              continue;
            baselineError += ulpDistance(*computed, groundTruth.results[s][0]);
          }

          double bestError = baselineError;
          unsigned bestIdx = static_cast<unsigned>(savedMCI.value_or(0));

          // Try each original alternative.
          for (unsigned origIdx : cand.originalIndices) {
            cand.classOp.setMinCostIndex(origIdx);

            double totalError = 0.0;
            for (size_t s = 0; s < groundTruth.points.size(); ++s) {
              auto computed =
                  foldSelectedProgram(graphOp, funcArgs, groundTruth.points[s]);
              if (!computed)
                continue;
              totalError += ulpDistance(*computed, groundTruth.results[s][0]);
            }

            LLVM_DEBUG({
              llvm::dbgs() << "  Class ";
              cand.classOp->print(llvm::dbgs(),
                                  OpPrintingFlags().skipRegions());
              llvm::dbgs() << " alt " << origIdx << ": totalUlp=" << totalError
                           << "\n";
            });

            if (totalError < bestError) {
              bestError = totalError;
              bestIdx = origIdx;
            }
          }

          // Reset to initial greedy selection before recording.
          if (savedMCI)
            cand.classOp.setMinCostIndex(*savedMCI);

          bestChoices.push_back({cand.classOp, bestIdx});
        }

        // Apply best selections, extract, and inline.
        for (auto &choice : bestChoices) {
          choice.classOp.setMinCostIndex(choice.bestIndex);
          LLVM_DEBUG({
            llvm::dbgs() << "Best selection for class: idx=" << choice.bestIndex
                         << " ";
            choice.classOp->print(llvm::dbgs(),
                                  OpPrintingFlags().skipRegions());
            llvm::dbgs() << "\n";
          });
        }

        extractFromGraph(graphOp);
        inlineGraphOp(graphOp);
      });
    }

    return success();
  }

  void runOnOperation() final {
    TAMAGOYAKI_SCOPED_TIMER("HerbieOptimizePass");
    mlir::ModuleOp module = getOperation();

    // ---------------------------------------------------------------
    // Resolve the patterns and IR modules.
    // ---------------------------------------------------------------
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

      if (!patternsModule || !irModule) {
        emitError(module.getLoc()) << "missing 'patterns' or 'ir' submodule";
        return signalPassFailure();
      }
    }

    // Convert ematch ops once; each function will clone from this.
    mlir::ematch::convertEmatchOpsToApplyRewrites(patternsModule);

    // ---------------------------------------------------------------
    // Process each function independently.
    // ---------------------------------------------------------------
    auto walkResult =
        irModule.walk([&](mlir::func::FuncOp funcOp) -> WalkResult {
          if (failed(processFunction(funcOp, patternsModule)))
            return WalkResult::interrupt();
          return WalkResult::advance();
        });

    if (walkResult.wasInterrupted())
      return signalPassFailure();
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
