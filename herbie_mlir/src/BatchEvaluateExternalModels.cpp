#include "BatchEvaluateExternalModels.h"
#include "HerbieMLIROpInterfaces.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/Support/LLVM.h"
#include "llvm/Support/ErrorHandling.h"
#include <cmath>
#include <cstddef>

using namespace mlir;
using namespace herbie;

namespace {

// ============================================================================
// Macros for generating BatchEvaluate implementations
// ============================================================================

#define BATCH_UNARY_OP(NAME, OP_TYPE, FUNC)                                    \
  struct NAME : public BatchEvaluateInterface::ExternalModel<NAME, OP_TYPE> {  \
    void batchEvaluate(Operation *op, ArrayRef<const double *> ins,            \
                       double *out, size_t n) const {                          \
      const double *x = ins[0];                                                \
      for (size_t i = 0; i < n; ++i)                                           \
        out[i] = FUNC(x[i]);                                                   \
    }                                                                          \
  };

#define BATCH_BINARY_OP(NAME, OP_TYPE, FUNC)                                   \
  struct NAME : public BatchEvaluateInterface::ExternalModel<NAME, OP_TYPE> {  \
    void batchEvaluate(Operation *op, ArrayRef<const double *> ins,            \
                       double *out, size_t n) const {                          \
      const double *a = ins[0], *b = ins[1];                                   \
      for (size_t i = 0; i < n; ++i)                                           \
        out[i] = FUNC(a[i], b[i]);                                             \
    }                                                                          \
  };

#define BATCH_BINARY_EXPR(NAME, OP_TYPE, EXPR)                                 \
  struct NAME : public BatchEvaluateInterface::ExternalModel<NAME, OP_TYPE> {  \
    void batchEvaluate(Operation *op, ArrayRef<const double *> ins,            \
                       double *out, size_t n) const {                          \
      const double *a = ins[0], *b = ins[1];                                   \
      for (size_t i = 0; i < n; ++i)                                           \
        out[i] = EXPR;                                                         \
    }                                                                          \
  };

// ============================================================================
// Arith Dialect Operations
// ============================================================================

BATCH_BINARY_EXPR(ArithAddFBatch, arith::AddFOp, a[i] + b[i])
BATCH_BINARY_EXPR(ArithSubFBatch, arith::SubFOp, a[i] - b[i])
BATCH_BINARY_EXPR(ArithMulFBatch, arith::MulFOp, a[i] * b[i])
BATCH_BINARY_EXPR(ArithDivFBatch, arith::DivFOp, a[i] / b[i])
BATCH_BINARY_OP(ArithRemFBatch, arith::RemFOp, fmod)
BATCH_BINARY_OP(ArithMaximumFBatch, arith::MaximumFOp, fmax)
BATCH_BINARY_OP(ArithMaxNumFBatch, arith::MaxNumFOp, fmax)
BATCH_BINARY_OP(ArithMinimumFBatch, arith::MinimumFOp, fmin)
BATCH_BINARY_OP(ArithMinNumFBatch, arith::MinNumFOp, fmin)

struct ArithNegFBatch
    : public BatchEvaluateInterface::ExternalModel<ArithNegFBatch,
                                                   arith::NegFOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *x = ins[0];
    for (size_t i = 0; i < n; ++i)
      out[i] = -x[i];
  }
};

// arith.select: out = cond ? lhs : rhs (cond encoded as 1.0/0.0)
struct ArithSelectBatch
    : public BatchEvaluateInterface::ExternalModel<ArithSelectBatch,
                                                   arith::SelectOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *cond = ins[0], *lhs = ins[1], *rhs = ins[2];
    for (size_t i = 0; i < n; ++i)
      out[i] = (cond[i] != 0.0) ? lhs[i] : rhs[i];
  }
};

// Pass-through ops (identity in double-land)
struct ArithExtFBatch
    : public BatchEvaluateInterface::ExternalModel<ArithExtFBatch,
                                                   arith::ExtFOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *x = ins[0];
    for (size_t i = 0; i < n; ++i)
      out[i] = x[i];
  }
};

struct ArithTruncFBatch
    : public BatchEvaluateInterface::ExternalModel<ArithTruncFBatch,
                                                   arith::TruncFOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *x = ins[0];
    for (size_t i = 0; i < n; ++i)
      out[i] = x[i];
  }
};

