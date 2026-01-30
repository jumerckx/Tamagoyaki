#include "RivalExternalModels.h"
#include "HerbieMLIROpInterfaces.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/IR/Block.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "rival.h"
#include "llvm/Support/ErrorHandling.h"
#include <cstdint>
#include <string>

using namespace mlir;
using namespace herbie;

namespace {

struct ArithAddFRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithAddFRivalCompile,
                                                      arith::AddFOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 2)
      llvm::report_fatal_error("arith.addf expects 2 operands");
    return rival_expr_add(arena, operands[0], operands[1]);
  }
};

struct ArithMulFRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithMulFRivalCompile,
                                                      arith::MulFOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 2)
      llvm::report_fatal_error("arith.mulf expects 2 operands");
    return rival_expr_mul(arena, operands[0], operands[1]);
  }
};

struct FuncRivalCompile
    : public RivalCompileableInterface::ExternalModel<FuncRivalCompile,
                                                      func::FuncOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    auto funcOp = cast<func::FuncOp>(op);
    if (funcOp.getBlocks().size() != 1) {
      llvm::report_fatal_error("Only single block functions supported");
    }

    Block &block = funcOp.front();
    DenseMap<Value, uint32_t> valueMap;

    // Arguments
    for (auto arg : block.getArguments()) {
      std::string name = "arg" + std::to_string(arg.getArgNumber());
      valueMap[arg] = rival_expr_var(arena, name.c_str());
    }

    // Operations
    for (auto &innerOp : block) {
      if (auto returnOp = dyn_cast<func::ReturnOp>(innerOp)) {
        if (returnOp.getNumOperands() != 1)
          llvm::report_fatal_error("Only single return value supported");
        if (valueMap.count(returnOp.getOperand(0)) == 0)
          llvm::report_fatal_error("Return operand not computed");
        return valueMap[returnOp.getOperand(0)];
      }

      if (auto iface = dyn_cast<RivalCompileableInterface>(innerOp)) {
        SmallVector<uint32_t> opOperands;
        for (auto operand : innerOp.getOperands()) {
          if (valueMap.count(operand) == 0) {
            llvm::report_fatal_error("Operand not computed: ");
            // llvm::report_fatal_error("Operand not computed: " +
            // operand.getLoc().toString());
          }
          opOperands.push_back(valueMap[operand]);
        }

        if (innerOp.getNumResults() != 1) {
          llvm::report_fatal_error(
              "Only single result operations supported inside func");
        }
        valueMap[innerOp.getResult(0)] = iface.compile(arena, opOperands);
      } else {
        llvm::report_fatal_error(
            "Operation not supported (missing RivalCompileableInterface): " +
            innerOp.getName().getStringRef());
      }
    }
    llvm::report_fatal_error("Function did not end with return");
  }
};

} // namespace

void herbie::registerRivalExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, arith::ArithDialect *dialect) {
    arith::AddFOp::attachInterface<ArithAddFRivalCompile>(*ctx);
    arith::MulFOp::attachInterface<ArithMulFRivalCompile>(*ctx);
  });

  registry.addExtension(+[](MLIRContext *ctx, func::FuncDialect *dialect) {
    func::FuncOp::attachInterface<FuncRivalCompile>(*ctx);
  });
}
