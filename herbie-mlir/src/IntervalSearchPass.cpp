#include "HerbieMLIR.h"
#include "HerbieMLIROpInterfaces.h"
#include "IntervalSearch.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Pass/Pass.h"
#include "llvm/Support/raw_ostream.h"

#include <rival.h>
#include <string>
#include <vector>

namespace herbie {

#define GEN_PASS_DEF_INTERVALSEARCHPASS
#include "HerbieMLIRPasses.h.inc"

namespace {

class IntervalSearchPass
    : public impl::IntervalSearchPassBase<IntervalSearchPass> {
public:
  using impl::IntervalSearchPassBase<
      IntervalSearchPass>::IntervalSearchPassBase;

  void runOnOperation() final {
    mlir::func::FuncOp funcOp = getOperation();

    // Check if function implements RivalCompileableInterface
    auto iface =
        mlir::dyn_cast<RivalCompileableInterface>(funcOp.getOperation());
    if (!iface) {
      funcOp.emitWarning()
          << "Function does not implement RivalCompileableInterface, skipping";
      return;
    }

    llvm::errs() << "=== Interval Search: " << funcOp.getName() << " ===\n";

    // Compile function to Rival expression
    RivalExprArena *arena = rival_expr_arena_new();
    if (!arena) {
      funcOp.emitError() << "Failed to create Rival expression arena";
      return signalPassFailure();
    }

    uint32_t exprRoot = iface.compile(arena, {});

    // Build variable names and determine float bit widths
    size_t numArgs = funcOp.getNumArguments();
    std::vector<std::string> varNames;
    std::vector<const char *> varNamePtrs;
    std::vector<unsigned> floatBitWidths;

    varNames.reserve(numArgs);
    floatBitWidths.reserve(numArgs);

    for (size_t i = 0; i < numArgs; ++i) {
      varNames.push_back("arg" + std::to_string(i));

      mlir::Type argType = funcOp.getArgumentTypes()[i];
      if (auto floatType = mlir::dyn_cast<mlir::FloatType>(argType)) {
        floatBitWidths.push_back(floatType.getWidth());
      } else {
        funcOp.emitError() << "Argument " << i
                           << " is not a floating-point type";
        rival_expr_arena_free(arena);
        return signalPassFailure();
      }
    }

    varNamePtrs.reserve(varNames.size());
    for (auto &name : varNames) {
      varNamePtrs.push_back(name.c_str());
    }

    // Create Rival machine
    uint32_t roots[] = {exprRoot};

    // Determine discretization based on result type
    RivalDiscretization *disc = nullptr;
    if (funcOp.getNumResults() > 0) {
      mlir::Type resultType = funcOp.getResultTypes()[0];
      if (auto floatType = mlir::dyn_cast<mlir::FloatType>(resultType)) {
        if (floatType.getWidth() == 32)
          disc = rival_disc_f32(24);
        else
          disc = rival_disc_f64(53);
      }
    }
    if (!disc)
      disc = rival_disc_f64(53);

    RivalMachine *machine =
        rival_machine_new(arena, roots, 1, varNamePtrs.data(), numArgs, disc,
                          maxRivalPrecision, 1000);

    if (!machine) {
      funcOp.emitError() << "Failed to create Rival machine";
      rival_disc_free(disc);
      rival_expr_arena_free(arena);
      return signalPassFailure();
    }

    // Build search options from pass options
    IntervalSearchOptions options;
    options.maxSearchDepth = maxSearchDepth;
    options.maxRegions = maxRegions;
    options.analysisPrecision = analysisPrecision;
    options.maxRivalPrecision = maxRivalPrecision;
    options.maxRivalIterations = maxRivalIterations;
    options.emitStatistics = emitStatistics;

    // Create initial hyperrect covering full domain
    std::vector<Hyperrect> initialRects;
    initialRects.push_back(
        createFullDomainRect(floatBitWidths, analysisPrecision));

    // Run the interval search
    llvm::errs() << "  Searching with " << numArgs << " variables, max depth "
                 << maxSearchDepth << ", max regions " << maxRegions << "\n";

    SearchResult result =
        findIntervals(machine, initialRects, floatBitWidths, options);

    // Report results
    llvm::errs() << "  Found " << result.sampleableRegions.size()
                 << " sampleable regions\n";
    llvm::errs() << "  Statistics:\n";
    llvm::errs() << "    Valid fraction:   " << result.statistics.validFraction
                 << "\n";
    llvm::errs() << "    Invalid fraction: "
                 << result.statistics.invalidFraction << "\n";
    llvm::errs() << "    Unknown fraction: "
                 << result.statistics.unknownFraction << "\n";

    // Emit statistics as attributes if requested
    if (emitStatistics) {
      mlir::OpBuilder builder(funcOp.getContext());
      funcOp->setAttr("herbie.valid_fraction",
                      builder.getF64FloatAttr(result.statistics.validFraction));
      funcOp->setAttr(
          "herbie.invalid_fraction",
          builder.getF64FloatAttr(result.statistics.invalidFraction));
      funcOp->setAttr(
          "herbie.unknown_fraction",
          builder.getF64FloatAttr(result.statistics.unknownFraction));
      funcOp->setAttr(
          "herbie.sampleable_regions",
          builder.getI64IntegerAttr(result.sampleableRegions.size()));
    }

    // Cleanup
    rival_machine_free(machine);
    rival_disc_free(disc);
    rival_expr_arena_free(arena);

    llvm::errs() << "=== End Interval Search ===\n";
  }
};

} // namespace

} // namespace herbie
