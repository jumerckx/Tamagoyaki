#include "Cranelift/Cranelift.h"
#include "EquivalenceDialect.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Operation.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Pass/Pass.h"

namespace cranelift {

#define GEN_PASS_DEF_CRANELIFTDUMMYPASS
#include "CraneliftPasses.h.inc"

class CraneliftDummyPass
    : public impl::CraneliftDummyPassBase<CraneliftDummyPass> {
public:
  using impl::CraneliftDummyPassBase<
      CraneliftDummyPass>::CraneliftDummyPassBase;

  mlir::equivalence::GraphOp convertToSoN(mlir::FunctionOpInterface funcOp) {
    mlir::equivalence::GraphOp graph;
    funcOp.walk([&](mlir::Operation *op) {
      if (mlir::isSpeculatable(op) &&
          !op->hasTrait<mlir::OpTrait::IsTerminator>()) {
        // check if the op is already in the hashcons:
        // * If it isn't, move it there (unlinnk the op from the original func).
        // * If it is, replace users of the new op with the one in the hashcons,
        // and unlink the new op from the func.
      }
    });
    return graph;
  }

  void runOnOperation() final {
    mlir::FunctionOpInterface funcOp = getOperation();
    mlir::equivalence::GraphOp graph = convertToSoN(funcOp);
    graph.dump();
  }
};

} // namespace cranelift
