#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "HerbieMLIR.h"
#include "HerbieMLIROpInterfaces.h"
#include "HerbieUtils.h"
#include "IntervalSearch.h"
#include "LocalError.h"
#include "mlir/Analysis/TopologicalSortUtils.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>
#include <cstddef>
#include <cstdint>
#include <mach/mach.h>
#include <mpfr.h>
#include <optional>
#include <rival.h>
#include <string>
#include <vector>

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATEPASS
#define GEN_PASS_DEF_RIVALEVALUATEPASS
#define GEN_PASS_DEF_HERBIEPRINTTOPOSORT
#define GEN_PASS_DEF_HERBIEOPTIMIZEPASS
#include "HerbieMLIRPasses.h.inc"

using namespace mlir;
using namespace mlir::equivalence;

SmallVector<Operation *> computeSelectedTopoSort(GraphOp graphOp) {
  Block &block = graphOp.getBody().front();

  DenseSet<Operation *> excludedOps;

  for (Operation &op : block) {
    if (isa<YieldOp>(&op))
      continue;

    bool anyResultNeeded = false;
    for (Value result : op.getResults()) {
      for (OpOperand &use : result.getUses()) {
        Operation *user = use.getOwner();
        auto classOp = dyn_cast<ClassOp>(user);
        if (!classOp) {
          anyResultNeeded = true;
          break;
        }
        if (auto minCostAttr =
                classOp->getAttrOfType<IntegerAttr>("min_cost_index")) {
          int64_t minIdx = minCostAttr.getInt();
          if (minIdx >= 0 &&
              static_cast<size_t>(minIdx) < classOp.getInputs().size() &&
              classOp.getInputs()[minIdx] == result) {
            anyResultNeeded = true;
            break;
          }
        } else {
          anyResultNeeded = true;
          break;
        }
      }
      if (anyResultNeeded)
        break;
    }

    if (!anyResultNeeded)
      excludedOps.insert(&op);
  }

  SmallVector<Operation *> opsToSort;
  for (Operation &op : block) {
    if (!excludedOps.contains(&op))
      opsToSort.push_back(&op);
  }

  auto isOperandReady = [&](Value value, Operation *) -> bool {
    Operation *defOp = value.getDefiningOp();
    return !defOp || excludedOps.contains(defOp);
  };

  computeTopologicalSorting(opsToSort, isOperandReady);

  // Remove YieldOp from result
  SmallVector<Operation *> result;
  for (Operation *op : opsToSort) {
    if (!isa<YieldOp>(op)) {
      result.push_back(op);
    }
  }
  return result;
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

class HerbieOptimizePass
    : public impl::HerbieOptimizePassBase<HerbieOptimizePass> {
public:
  using impl::HerbieOptimizePassBase<
      HerbieOptimizePass>::HerbieOptimizePassBase;

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

    IntervalSearchConfig intervalConfig;
    intervalConfig.maxSearchDepth = maxSearchDepth;
    intervalConfig.maxRegions = maxRegions;
    intervalConfig.analysisPrecision = analysisPrecision;
    intervalConfig.maxRivalPrecision = maxRivalPrecision;
    intervalConfig.maxRivalIterations = maxRivalIterations;

    // Create a shared rival arena for all functions
    RivalExprArena *arena = rival_expr_arena_new();
    if (!arena) {
      llvm::errs() << "Failed to create rival expression arena\n";
      return signalPassFailure();
    }

    // Shared state for rival compilation across all functions
    DenseMap<Value, uint32_t> valueToExpr;
    DenseMap<Value, size_t> valueToRootIdx;
    std::vector<std::string> varNameStorage;
    SmallVector<uint32_t> roots;
    SmallVector<FunctionIntervalResult> intervalResults;
    SmallVector<SmallVector<Operation *>> allSortedOps;

    irModule.walk([&](mlir::func::FuncOp funcOp) {
      auto &intervalResult = intervalResults.emplace_back(
          runIntervalSearchOnFunction(funcOp, intervalConfig));

      if (!intervalResult.success) {
        funcOp.emitWarning() << "Interval search failed, continuing anyway";
      } else {
        llvm::errs() << "  Found "
                     << intervalResult.searchResult.sampleableRegions.size()
                     << " sampleable regions\n";
        llvm::errs() << "  Valid fraction: "
                     << intervalResult.searchResult.statistics.validFraction
                     << "\n";
      }

      llvm::errs() << "Step 2: Inserting equivalence graph...\n";

      if (mlir::failed(mlir::equivalence::insertGraphInFunction(
              funcOp, /*insertSingleElementEqs=*/false))) {
        funcOp.emitError() << "Failed to insert equivalence graph";
        return signalPassFailure();
      }

      llvm::errs() << "  Graph inserted successfully\n";

      // Map function arguments to rival variables and register as roots
      for (auto [i, arg] : llvm::enumerate(funcOp.getArguments())) {
        std::string name = "arg" + std::to_string(i);
        varNameStorage.push_back(name);
        uint32_t varExpr = rival_expr_var(arena, varNameStorage.back().c_str());
        valueToExpr[arg] = varExpr;

        size_t idx = roots.size();
        roots.push_back(varExpr);
        valueToRootIdx[arg] = idx;
      }
    });

    // Run saturation
    bool saturationSuccess = mlir::ematch::runSaturation(
        irModule->getContext(), patternModule, irModule, maxSaturationIters);

    if (!saturationSuccess) {
      llvm::errs() << "  Warning: Saturation returned false\n";
    } else {
      llvm::errs() << "  Saturation completed\n";
    }

    // select greedily:
    irModule.walk(
        [&](GraphOp graphOp) { selectGreedy(graphOp, 1, "herbie.cost"); });

    // Step 4: Compile selected operations to rival expressions in
    // topological order, then build the rival machine
    llvm::errs() << "Step 4: Computing topological sort and compiling to "
                    "rival expressions...\n";

    irModule.walk([&](mlir::equivalence::GraphOp graphOp) {
      auto sortedOps = computeSelectedTopoSort(graphOp);

      llvm::errs() << "  Topological order (" << sortedOps.size()
                   << " operations):\n";
      for (mlir::Operation *op : sortedOps) {
        llvm::errs() << "    ";
        op->print(llvm::errs(), mlir::OpPrintingFlags().skipRegions());
        llvm::errs() << "\n";
      }

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
          llvm::errs() << "  Skipping op without RivalCompileableInterface: "
                       << op->getName() << "\n";
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
            // This result was not compiled into its own rival root.
            // Find the equivalence.class that consumes it and reuse
            // that class's ground-truth value.
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

    // Build the rival machine from all collected roots and variables
    std::vector<const char *> varNamePtrs;
    varNamePtrs.reserve(varNameStorage.size());
    for (auto &name : varNameStorage) {
      varNamePtrs.push_back(name.c_str());
    }

    llvm::errs() << "Step 5: Building rival machine (" << roots.size()
                 << " roots, " << varNamePtrs.size() << " variables)...\n";

    RivalDiscretization *disc = rival_disc_f64(analysisPrecision);
    RivalMachine *machine = rival_machine_new(
        arena, roots.data(), roots.size(), varNamePtrs.data(),
        varNamePtrs.size(), disc, maxRivalPrecision, maxRivalIterations);

    if (!machine) {
      llvm::errs() << "Failed to create rival machine\n";
      rival_disc_free(disc);
      rival_expr_arena_free(arena);
      return signalPassFailure();
    }

    llvm::errs() << "  Rival machine constructed successfully\n";

    llvm::errs() << "Step 6: Sampling points and evaluating...\n";

    if (intervalResults.empty() || !intervalResults[0].success) {
      llvm::errs() << "  No valid interval result; skipping sampling.\n";
    } else {
      auto &intervalResult = intervalResults[0];

      SamplingResult samplingResult = sampleAndEvaluate(
          machine, intervalResult.searchResult, intervalResult.floatBitWidths,
          roots.size(), /*numSamples=*/256, /*evalMaxIterations=*/100,
          /*evalMaxPrecision=*/2000, analysisPrecision);

      llvm::errs() << "  Sampled " << samplingResult.sampled << " / 256 points"
                   << " (skipped " << samplingResult.skipped << ")\n";

      // Step 7: Compute local error for each operation
      llvm::errs() << "Step 7: Computing local errors...\n";

      for (auto &sortedOps : allSortedOps) {
        auto localErrors =
            computeLocalErrors(sortedOps, valueToRootIdx, samplingResult);

        for (auto &errInfo : localErrors) {
          if (errInfo.count == 0)
            continue;

          llvm::errs() << "  ";
          errInfo.op->print(llvm::errs(),
                            mlir::OpPrintingFlags().skipRegions());
          llvm::errs() << "\n    max_ulp=" << errInfo.maxUlp
                       << " mean_ulp=" << errInfo.meanUlp()
                       << " samples=" << errInfo.count;
          if (errInfo.foldFailures > 0)
            llvm::errs() << " fold_failures=" << errInfo.foldFailures;
          llvm::errs() << "\n";
        }
      }
    }

    rival_machine_free(machine);
    rival_disc_free(disc);
    rival_expr_arena_free(arena);

    llvm::errs() << "=== End Herbie Optimize ===\n";
  }
};

} // namespace

} // namespace herbie
