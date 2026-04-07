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
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <functional>
#include <limits>
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

/// Convert a ULP distance to bits of error, following Herbie's ulps->bits.
/// 0 ULPs → 0 bits; otherwise log₂(ulp).  NaN/Inf results (which get the
/// huge sentinel from ulpDistance) are capped at `maxBits` (64 for binary64).
static double ulpsToBits(double ulps, double maxBits = 64.0) {
  if (ulps <= 0.0)
    return 0.0;
  double bits = std::log2(ulps);
  return std::min(bits, maxBits);
}

/// A single patch: one alternative operand choice in one patchable ClassOp.
struct PatchDesc {
  ClassOp classOp;
  unsigned operandIndex;
};

/// Per-Value execution state: a baseline column plus sparse per-patch
/// override columns.
struct ValueColumns {
  SmallVector<double> baseline; // [numSamples]
  DenseMap<unsigned /*patchId*/, SmallVector<double>> overrides;
};

/// Recursively print a Value as a flat expression string, resolving ClassOps
/// by picking the greedy-selected operand — unless `patch` is non-null and
/// points at that ClassOp, in which case the patch operand is used instead.
static std::string valueToExpr(Value val, PatchDesc *patch,
                               DenseSet<Value> &onStack) {
  Operation *defOp = val.getDefiningOp();
  if (!defOp) {
    auto blockArg = cast<BlockArgument>(val);
    return "arg" + std::to_string(blockArg.getArgNumber());
  }

  if (onStack.contains(val))
    return "<cycle>";

  onStack.insert(val);

  std::string result;

  if (auto classOp = dyn_cast<ClassOp>(defOp)) {
    unsigned idx;
    if (patch && patch->classOp.getOperation() == classOp.getOperation())
      idx = patch->operandIndex;
    else {
      auto mci = classOp.getMinCostIndex();
      idx = mci ? *mci : 0;
    }
    result = valueToExpr(classOp->getOperand(idx), patch, onStack);
  } else if (auto constOp = dyn_cast<arith::ConstantOp>(defOp)) {
    if (auto floatAttr = dyn_cast<FloatAttr>(constOp.getValue())) {
      llvm::raw_string_ostream os(result);
      os << floatAttr.getValueAsDouble();
    } else if (auto intAttr = dyn_cast<IntegerAttr>(constOp.getValue())) {
      result = std::to_string(intAttr.getInt());
    }
  } else {
    result = defOp->getName().getStringRef().str();
    result += "(";
    for (unsigned i = 0; i < defOp->getNumOperands(); ++i) {
      if (i > 0)
        result += ", ";
      result += valueToExpr(defOp->getOperand(i), patch, onStack);
    }
    result += ")";
  }

  onStack.erase(val);
  return result;
}

/// Check whether selecting `operandIdx` for `patchedClass` creates a cycle.
/// Mirrors the traversal of valueToExpr exactly: the patched ClassOp uses
/// operandIdx; every other ClassOp uses its min_cost_index.
static bool patchHasCycle(Value val, ClassOp patchedClass, unsigned patchIdx,
                          DenseSet<Value> &onStack) {
  Operation *defOp = val.getDefiningOp();
  if (!defOp)
    return false; // block argument — no cycle

  if (onStack.contains(val))
    return true; // found a cycle

  onStack.insert(val);
  bool cycle = false;

  if (auto classOp = dyn_cast<ClassOp>(defOp)) {
    unsigned idx;
    if (classOp.getOperation() == patchedClass.getOperation()) {
      idx = patchIdx; // the patched class — use the patch operand
    } else {
      auto mci = classOp.getMinCostIndex();
      idx = mci ? *mci : 0; // every other class — greedy selection
    }
    cycle = patchHasCycle(classOp->getOperand(idx), patchedClass, patchIdx,
                          onStack);
  } else {
    for (Value operand : defOp->getOperands()) {
      if (patchHasCycle(operand, patchedClass, patchIdx, onStack)) {
        cycle = true;
        break;
      }
    }
  }

  onStack.erase(val);
  return cycle;
}