// arith.cmpf: result is 1.0 for true, 0.0 for false
struct ArithCmpFBatch
    : public BatchEvaluateInterface::ExternalModel<ArithCmpFBatch,
                                                   arith::CmpFOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    auto pred = cast<arith::CmpFOp>(op).getPredicate();
    const double *a = ins[0], *b = ins[1];
    for (size_t i = 0; i < n; ++i) {
      bool result;
      switch (pred) {
      case arith::CmpFPredicate::OEQ:
        result = a[i] == b[i];
        break;
      case arith::CmpFPredicate::UEQ:
        result = std::isunordered(a[i], b[i]) || a[i] == b[i];
        break;
      case arith::CmpFPredicate::ONE:
        result = a[i] != b[i] && !std::isunordered(a[i], b[i]);
        break;
      case arith::CmpFPredicate::UNE:
        result = a[i] != b[i];
        break;
      case arith::CmpFPredicate::OLT:
        result = a[i] < b[i];
        break;
      case arith::CmpFPredicate::ULT:
        result = std::isunordered(a[i], b[i]) || a[i] < b[i];
        break;
      case arith::CmpFPredicate::OLE:
        result = a[i] <= b[i];
        break;
      case arith::CmpFPredicate::ULE:
        result = std::isunordered(a[i], b[i]) || a[i] <= b[i];
        break;
      case arith::CmpFPredicate::OGT:
        result = a[i] > b[i];
        break;
      case arith::CmpFPredicate::UGT:
        result = std::isunordered(a[i], b[i]) || a[i] > b[i];
        break;
      case arith::CmpFPredicate::OGE:
        result = a[i] >= b[i];
        break;
      case arith::CmpFPredicate::UGE:
        result = std::isunordered(a[i], b[i]) || a[i] >= b[i];
        break;
      default:
        result = false;
      }
      out[i] = result ? 1.0 : 0.0;
    }
  }
};

// arith.constant: fill output with the constant's double value
struct ArithConstantBatch
    : public BatchEvaluateInterface::ExternalModel<ArithConstantBatch,
                                                   arith::ConstantOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    auto floatAttr =
        dyn_cast<FloatAttr>(cast<arith::ConstantOp>(op).getValue());
    double val = floatAttr ? floatAttr.getValueAsDouble()
                           : std::numeric_limits<double>::quiet_NaN();
    for (size_t i = 0; i < n; ++i)
      out[i] = val;
  }
};

// ============================================================================
// Math Dialect Operations
// ============================================================================

// Unary operations
BATCH_UNARY_OP(MathAbsFBatch, math::AbsFOp, fabs)
BATCH_UNARY_OP(MathSqrtBatch, math::SqrtOp, sqrt)
BATCH_UNARY_OP(MathCbrtBatch, math::CbrtOp, cbrt)
BATCH_UNARY_OP(MathExpBatch, math::ExpOp, exp)
BATCH_UNARY_OP(MathExp2Batch, math::Exp2Op, exp2)
BATCH_UNARY_OP(MathExpM1Batch, math::ExpM1Op, expm1)
BATCH_UNARY_OP(MathLogBatch, math::LogOp, log)
BATCH_UNARY_OP(MathLog2Batch, math::Log2Op, log2)
BATCH_UNARY_OP(MathLog10Batch, math::Log10Op, log10)
BATCH_UNARY_OP(MathLog1pBatch, math::Log1pOp, log1p)
BATCH_UNARY_OP(MathSinBatch, math::SinOp, sin)
BATCH_UNARY_OP(MathCosBatch, math::CosOp, cos)
BATCH_UNARY_OP(MathTanBatch, math::TanOp, tan)
BATCH_UNARY_OP(MathAsinBatch, math::AsinOp, asin)
BATCH_UNARY_OP(MathAcosBatch, math::AcosOp, acos)
BATCH_UNARY_OP(MathAtanBatch, math::AtanOp, atan)
BATCH_UNARY_OP(MathSinhBatch, math::SinhOp, sinh)
BATCH_UNARY_OP(MathCoshBatch, math::CoshOp, cosh)
BATCH_UNARY_OP(MathTanhBatch, math::TanhOp, tanh)
BATCH_UNARY_OP(MathAsinhBatch, math::AsinhOp, asinh)
BATCH_UNARY_OP(MathAcoshBatch, math::AcoshOp, acosh)
BATCH_UNARY_OP(MathAtanhBatch, math::AtanhOp, atanh)
BATCH_UNARY_OP(MathErfBatch, math::ErfOp, erf)
BATCH_UNARY_OP(MathErfcBatch, math::ErfcOp, erfc)
BATCH_UNARY_OP(MathCeilBatch, math::CeilOp, ceil)
BATCH_UNARY_OP(MathFloorBatch, math::FloorOp, floor)
BATCH_UNARY_OP(MathRoundBatch, math::RoundOp, round)
BATCH_UNARY_OP(MathRoundEvenBatch, math::RoundEvenOp, rint)
BATCH_UNARY_OP(MathTruncBatch, math::TruncOp, trunc)

// Binary operations
BATCH_BINARY_OP(MathAtan2Batch, math::Atan2Op, atan2)
BATCH_BINARY_OP(MathPowFBatch, math::PowFOp, pow)
BATCH_BINARY_OP(MathCopySignBatch, math::CopySignOp, copysign)

// math.fpowi: pow with integer exponent (both come as doubles here)
BATCH_BINARY_OP(MathFPowIBatch, math::FPowIOp, pow)

// math.fma: a*b + c
struct MathFmaBatch
    : public BatchEvaluateInterface::ExternalModel<MathFmaBatch, math::FmaOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *a = ins[0], *b = ins[1], *c = ins[2];
    for (size_t i = 0; i < n; ++i)
      out[i] = fma(a[i], b[i], c[i]);
  }
};

