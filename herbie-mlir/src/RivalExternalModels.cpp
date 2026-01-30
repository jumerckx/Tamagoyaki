#include "RivalExternalModels.h"
#include "HerbieMLIROpInterfaces.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Math/IR/Math.h"
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

// ============================================================================
// Macros for generating RivalCompileable implementations
// ============================================================================

#define RIVAL_UNARY_OP(NAME, OP_TYPE, RIVAL_FUNC)                              \
  struct NAME                                                                  \
      : public RivalCompileableInterface::ExternalModel<NAME, OP_TYPE> {       \
    uint32_t compile(Operation *op, RivalExprArena *arena,                     \
                     ArrayRef<uint32_t> operands) const {                      \
      if (operands.size() != 1)                                                \
        llvm::report_fatal_error(#OP_TYPE " expects 1 operand");               \
      return RIVAL_FUNC(arena, operands[0]);                                   \
    }                                                                          \
  };

#define RIVAL_BINARY_OP(NAME, OP_TYPE, RIVAL_FUNC)                             \
  struct NAME                                                                  \
      : public RivalCompileableInterface::ExternalModel<NAME, OP_TYPE> {       \
    uint32_t compile(Operation *op, RivalExprArena *arena,                     \
                     ArrayRef<uint32_t> operands) const {                      \
      if (operands.size() != 2)                                                \
        llvm::report_fatal_error(#OP_TYPE " expects 2 operands");              \
      return RIVAL_FUNC(arena, operands[0], operands[1]);                      \
    }                                                                          \
  };

#define RIVAL_TERNARY_OP(NAME, OP_TYPE, RIVAL_FUNC)                            \
  struct NAME                                                                  \
      : public RivalCompileableInterface::ExternalModel<NAME, OP_TYPE> {       \
    uint32_t compile(Operation *op, RivalExprArena *arena,                     \
                     ArrayRef<uint32_t> operands) const {                      \
      if (operands.size() != 3)                                                \
        llvm::report_fatal_error(#OP_TYPE " expects 3 operands");              \
      return RIVAL_FUNC(arena, operands[0], operands[1], operands[2]);         \
    }                                                                          \
  };

// ============================================================================
// Arith Dialect Operations
// ============================================================================

RIVAL_BINARY_OP(ArithAddFRivalCompile, arith::AddFOp, rival_expr_add)
RIVAL_BINARY_OP(ArithSubFRivalCompile, arith::SubFOp, rival_expr_sub)
RIVAL_BINARY_OP(ArithMulFRivalCompile, arith::MulFOp, rival_expr_mul)
RIVAL_BINARY_OP(ArithDivFRivalCompile, arith::DivFOp, rival_expr_div)
RIVAL_UNARY_OP(ArithNegFRivalCompile, arith::NegFOp, rival_expr_neg)
RIVAL_BINARY_OP(ArithRemFRivalCompile, arith::RemFOp, rival_expr_fmod)
RIVAL_BINARY_OP(ArithMaximumFRivalCompile, arith::MaximumFOp, rival_expr_fmax)
RIVAL_BINARY_OP(ArithMaxNumFRivalCompile, arith::MaxNumFOp, rival_expr_fmax)
RIVAL_BINARY_OP(ArithMinimumFRivalCompile, arith::MinimumFOp, rival_expr_fmin)
RIVAL_BINARY_OP(ArithMinNumFRivalCompile, arith::MinNumFOp, rival_expr_fmin)
RIVAL_TERNARY_OP(ArithSelectRivalCompile, arith::SelectOp, rival_expr_if)

// Pass-through ops (no-ops in Rival's arbitrary precision model)
struct ArithExtFRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithExtFRivalCompile,
                                                      arith::ExtFOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 1)
      llvm::report_fatal_error("arith::ExtFOp expects 1 operand");
    return operands[0];
  }
};

struct ArithTruncFRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithTruncFRivalCompile,
                                                      arith::TruncFOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 1)
      llvm::report_fatal_error("arith::TruncFOp expects 1 operand");
    return operands[0];
  }
};

