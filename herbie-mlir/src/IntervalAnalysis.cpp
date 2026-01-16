#include "IntervalAnalysis.h"
#include "RivalRAII.h"
#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace mlir::dataflow;

namespace herbie {

static constexpr uint32_t kDefaultPrecision = 53;

IntervalValue IntervalValue::join(const IntervalValue &lhs,
                                  const IntervalValue &rhs) {
  if (lhs.isUninitialized())
    return rhs;
  if (rhs.isUninitialized())
    return lhs;
  if (lhs.isUnknown() || rhs.isUnknown())
    return getUnknown();

  const rival_Float *lhsLo = rival_ival_lower(lhs.getInterval());
  const rival_Float *lhsHi = rival_ival_upper(lhs.getInterval());
  const rival_Float *rhsLo = rival_ival_lower(rhs.getInterval());
  const rival_Float *rhsHi = rival_ival_upper(rhs.getInterval());

  const rival_Float *newLo = rival_float_cmp(lhsLo, rhsLo) < 0 ? lhsLo : rhsLo;
  const rival_Float *newHi = rival_float_cmp(lhsHi, rhsHi) > 0 ? lhsHi : rhsHi;

  return IntervalValue(makeSharedIval(rival_ival_new(newLo, newHi)));
}

bool IntervalValue::operator==(const IntervalValue &rhs) const {
  if (isUninitialized() && rhs.isUninitialized())
    return true;
  if (isUninitialized() != rhs.isUninitialized())
    return false;
  if (isUnknown() && rhs.isUnknown())
    return true;
  if (isUnknown() != rhs.isUnknown())
    return false;

  const rival_Float *lhsLo = rival_ival_lower(getInterval());
  const rival_Float *lhsHi = rival_ival_upper(getInterval());
  const rival_Float *rhsLo = rival_ival_lower(rhs.getInterval());
  const rival_Float *rhsHi = rival_ival_upper(rhs.getInterval());

  return rival_float_cmp(lhsLo, rhsLo) == 0 &&
         rival_float_cmp(lhsHi, rhsHi) == 0;
}

void IntervalValue::print(llvm::raw_ostream &os) const {
  if (isUninitialized()) {
    os << "<uninitialized>";
    return;
  }
  if (isUnknown()) {
    os << "<unknown>";
    return;
  }

  auto loStr = rival::toString(rival_ival_lower(getInterval()));
  auto hiStr = rival::toString(rival_ival_upper(getInterval()));
  os << "[" << loStr << ", " << hiStr << "]";
}

static IntervalValue fromConstantInt(int64_t value) {
  auto lo = rival::makeFloat(kDefaultPrecision, static_cast<double>(value));
  auto hi = rival::makeFloat(kDefaultPrecision, static_cast<double>(value));
  return IntervalValue(makeSharedIval(rival_ival_new(lo.get(), hi.get())));
}

static IntervalValue fromConstantFloat(double value) {
  return IntervalValue(
      makeSharedIval(rival_ival_from_f64(kDefaultPrecision, value)));
}

static IntervalValue intervalAdd(const IntervalValue &lhs,
                                 const IntervalValue &rhs) {
  if (lhs.isUnknown() || rhs.isUnknown())
    return IntervalValue::getUnknown();

  const rival_Float *lhsLo = rival_ival_lower(lhs.getInterval());
  const rival_Float *lhsHi = rival_ival_upper(lhs.getInterval());
  const rival_Float *rhsLo = rival_ival_lower(rhs.getInterval());
  const rival_Float *rhsHi = rival_ival_upper(rhs.getInterval());

  double newLoVal = rival_float_to_f64(lhsLo) + rival_float_to_f64(rhsLo);
  double newHiVal = rival_float_to_f64(lhsHi) + rival_float_to_f64(rhsHi);

  auto newLo = rival::makeFloat(kDefaultPrecision, newLoVal);
  auto newHi = rival::makeFloat(kDefaultPrecision, newHiVal);
  return IntervalValue(
      makeSharedIval(rival_ival_new(newLo.get(), newHi.get())));
}

static IntervalValue intervalSub(const IntervalValue &lhs,
                                 const IntervalValue &rhs) {
  if (lhs.isUnknown() || rhs.isUnknown())
    return IntervalValue::getUnknown();

  const rival_Float *lhsLo = rival_ival_lower(lhs.getInterval());
  const rival_Float *lhsHi = rival_ival_upper(lhs.getInterval());
  const rival_Float *rhsLo = rival_ival_lower(rhs.getInterval());
  const rival_Float *rhsHi = rival_ival_upper(rhs.getInterval());

  double newLoVal = rival_float_to_f64(lhsLo) - rival_float_to_f64(rhsHi);
  double newHiVal = rival_float_to_f64(lhsHi) - rival_float_to_f64(rhsLo);

  auto newLo = rival::makeFloat(kDefaultPrecision, newLoVal);
  auto newHi = rival::makeFloat(kDefaultPrecision, newHiVal);
  return IntervalValue(
      makeSharedIval(rival_ival_new(newLo.get(), newHi.get())));
}

static IntervalValue intervalMul(const IntervalValue &lhs,
                                 const IntervalValue &rhs) {
  if (lhs.isUnknown() || rhs.isUnknown())
    return IntervalValue::getUnknown();

  double a = rival_float_to_f64(rival_ival_lower(lhs.getInterval()));
  double b = rival_float_to_f64(rival_ival_upper(lhs.getInterval()));
  double c = rival_float_to_f64(rival_ival_lower(rhs.getInterval()));
  double d = rival_float_to_f64(rival_ival_upper(rhs.getInterval()));

  double products[] = {a * c, a * d, b * c, b * d};
  double lo = products[0], hi = products[0];
  for (double p : products) {
    if (p < lo)
      lo = p;
    if (p > hi)
      hi = p;
  }

  auto newLo = rival::makeFloat(kDefaultPrecision, lo);
  auto newHi = rival::makeFloat(kDefaultPrecision, hi);
  return IntervalValue(
      makeSharedIval(rival_ival_new(newLo.get(), newHi.get())));
}

LogicalResult
IntervalAnalysis::visitOperation(Operation *op,
                                 ArrayRef<const IntervalLattice *> operands,
                                 ArrayRef<IntervalLattice *> results) {
  auto setResultUnknown = [&]() {
    for (auto *result : results) {
      propagateIfChanged(result, result->join(IntervalValue::getUnknown()));
    }
    return success();
  };

  if (operands.empty() && results.empty())
    return success();

  for (const auto *operand : operands) {
    if (operand->getValue().isUninitialized())
      return success();
  }

  auto result =
      llvm::TypeSwitch<Operation *, IntervalValue>(op)
          .Case<arith::ConstantOp>([](arith::ConstantOp op) {
            if (auto intAttr = dyn_cast<IntegerAttr>(op.getValue())) {
              return fromConstantInt(intAttr.getInt());
            }
            if (auto floatAttr = dyn_cast<FloatAttr>(op.getValue())) {
              return fromConstantFloat(floatAttr.getValueAsDouble());
            }
            return IntervalValue::getUnknown();
          })
          .Case<arith::AddIOp>([&](arith::AddIOp) {
            return intervalAdd(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Case<arith::SubIOp>([&](arith::SubIOp) {
            return intervalSub(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Case<arith::MulIOp>([&](arith::MulIOp) {
            return intervalMul(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Case<arith::AddFOp>([&](arith::AddFOp) {
            return intervalAdd(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Case<arith::SubFOp>([&](arith::SubFOp) {
            return intervalSub(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Case<arith::MulFOp>([&](arith::MulFOp) {
            return intervalMul(operands[0]->getValue(),
                               operands[1]->getValue());
          })
          .Default([](Operation *) { return IntervalValue::getUnknown(); });

  if (results.size() == 1) {
    propagateIfChanged(results[0], results[0]->join(result));
    return success();
  }

  return setResultUnknown();
}

void IntervalAnalysis::setToEntryState(IntervalLattice *lattice) {
  propagateIfChanged(lattice, lattice->join(IntervalValue::getUnknown()));
}

} // namespace herbie
