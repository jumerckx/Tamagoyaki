#include "HerbieMLIR.h"
#include "RivalRAII.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/PassManager.h"

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

    auto pi = rival::makeFloat(53, 3.14159265359);
    auto str = rival::toString(pi.get());
    llvm::errs() << "Pi: " << str << "\n";
  }
};

} // namespace

} // namespace herbie