struct ArithCmpFRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithCmpFRivalCompile,
                                                      arith::CmpFOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 2)
      llvm::report_fatal_error("arith.cmpf expects 2 operands");

    auto pred = cast<arith::CmpFOp>(op).getPredicate();
    uint32_t lhs = operands[0], rhs = operands[1];

    switch (pred) {
    case arith::CmpFPredicate::OEQ:
    case arith::CmpFPredicate::UEQ:
      return rival_expr_eq(arena, lhs, rhs);
    case arith::CmpFPredicate::ONE:
    case arith::CmpFPredicate::UNE:
      return rival_expr_ne(arena, lhs, rhs);
    case arith::CmpFPredicate::OLT:
    case arith::CmpFPredicate::ULT:
      return rival_expr_lt(arena, lhs, rhs);
    case arith::CmpFPredicate::OLE:
    case arith::CmpFPredicate::ULE:
      return rival_expr_le(arena, lhs, rhs);
    case arith::CmpFPredicate::OGT:
    case arith::CmpFPredicate::UGT:
      return rival_expr_gt(arena, lhs, rhs);
    case arith::CmpFPredicate::OGE:
    case arith::CmpFPredicate::UGE:
      return rival_expr_ge(arena, lhs, rhs);
    default:
      llvm::report_fatal_error("Unsupported cmpf predicate for Rival");
    }
  }
};

struct ArithConstantRivalCompile
    : public RivalCompileableInterface::ExternalModel<ArithConstantRivalCompile,
                                                      arith::ConstantOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (auto floatAttr =
            dyn_cast<FloatAttr>(cast<arith::ConstantOp>(op).getValue()))
      return rival_expr_f64(arena, floatAttr.getValueAsDouble());
    llvm::report_fatal_error(
        "arith.constant: only floating point constants supported");
  }
};

// ============================================================================
// Math Dialect Operations
// ============================================================================

// Unary operations
RIVAL_UNARY_OP(MathAbsFRivalCompile, math::AbsFOp, rival_expr_fabs)
RIVAL_UNARY_OP(MathSqrtRivalCompile, math::SqrtOp, rival_expr_sqrt)
RIVAL_UNARY_OP(MathCbrtRivalCompile, math::CbrtOp, rival_expr_cbrt)
RIVAL_UNARY_OP(MathExpRivalCompile, math::ExpOp, rival_expr_exp)
RIVAL_UNARY_OP(MathExp2RivalCompile, math::Exp2Op, rival_expr_exp2)
RIVAL_UNARY_OP(MathExpM1RivalCompile, math::ExpM1Op, rival_expr_expm1)
RIVAL_UNARY_OP(MathLogRivalCompile, math::LogOp, rival_expr_log)
RIVAL_UNARY_OP(MathLog2RivalCompile, math::Log2Op, rival_expr_log2)
RIVAL_UNARY_OP(MathLog10RivalCompile, math::Log10Op, rival_expr_log10)
RIVAL_UNARY_OP(MathLog1pRivalCompile, math::Log1pOp, rival_expr_log1p)
RIVAL_UNARY_OP(MathSinRivalCompile, math::SinOp, rival_expr_sin)
RIVAL_UNARY_OP(MathCosRivalCompile, math::CosOp, rival_expr_cos)
RIVAL_UNARY_OP(MathTanRivalCompile, math::TanOp, rival_expr_tan)
RIVAL_UNARY_OP(MathAsinRivalCompile, math::AsinOp, rival_expr_asin)
RIVAL_UNARY_OP(MathAcosRivalCompile, math::AcosOp, rival_expr_acos)
RIVAL_UNARY_OP(MathAtanRivalCompile, math::AtanOp, rival_expr_atan)
RIVAL_UNARY_OP(MathSinhRivalCompile, math::SinhOp, rival_expr_sinh)
RIVAL_UNARY_OP(MathCoshRivalCompile, math::CoshOp, rival_expr_cosh)
RIVAL_UNARY_OP(MathTanhRivalCompile, math::TanhOp, rival_expr_tanh)
RIVAL_UNARY_OP(MathAsinhRivalCompile, math::AsinhOp, rival_expr_asinh)
RIVAL_UNARY_OP(MathAcoshRivalCompile, math::AcoshOp, rival_expr_acosh)
RIVAL_UNARY_OP(MathAtanhRivalCompile, math::AtanhOp, rival_expr_atanh)
RIVAL_UNARY_OP(MathErfRivalCompile, math::ErfOp, rival_expr_erf)
RIVAL_UNARY_OP(MathErfcRivalCompile, math::ErfcOp, rival_expr_erfc)
RIVAL_UNARY_OP(MathCeilRivalCompile, math::CeilOp, rival_expr_ceil)
RIVAL_UNARY_OP(MathFloorRivalCompile, math::FloorOp, rival_expr_floor)
RIVAL_UNARY_OP(MathRoundRivalCompile, math::RoundOp, rival_expr_round)
RIVAL_UNARY_OP(MathRoundEvenRivalCompile, math::RoundEvenOp, rival_expr_rint)
RIVAL_UNARY_OP(MathTruncRivalCompile, math::TruncOp, rival_expr_trunc)