// math.rsqrt: 1/sqrt(x)
struct MathRsqrtBatch
    : public BatchEvaluateInterface::ExternalModel<MathRsqrtBatch,
                                                   math::RsqrtOp> {
  void batchEvaluate(Operation *op, ArrayRef<const double *> ins, double *out,
                     size_t n) const {
    const double *x = ins[0];
    for (size_t i = 0; i < n; ++i)
      out[i] = 1.0 / sqrt(x[i]);
  }
};

#undef BATCH_UNARY_OP
#undef BATCH_BINARY_OP
#undef BATCH_BINARY_EXPR

} // namespace

// ============================================================================
// Registration
// ============================================================================

void herbie::registerBatchEvaluateExternalModels(DialectRegistry &registry) {
  registry.addExtension(+[](MLIRContext *ctx, arith::ArithDialect *dialect) {
    arith::AddFOp::attachInterface<ArithAddFBatch>(*ctx);
    arith::SubFOp::attachInterface<ArithSubFBatch>(*ctx);
    arith::MulFOp::attachInterface<ArithMulFBatch>(*ctx);
    arith::DivFOp::attachInterface<ArithDivFBatch>(*ctx);
    arith::NegFOp::attachInterface<ArithNegFBatch>(*ctx);
    arith::RemFOp::attachInterface<ArithRemFBatch>(*ctx);
    arith::MaximumFOp::attachInterface<ArithMaximumFBatch>(*ctx);
    arith::MaxNumFOp::attachInterface<ArithMaxNumFBatch>(*ctx);
    arith::MinimumFOp::attachInterface<ArithMinimumFBatch>(*ctx);
    arith::MinNumFOp::attachInterface<ArithMinNumFBatch>(*ctx);
    arith::SelectOp::attachInterface<ArithSelectBatch>(*ctx);
    arith::CmpFOp::attachInterface<ArithCmpFBatch>(*ctx);
    arith::ConstantOp::attachInterface<ArithConstantBatch>(*ctx);
    arith::ExtFOp::attachInterface<ArithExtFBatch>(*ctx);
    arith::TruncFOp::attachInterface<ArithTruncFBatch>(*ctx);
  });

  registry.addExtension(+[](MLIRContext *ctx, math::MathDialect *dialect) {
    math::AbsFOp::attachInterface<MathAbsFBatch>(*ctx);
    math::SqrtOp::attachInterface<MathSqrtBatch>(*ctx);
    math::RsqrtOp::attachInterface<MathRsqrtBatch>(*ctx);
    math::CbrtOp::attachInterface<MathCbrtBatch>(*ctx);
    math::ExpOp::attachInterface<MathExpBatch>(*ctx);
    math::Exp2Op::attachInterface<MathExp2Batch>(*ctx);
    math::ExpM1Op::attachInterface<MathExpM1Batch>(*ctx);
    math::LogOp::attachInterface<MathLogBatch>(*ctx);
    math::Log2Op::attachInterface<MathLog2Batch>(*ctx);
    math::Log10Op::attachInterface<MathLog10Batch>(*ctx);
    math::Log1pOp::attachInterface<MathLog1pBatch>(*ctx);
    math::SinOp::attachInterface<MathSinBatch>(*ctx);
    math::CosOp::attachInterface<MathCosBatch>(*ctx);
    math::TanOp::attachInterface<MathTanBatch>(*ctx);
    math::AsinOp::attachInterface<MathAsinBatch>(*ctx);
    math::AcosOp::attachInterface<MathAcosBatch>(*ctx);
    math::AtanOp::attachInterface<MathAtanBatch>(*ctx);
    math::Atan2Op::attachInterface<MathAtan2Batch>(*ctx);
    math::SinhOp::attachInterface<MathSinhBatch>(*ctx);
    math::CoshOp::attachInterface<MathCoshBatch>(*ctx);
    math::TanhOp::attachInterface<MathTanhBatch>(*ctx);
    math::AsinhOp::attachInterface<MathAsinhBatch>(*ctx);
    math::AcoshOp::attachInterface<MathAcoshBatch>(*ctx);
    math::AtanhOp::attachInterface<MathAtanhBatch>(*ctx);
    math::ErfOp::attachInterface<MathErfBatch>(*ctx);
    math::ErfcOp::attachInterface<MathErfcBatch>(*ctx);
    math::CeilOp::attachInterface<MathCeilBatch>(*ctx);
    math::FloorOp::attachInterface<MathFloorBatch>(*ctx);
    math::RoundOp::attachInterface<MathRoundBatch>(*ctx);
    math::RoundEvenOp::attachInterface<MathRoundEvenBatch>(*ctx);
    math::TruncOp::attachInterface<MathTruncBatch>(*ctx);
    math::PowFOp::attachInterface<MathPowFBatch>(*ctx);
    math::FPowIOp::attachInterface<MathFPowIBatch>(*ctx);
    math::CopySignOp::attachInterface<MathCopySignBatch>(*ctx);
    math::FmaOp::attachInterface<MathFmaBatch>(*ctx);
  });
}
