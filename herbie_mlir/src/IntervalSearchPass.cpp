#include "HerbieMLIR.h"
#include "IntervalSearch.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "llvm/Support/raw_ostream.h"

#include <rival.h>
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

    llvm::errs() << "=== Interval Search: " << funcOp.getName() << " ===\n";

    // Build config from pass options
    IntervalSearchOptions config;
    config.maxSearchDepth = maxSearchDepth;
    config.analysisPrecision = analysisPrecision;
    config.maxRivalPrecision = maxRivalPrecision;
    config.maxRivalIterations = maxRivalIterations;

    // Run the interval search
    llvm::errs() << "  Searching with " << funcOp.getNumArguments()
                 << " variables, max depth " << maxSearchDepth << "\n";

    FunctionIntervalResult result = runIntervalSearchOnFunction(funcOp, config);

    if (!result.success) {
      return signalPassFailure();
    }

    // Report results
    llvm::errs() << "  Found " << result.searchResult.sampleableRegions.size()
                 << " sampleable regions\n";
    llvm::errs() << "  Statistics:\n";
    llvm::errs() << "    Valid fraction:   "
                 << result.searchResult.statistics.validFraction << "\n";
    llvm::errs() << "    Invalid fraction: "
                 << result.searchResult.statistics.invalidFraction << "\n";
    llvm::errs() << "    Unknown fraction: "
                 << result.searchResult.statistics.unknownFraction << "\n";

    // Emit statistics as attributes if requested
    if (emitStatistics) {
      mlir::OpBuilder builder(funcOp.getContext());
      funcOp->setAttr("herbie.valid_fraction",
                      builder.getF64FloatAttr(
                          result.searchResult.statistics.validFraction));
      funcOp->setAttr("herbie.invalid_fraction",
                      builder.getF64FloatAttr(
                          result.searchResult.statistics.invalidFraction));
      funcOp->setAttr("herbie.unknown_fraction",
                      builder.getF64FloatAttr(
                          result.searchResult.statistics.unknownFraction));
      funcOp->setAttr("herbie.sampleable_regions",
                      builder.getI64IntegerAttr(
                          result.searchResult.sampleableRegions.size()));
    }

    llvm::errs() << "=== End Interval Search ===\n";
  }
};

} // namespace

} // namespace herbie
