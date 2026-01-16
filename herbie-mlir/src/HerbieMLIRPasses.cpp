#include "HerbieMLIR.h"
#include "IntervalAnalysis.h"
#include "RivalRAII.h"
#include "mlir/Analysis/DataFlow/DeadCodeAnalysis.h"
#include "mlir/Analysis/DataFlowFramework.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/PassManager.h"

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATEPASS
#define GEN_PASS_DEF_INTERVALANALYSISPASS
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

    auto pi = rival::makeFloat(53, 3.14159265359);
    auto str = rival::toString(pi.get());
    llvm::errs() << "Pi: " << str << "\n";
  }
};

class IntervalAnalysisPass
    : public impl::IntervalAnalysisPassBase<IntervalAnalysisPass> {
public:
  using impl::IntervalAnalysisPassBase<
      IntervalAnalysisPass>::IntervalAnalysisPassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();

    mlir::DataFlowSolver solver;
    solver.load<mlir::dataflow::DeadCodeAnalysis>();
    solver.load<IntervalAnalysis>();

    if (failed(solver.initializeAndRun(module))) {
      signalPassFailure();
      return;
    }

    module.walk([&](mlir::Operation *op) {
      for (mlir::Value result : op->getResults()) {
        if (const auto *lattice = solver.lookupState<IntervalLattice>(result)) {
          llvm::errs() << result << " -> " << lattice->getValue() << "\n";
        }
      }
    });
  }
};

} // namespace

} // namespace herbie
