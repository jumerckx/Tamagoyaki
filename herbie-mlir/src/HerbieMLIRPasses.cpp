#include "EquivalenceDialect.h"
#include "HerbieMLIR.h"
#include "HerbieMLIROpInterfaces.h"
#include "mlir/Analysis/TopologicalSortUtils.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "llvm/Support/raw_ostream.h"

#include <cstddef>
#include <cstdint>
#include <mpfr.h>
#include <rival.h>
#include <string>
#include <vector>

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATEPASS
#define GEN_PASS_DEF_RIVALEVALUATEPASS
#define GEN_PASS_DEF_HERBIEPRINTTOPOSORT
#include "HerbieMLIRPasses.h.inc"

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

      uint32_t exprRoot = iface.compile(arena, {});

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
      mlir::Block &block = graphOp.getBody().front();

      // Determine which operations to exclude from the sort.
      // An operation is excluded only if ALL of its results are exclusively
      // consumed by equivalence.class ops whose min_cost_index does NOT
      // select them. If any result is selected by a class, or used by a
      // non-class op, the operation is included.
      mlir::DenseSet<mlir::Operation *> excludedOps;

      for (mlir::Operation &op : block) {
        if (mlir::isa<mlir::equivalence::YieldOp>(&op))
          continue;

        bool anyResultNeeded = false;
        for (mlir::Value result : op.getResults()) {
          for (mlir::OpOperand &use : result.getUses()) {
            mlir::Operation *user = use.getOwner();
            auto classOp = mlir::dyn_cast<mlir::equivalence::ClassOp>(user);
            if (!classOp) {
              // Used by a non-class op — this result is needed.
              anyResultNeeded = true;
              break;
            }
            // Used by a class op — check if min_cost_index selects this input.
            if (auto minCostAttr = classOp->getAttrOfType<mlir::IntegerAttr>(
                    "min_cost_index")) {
              int64_t minIdx = minCostAttr.getInt();
              if (minIdx >= 0 &&
                  static_cast<size_t>(minIdx) < classOp.getInputs().size() &&
                  classOp.getInputs()[minIdx] == result) {
                anyResultNeeded = true;
                break;
              }
            } else {
              // No min_cost_index — conservatively treat as needed.
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

      // Collect included ops in block order.
      mlir::SmallVector<mlir::Operation *> opsToSort;
      for (mlir::Operation &op : block) {
        if (!excludedOps.contains(&op))
          opsToSort.push_back(&op);
      }

      // Operands defined by excluded ops are treated as ready (no dependency).
      auto isOperandReady = [&](mlir::Value value, mlir::Operation *) -> bool {
        mlir::Operation *defOp = value.getDefiningOp();
        return !defOp || excludedOps.contains(defOp);
      };

      mlir::computeTopologicalSorting(opsToSort, isOperandReady);

      llvm::errs() << "Topological order for graph at " << graphOp.getLoc()
                   << ":\n";
      for (mlir::Operation *op : opsToSort) {
        if (!mlir::isa<mlir::equivalence::YieldOp>(op)) {
          llvm::errs() << "  ";
          op->print(llvm::errs(), mlir::OpPrintingFlags().skipRegions());
          llvm::errs() << "\n";
        }
      }
      llvm::errs() << "\n";
    });
  }
};

} // namespace

} // namespace herbie
