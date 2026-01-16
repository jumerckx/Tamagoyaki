#include "HerbieMLIR.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/PassManager.h"

namespace herbie {

#define GEN_PASS_DEF_HERBIEMLIRTEMPLATE
#include "HerbieMLIRPasses.h.inc"

namespace {

class HerbieMLIRTemplatePass
    : public impl::HerbieMLIRTemplatePassBase<HerbieMLIRTemplatePass> {
public:
  using impl::HerbieMLIRTemplatePassBase<
      HerbieMLIRTemplatePass>::HerbieMLIRTemplatePassBase;

  void runOnOperation() final {
    mlir::ModuleOp module = getOperation();
    // TODO: Add pass logic here
  }
};

} // namespace

} // namespace herbie