// Binary operations
RIVAL_BINARY_OP(MathAtan2RivalCompile, math::Atan2Op, rival_expr_atan2)
RIVAL_BINARY_OP(MathPowFRivalCompile, math::PowFOp, rival_expr_pow)
RIVAL_BINARY_OP(MathFPowIRivalCompile, math::FPowIOp, rival_expr_pow)
RIVAL_BINARY_OP(MathCopySignRivalCompile, math::CopySignOp, rival_expr_copysign)

// Ternary operations
RIVAL_TERNARY_OP(MathFmaRivalCompile, math::FmaOp, rival_expr_fma)

// Composite operation: rsqrt(x) = 1 / sqrt(x)
struct MathRsqrtRivalCompile
    : public RivalCompileableInterface::ExternalModel<MathRsqrtRivalCompile,
                                                      math::RsqrtOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    if (operands.size() != 1)
      llvm::report_fatal_error("math::RsqrtOp expects 1 operand");
    uint32_t one = rival_expr_f64(arena, 1.0);
    uint32_t sqrtVal = rival_expr_sqrt(arena, operands[0]);
    return rival_expr_div(arena, one, sqrtVal);
  }
};

// ============================================================================
// Func Dialect Operations
// ============================================================================

struct FuncRivalCompile
    : public RivalCompileableInterface::ExternalModel<FuncRivalCompile,
                                                      func::FuncOp> {
  uint32_t compile(Operation *op, RivalExprArena *arena,
                   ArrayRef<uint32_t> operands) const {
    auto funcOp = cast<func::FuncOp>(op);
    if (funcOp.getBlocks().size() != 1)
      llvm::report_fatal_error("Only single block functions supported");

    Block &block = funcOp.front();
    DenseMap<Value, uint32_t> valueMap;

    for (auto arg : block.getArguments()) {
      std::string name = "arg" + std::to_string(arg.getArgNumber());
      valueMap[arg] = rival_expr_var(arena, name.c_str());
    }

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
          if (valueMap.count(operand) == 0)
            llvm::report_fatal_error("Operand not computed");
          opOperands.push_back(valueMap[operand]);
        }

        if (innerOp.getNumResults() != 1)
          llvm::report_fatal_error(
              "Only single result operations supported inside func");
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

#undef RIVAL_UNARY_OP
#undef RIVAL_BINARY_OP
#undef RIVAL_TERNARY_OP

} // namespace

// ============================================================================
// Registration
// ============================================================================