/// Evaluate all patches simultaneously inside `graphOp`.
///
/// A "patch" is a (ClassOp, operandIndex) pair representing one alternative
/// choice in a patchable class, applied on top of the greedy baseline.
/// All patches are evaluated in a single traversal.
///
/// `patchableClassOps` contains the set of ClassOps that have original-op
/// alternatives (i.e. classes worth optimizing).
///
/// On success, writes the best operand index for each patchable ClassOp
/// via setMinCostIndex. Returns true on success, false on failure.
static bool
evaluateAllPatchesBatched(GraphOp graphOp, ArrayRef<Value> funcArgs,
                          ArrayRef<SmallVector<double>> inputColumns,
                          size_t numSamples, ArrayRef<double> gtOutputs,
                          const DenseSet<Operation *> &patchableClassSet) {
  using namespace mlir;
  using namespace mlir::equivalence;

  auto yieldOp = cast<YieldOp>(graphOp.getBody().front().getTerminator());
  if (yieldOp.getNumOperands() != 1)
    return false;
  Value outputVal = yieldOp.getOperand(0);

  // ------------------------------------------------------------------
  // 1. Build patch registry and per-ClassOp patch index.
  //
  // patchRegistry[patchId] gives the PatchDesc (classOp + operandIndex).
  // classPatchIds[op]      gives the list of patchIds for that ClassOp.
  // ------------------------------------------------------------------
  SmallVector<PatchDesc> patchRegistry;
  DenseMap<Operation *, SmallVector<unsigned>> classPatchIds;

  for (Operation &op : graphOp.getBody().front()) {
    auto classOp = dyn_cast<ClassOp>(&op);
    if (!classOp || !patchableClassSet.contains(&op))
      continue;
    for (unsigned i = 0; i < classOp.getInputs().size(); ++i) {
      unsigned patchId = patchRegistry.size();
      patchRegistry.push_back({classOp, i});
      classPatchIds[&op].push_back(patchId);
    }
  }

  // ------------------------------------------------------------------
  // 2. Filter cyclic patches.
  // ------------------------------------------------------------------
  {
    SmallVector<PatchDesc> filtered;
    DenseMap<Operation *, SmallVector<unsigned>> filteredClassPatchIds;

    for (auto &patch : patchRegistry) {
      DenseSet<Value> onStack;
      onStack.insert(patch.classOp->getResult(0));

      if (patchHasCycle(patch.classOp->getOperand(patch.operandIndex),
                        patch.classOp, patch.operandIndex, onStack)) {
        continue;
      }

      unsigned newId = filtered.size();
      filtered.push_back(patch);
      filteredClassPatchIds[patch.classOp.getOperation()].push_back(newId);
    }

    patchRegistry = std::move(filtered);
    classPatchIds = std::move(filteredClassPatchIds);
  }

  unsigned P = patchRegistry.size();
  if (P == 0)
    return true;

  // Build a set of valid operand indices per ClassOp (used in topo sort).
  DenseMap<Operation *, DenseSet<unsigned>> validPatchOperands;
  for (auto &[op, pids] : classPatchIds)
    for (unsigned pid : pids)
      validPatchOperands[op].insert(patchRegistry[pid].operandIndex);

  // ------------------------------------------------------------------
  // 3. Topological sort — cycle-free after filtering.
  // ------------------------------------------------------------------
  SmallVector<Operation *> sortedOps;
  DenseSet<Operation *> visited;

  std::function<bool(Value)> visit = [&](Value val) -> bool {
    Operation *defOp = val.getDefiningOp();
    if (!defOp)
      return true;
    if (!visited.insert(defOp).second)
      return true;

    if (auto classOp = dyn_cast<ClassOp>(defOp)) {
      auto mci = classOp.getMinCostIndex();
      if (!mci)
        return false;
      if (!visit(classOp->getOperand(*mci)))
        return false;

      if (patchableClassSet.contains(defOp)) {
        auto it = validPatchOperands.find(defOp);
        if (it != validPatchOperands.end()) {
          for (unsigned idx : it->second) {
            if (idx == *mci)
              continue;
            if (!visit(classOp->getOperand(idx)))
              return false;
          }
        }
      }
    } else {
      for (Value operand : defOp->getOperands())
        if (!visit(operand))
          return false;
    }

    sortedOps.push_back(defOp);
    return true;
  };

  if (!visit(outputVal))
    return false;

  LLVM_DEBUG({
    DenseSet<Value> onStack;
    llvm::dbgs() << "Baseline expression: "
                 << valueToExpr(outputVal, nullptr, onStack) << "\n";
    for (unsigned p = 0; p < P; ++p) {
      DenseSet<Value> onStack;
      llvm::dbgs() << "Patch " << p << " (class at "
                   << patchRegistry[p].classOp.getLoc() << ", operand "
                   << patchRegistry[p].operandIndex << "): "
                   << valueToExpr(outputVal, &patchRegistry[p], onStack)
                   << "\n";
    }
  });

  // ------------------------------------------------------------------
  // 4. Seed function-argument ValueColumns.
  // ------------------------------------------------------------------
  DenseMap<Value, ValueColumns> valueMap;
  for (auto [arg, col] : llvm::zip(funcArgs, inputColumns)) {
    auto &vc = valueMap[arg];
    vc.baseline.assign(col.begin(), col.end());
  }

  auto nanColumn = [&]() -> SmallVector<double> {
    return SmallVector<double>(numSamples,
                               std::numeric_limits<double>::quiet_NaN());
  };

  // ------------------------------------------------------------------
  // 5. Batched execution.
  // ------------------------------------------------------------------
  for (Operation *op : sortedOps) {
    if (isa<YieldOp>(op))
      continue;

    // ---- ClassOp handling ----
    if (auto classOp = dyn_cast<ClassOp>(op)) {
      auto mci = classOp.getMinCostIndex();
      if (!mci)
        return false;
      Value selected = classOp->getOperand(*mci);

      auto &resultVC = valueMap[classOp.getResult()];
      auto selIt = valueMap.find(selected);

      // Baseline: forward greedy-selected operand's baseline.
      if (selIt != valueMap.end())
        resultVC.baseline = selIt->second.baseline;
      else
        resultVC.baseline = nanColumn();

      if (patchableClassSet.contains(op)) {
        // --- Patchable ClassOp ---

        // (a) New patches originating here: for each *surviving* patch,
        //     the override is that operand's baseline.
        auto cpIt = classPatchIds.find(op);
        if (cpIt != classPatchIds.end()) {
          for (unsigned patchId : cpIt->second) {
            unsigned operandIdx = patchRegistry[patchId].operandIndex;
            Value operand = classOp->getOperand(operandIdx);
            auto opIt = valueMap.find(operand);
            if (opIt != valueMap.end())
              resultVC.overrides[patchId] = opIt->second.baseline;
            else
              resultVC.overrides[patchId] = nanColumn();
          }
        }

        // (b) Upstream patches passing through on the greedy path.
        if (selIt != valueMap.end()) {
          for (auto &[pid, col] : selIt->second.overrides)
            resultVC.overrides[pid] = col;
        }
      } else {
        // --- Non-patchable ClassOp: forward all overrides from selected.
        if (selIt != valueMap.end())
          resultVC.overrides = selIt->second.overrides;
      }
      continue;
    }

    // ---- Regular op (BatchEvaluateInterface) ----
    auto batchIface = dyn_cast<BatchEvaluateInterface>(op);
    if (!batchIface)
      return false;

    // Collect union of all patchIds present in any operand.
    DenseSet<unsigned> activePatchIds;
    for (Value operand : op->getOperands()) {
      auto it = valueMap.find(operand);
      if (it != valueMap.end())
        for (auto &[pid, _] : it->second.overrides)
          activePatchIds.insert(pid);
    }

    // --- Baseline evaluation ---
    {
      SmallVector<const double *> operandPtrs;
      operandPtrs.reserve(op->getNumOperands());
      bool ready = true;
      for (Value operand : op->getOperands()) {
        auto it = valueMap.find(operand);
        if (it != valueMap.end()) {
          operandPtrs.push_back(it->second.baseline.data());
        } else {
          valueMap[op->getResult(0)].baseline = nanColumn();
          ready = false;
          break;
        }
      }
      if (ready) {
        auto &out = valueMap[op->getResult(0)].baseline;
        out.resize(numSamples);
        batchIface.batchEvaluate(operandPtrs, out.data(), numSamples);
      }
    }

    // --- Override evaluations ---
    for (unsigned pid : activePatchIds) {
      bool hasDifference = false;
      for (Value operand : op->getOperands()) {
        auto it = valueMap.find(operand);
        if (it != valueMap.end() && it->second.overrides.count(pid)) {
          hasDifference = true;
          break;
        }
      }
      if (!hasDifference)
        continue;

      SmallVector<const double *> operandPtrs;
      operandPtrs.reserve(op->getNumOperands());
      for (Value operand : op->getOperands()) {
        auto it = valueMap.find(operand);
        if (it == valueMap.end()) {
          operandPtrs.clear();
          break;
        }
        auto overIt = it->second.overrides.find(pid);
        if (overIt != it->second.overrides.end())
          operandPtrs.push_back(overIt->second.data());
        else
          operandPtrs.push_back(it->second.baseline.data());
      }

      auto &out = valueMap[op->getResult(0)].overrides[pid];
      if (operandPtrs.empty()) {
        out = nanColumn();
      } else {
        out.resize(numSamples);
        batchIface.batchEvaluate(operandPtrs, out.data(), numSamples);
      }
    }
  }

  // ------------------------------------------------------------------
  // 6. Result collection — find the single best patch globally.
  //    Scoring uses Herbie's bits-of-error metric:
  //      bits_error(point) = log₂(ulpDistance(candidate, exact))
  //    and we compare candidates by the sum (equivalently, average)
  //    of per-point bits of error across all sample points.
  // ------------------------------------------------------------------
  auto outIt = valueMap.find(outputVal);
  if (outIt == valueMap.end())
    return false;

  const ValueColumns &outVC = outIt->second;

  // Maximum bits penalty for invalid results (NaN, Inf, missing).
  constexpr double kMaxBits = 64.0;

  // Helper: compute total bits-of-error for an output column against ground
  // truth.
  auto computeTotalBitsError = [&](const SmallVector<double> &col) -> double {
    double totalBits = 0.0;
    for (size_t s = 0; s < numSamples; ++s) {
      if (s < col.size()) {
        totalBits += ulpsToBits(ulpDistance(col[s], gtOutputs[s]), kMaxBits);
      } else
        totalBits += kMaxBits;
    }
    return totalBits;
  };

  double baselineTotalBits = computeTotalBitsError(outVC.baseline);

  double globalBestTotalBits = baselineTotalBits;
  Operation *globalBestClassOp = nullptr;
  unsigned globalBestOperandIdx = 0;

  LLVM_DEBUG(
      llvm::dbgs() << "Baseline : avg bits of error = "
                   << baselineTotalBits / numSamples << " (accuracy = "
                   << 100.0 * (1.0 - baselineTotalBits / numSamples / kMaxBits)
                   << "%)\n");

  // Iterate patches via the registry — patchId ↔ operand relationship
  // is always looked up, never derived arithmetically.
  for (unsigned patchId = 0; patchId < P; ++patchId) {
    auto &patch = patchRegistry[patchId];
    auto overIt = outVC.overrides.find(patchId);

    double totalBits;
    if (overIt != outVC.overrides.end())
      totalBits = computeTotalBitsError(overIt->second);
    else
      totalBits = baselineTotalBits;

    LLVM_DEBUG(llvm::dbgs()
               << "Patch " << patchId << " operand " << patch.operandIndex
               << ": avg bits of error = " << totalBits / numSamples
               << " (accuracy = "
               << 100.0 * (1.0 - totalBits / numSamples / kMaxBits) << "%)\n");

    if (totalBits < globalBestTotalBits) {
      globalBestTotalBits = totalBits;
      globalBestClassOp = patch.classOp.getOperation();
      globalBestOperandIdx = patch.operandIndex;
    }
  }

  // Apply the single globally-best patch (if it improves on baseline).
  if (globalBestClassOp) {
    auto classOp = cast<ClassOp>(globalBestClassOp);
    classOp.setMinCostIndex(globalBestOperandIdx);
    LLVM_DEBUG(llvm::dbgs()
               << "--> globally selected: Class " << classOp.getLoc()
               << " operand " << globalBestOperandIdx
               << " (avg bits of error = " << globalBestTotalBits / numSamples
               << ", accuracy = "
               << 100.0 * (1.0 - globalBestTotalBits / numSamples / kMaxBits)
               << "%)\n");
  } else {
    LLVM_DEBUG(llvm::dbgs()
               << "  -> no patch improved on baseline (avg bits of error = "
               << baselineTotalBits / numSamples << ", accuracy = "
               << 100.0 * (1.0 - baselineTotalBits / numSamples / kMaxBits)
               << "%)\n");
  }

  return true;
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
      int numSamples = 256;
      groundTruth = sampleAndEvaluate(
          gtArena, gtRoots, varNamePtrs, disc, intervalResult.searchResult,
          intervalResult.floatBitWidths, numSamples,
          /*evalMaxIterations=*/100,
          /*evalMaxPrecision=*/2000, analysisPrecision, 43);
      rival_disc_free(disc);
      rival_expr_arena_free(gtArena);

      if (groundTruth.sampled == 0 || groundTruth.results.empty())
        return funcOp.emitError()
               << "ground-truth evaluation produced no valid samples";

      LLVM_DEBUG(llvm::dbgs()
                 << "Ground truth: " << groundTruth.sampled << " / "
                 << numSamples << " " << "points (skipped "
                 << groundTruth.skipped << ")\n");
    }

    // ---------------------------------------------------------------
    // Step 3: Insert equivalence graph, track original operations.
    // ---------------------------------------------------------------
    if (failed(mlir::equivalence::insertGraphInFunction(
            funcOp, /*insertSingleElementEqs=*/false)))
      return funcOp.emitError() << "failed to insert equivalence graph";

    GraphOp graphOp = llvm::dyn_cast<GraphOp>(*funcOp.getOps().begin());
    assert(graphOp);

    OriginalOpTracker tracker;
    graphOp.walk([&](Operation *op) {
      if (!isa<equivalence::ClassOp, equivalence::GraphOp,
               equivalence::YieldOp>(op))
        tracker.trackOriginal(op);
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
          maxSaturationIters, maxNodes, &tracker, eagerRewrite);
      if (!ok)
        return funcOp.emitError() << "equality saturation failed";
    }

    for (auto op : tracker.getOps()) {
      op->setAttr("herbie.is_original", UnitAttr::get(op->getContext()));
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
    // Herbie cost function: maps MLIR operation names to Herbie's
    // measured cycle costs for C/C++ on Linux (binary64).
    auto herbieCostFn = [](Operation *op) -> int {
      assert(!(op->getName().getStringRef() == "equivalence.class"));
      auto cost =
          llvm::StringSwitch<int>(op->getName().getStringRef())
              // arith ops
              .Case("arith.addf", 16)
              .Case("arith.subf", 15)
              .Case("arith.mulf", 21)
              .Case("arith.divf", 27)
              .Case("arith.negf", 10)
              .Case("arith.constant", 9) // fl-move-cost
              // math unary ops
              .Case("math.absf", 10)
              .Case("math.sin", 332)
              .Case("math.cos", 333)
              .Case("math.tan", 371)
              .Case("math.sinh", 121)
              .Case("math.cosh", 95)
              .Case("math.acos", 36)
              .Case("math.acosh", 66)
              .Case("math.asin", 39)
              .Case("math.asinh", 84)
              .Case("math.atan", 84)
              .Case("math.atanh", 36)
              .Case("math.cbrt", 157)
              .Case("math.ceil", 47)
              .Case("math.erf", 81)
              .Case("math.exp", 108)
              .Case("math.exp2", 83)
              .Case("math.floor", 47)
              .Case("math.log", 51)
              .Case("math.log10", 87)
              .Case("math.log2", 68)
              .Case("math.sqrt", 19)
              .Case("math.tanh", 82)
              .Case("math.trunc", 46)
              .Case("math.round", 66)
              .Case("math.roundeven", 12) // rint
              // math binary ops
              .Case("math.powf", 152)
              .Case("math.atan2", 149)
              .Case("math.copysign", 20)
              .Case("math.fpowi", 152) // same as powf
              // herbie-specific ops (use same cost as their lowered form)
              .Case("herbie.sound_div", 27)
              .Case("herbie.sound_pow", 152)
              .Case("herbie.sound_log", 51)
              .Case("herbie.constant", 9)
              // equivalence.class has zero cost (just routing)
              .Case("equivalence.class", 0)
              .Default(-1);
      if (cost == -1)
        llvm::report_fatal_error("herbieCostFn: unknown op '" +
                                 op->getName().getStringRef() + "'");
      return cost;
    };
    selectGreedy(graphOp, herbieCostFn, "herbie.cost");
    // Ensure the original expression is selected by the greedy selection:
    for (auto originalOp : tracker.getOps()) {
      if (originalOp->hasOneUse()) {
        OpOperand &use = *(originalOp->use_begin());
        if (ClassOp c = dyn_cast<ClassOp>(use.getOwner())) {
          c.setMinCostIndex(use.getOperandNumber());
        }
      }
    }

    // ---------------------------------------------------------------
    // Step 6: Batched per-class optimization via sample-based
    //         bits-of-error evaluation — all patches evaluated in
    //         one traversal.
    // ---------------------------------------------------------------
    {
      TAMAGOYAKI_SCOPED_TIMER("PerClassOptimization");

      SmallVector<Value> funcArgs(funcOp.getArguments());
      size_t numSamples = groundTruth.sampled;
      size_t numArgs = funcArgs.size();

      // Build per-argument input columns from ground truth samples.
      SmallVector<SmallVector<double>> inputColumns(numArgs);
      for (size_t a = 0; a < numArgs; ++a) {
        inputColumns[a].reserve(numSamples);
        for (size_t s = 0; s < numSamples; ++s)
          inputColumns[a].push_back(groundTruth.points[s][a]);
      }

      // Collect ground truth output values.
      SmallVector<double> gtOutputs;
      gtOutputs.reserve(numSamples);
      for (size_t s = 0; s < numSamples; ++s)
        gtOutputs.push_back(groundTruth.results[s][0]);

      // Collect unique ClassOps that contain at least one original
      // operation among their operands (i.e. classes with alternatives).
      DenseSet<Operation *> patchableClassSet;
      for (Operation *origOp : tracker.getOps()) {
        for (Operation *user : origOp->getUsers()) {
          if (auto classOp = dyn_cast<ClassOp>(user)) {
            if (classOp.getInputs().size() > 1)
              patchableClassSet.insert(classOp.getOperation());
          }
        }
      }

      LLVM_DEBUG(llvm::dbgs() << "Optimizing " << patchableClassSet.size()
                              << " equivalence classes (batched)\n");

      if (!evaluateAllPatchesBatched(graphOp, funcArgs, inputColumns,
                                     numSamples, gtOutputs, patchableClassSet))
        return funcOp.emitError() << "batched patch evaluation failed";
    }

    // ---------------------------------------------------------------
    // Step 7: Extract and inline the optimized graph.
    // ---------------------------------------------------------------
    extractFromGraph(graphOp);
    inlineGraphOp(graphOp);

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

    {
      TAMAGOYAKI_SCOPED_TIMER("LoadPDL");
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
    }

    {
      TAMAGOYAKI_SCOPED_TIMER("processFunctions");
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
