#include "HerbieMLIR.h"
#include "mlir/Analysis/DataFlow/DeadCodeAnalysis.h"
#include "mlir/Analysis/DataFlowFramework.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/PassManager.h"
#include "llvm/Support/raw_ostream.h"

#include <cstdint>
#include <mpfr.h>
#include <rival.h>

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATEPASS
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

} // namespace

} // namespace herbie