void herbie::registerRivalExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, arith::ArithDialect *dialect) {
    arith::AddFOp::attachInterface<ArithAddFRivalCompile>(*ctx);
    arith::SubFOp::attachInterface<ArithSubFRivalCompile>(*ctx);
    arith::MulFOp::attachInterface<ArithMulFRivalCompile>(*ctx);
    arith::DivFOp::attachInterface<ArithDivFRivalCompile>(*ctx);
    arith::NegFOp::attachInterface<ArithNegFRivalCompile>(*ctx);
    arith::RemFOp::attachInterface<ArithRemFRivalCompile>(*ctx);
    arith::MaximumFOp::attachInterface<ArithMaximumFRivalCompile>(*ctx);
    arith::MaxNumFOp::attachInterface<ArithMaxNumFRivalCompile>(*ctx);
    arith::MinimumFOp::attachInterface<ArithMinimumFRivalCompile>(*ctx);
    arith::MinNumFOp::attachInterface<ArithMinNumFRivalCompile>(*ctx);
    arith::SelectOp::attachInterface<ArithSelectRivalCompile>(*ctx);
    arith::CmpFOp::attachInterface<ArithCmpFRivalCompile>(*ctx);
    arith::ConstantOp::attachInterface<ArithConstantRivalCompile>(*ctx);
    arith::ExtFOp::attachInterface<ArithExtFRivalCompile>(*ctx);
    arith::TruncFOp::attachInterface<ArithTruncFRivalCompile>(*ctx);
  });

  registry.addExtension(+[](MLIRContext *ctx, math::MathDialect *dialect) {
    math::AbsFOp::attachInterface<MathAbsFRivalCompile>(*ctx);
    math::SqrtOp::attachInterface<MathSqrtRivalCompile>(*ctx);
    math::RsqrtOp::attachInterface<MathRsqrtRivalCompile>(*ctx);
    math::CbrtOp::attachInterface<MathCbrtRivalCompile>(*ctx);
    math::ExpOp::attachInterface<MathExpRivalCompile>(*ctx);
    math::Exp2Op::attachInterface<MathExp2RivalCompile>(*ctx);
    math::ExpM1Op::attachInterface<MathExpM1RivalCompile>(*ctx);
    math::LogOp::attachInterface<MathLogRivalCompile>(*ctx);
    math::Log2Op::attachInterface<MathLog2RivalCompile>(*ctx);
    math::Log10Op::attachInterface<MathLog10RivalCompile>(*ctx);
    math::Log1pOp::attachInterface<MathLog1pRivalCompile>(*ctx);
    math::SinOp::attachInterface<MathSinRivalCompile>(*ctx);
    math::CosOp::attachInterface<MathCosRivalCompile>(*ctx);
    math::TanOp::attachInterface<MathTanRivalCompile>(*ctx);
    math::AsinOp::attachInterface<MathAsinRivalCompile>(*ctx);
    math::AcosOp::attachInterface<MathAcosRivalCompile>(*ctx);
    math::AtanOp::attachInterface<MathAtanRivalCompile>(*ctx);
    math::Atan2Op::attachInterface<MathAtan2RivalCompile>(*ctx);
    math::SinhOp::attachInterface<MathSinhRivalCompile>(*ctx);
    math::CoshOp::attachInterface<MathCoshRivalCompile>(*ctx);
    math::TanhOp::attachInterface<MathTanhRivalCompile>(*ctx);
    math::AsinhOp::attachInterface<MathAsinhRivalCompile>(*ctx);
    math::AcoshOp::attachInterface<MathAcoshRivalCompile>(*ctx);
    math::AtanhOp::attachInterface<MathAtanhRivalCompile>(*ctx);
    math::ErfOp::attachInterface<MathErfRivalCompile>(*ctx);
    math::ErfcOp::attachInterface<MathErfcRivalCompile>(*ctx);
    math::CeilOp::attachInterface<MathCeilRivalCompile>(*ctx);
    math::FloorOp::attachInterface<MathFloorRivalCompile>(*ctx);
    math::RoundOp::attachInterface<MathRoundRivalCompile>(*ctx);
    math::RoundEvenOp::attachInterface<MathRoundEvenRivalCompile>(*ctx);
    math::TruncOp::attachInterface<MathTruncRivalCompile>(*ctx);
    math::PowFOp::attachInterface<MathPowFRivalCompile>(*ctx);
    math::FPowIOp::attachInterface<MathFPowIRivalCompile>(*ctx);
    math::CopySignOp::attachInterface<MathCopySignRivalCompile>(*ctx);
    math::FmaOp::attachInterface<MathFmaRivalCompile>(*ctx);
  });

  registry.addExtension(+[](MLIRContext *ctx, func::FuncDialect *dialect) {
    func::FuncOp::attachInterface<FuncRivalCompile>(*ctx);
  });
}
