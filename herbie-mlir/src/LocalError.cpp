#include "LocalError.h"
#include "IntervalSearch.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"
#include <cmath>
#include <cstdint>

using namespace mlir;

namespace herbie {

// ============================================================================
// Float Attribute Utilities
// ============================================================================

FloatAttr makeRoundedFloatAttr(FloatType ty, double value) {
  llvm::APFloat ap(value);
  bool losesInfo = false;
  ap.convert(ty.getFloatSemantics(), llvm::APFloat::rmNearestTiesToEven,
             &losesInfo);
  return FloatAttr::get(ty, ap);
}

double roundToTypeAsDouble(FloatType ty, double value) {
  return makeRoundedFloatAttr(ty, value).getValueAsDouble();
}

// ============================================================================
// Op Folding Utilities
// ============================================================================

FailureOr<SmallVector<Attribute>>
foldWithConstantOperands(Operation *op, ArrayRef<Attribute> operandAttrs) {
  SmallVector<OpFoldResult> foldResults;
  if (failed(op->fold(operandAttrs, foldResults)))
    return failure();

  if (foldResults.empty())
    return failure();

  SmallVector<Attribute> attrs;
  attrs.reserve(foldResults.size());
  for (OpFoldResult r : foldResults) {
    auto attr = dyn_cast<Attribute>(r);
    if (!attr)
      return failure();
    attrs.push_back(attr);
  }
  return attrs;
}

// ============================================================================
// ULP Distance
// ============================================================================

uint64_t ulpDistance(FloatType ty, double a, double b) {
  if (std::isnan(a) || std::isnan(b) || std::isinf(a) || std::isinf(b))
    return UINT64_MAX;

  if (ty.getWidth() == 32) {
    uint32_t oa = floatToOrdinal(static_cast<float>(a));
    uint32_t ob = floatToOrdinal(static_cast<float>(b));
    return oa > ob ? static_cast<uint64_t>(oa - ob)
                   : static_cast<uint64_t>(ob - oa);
  }

  uint64_t oa = floatToOrdinal(a);
  uint64_t ob = floatToOrdinal(b);
  return oa > ob ? (oa - ob) : (ob - oa);
}

// ============================================================================
// Local Error Computation
// ============================================================================

std::vector<OpLocalError>
computeLocalErrors(ArrayRef<Operation *> sortedOps,
                   const DenseMap<Value, size_t> &valueToRootIdx,
                   const SamplingResult &samplingResult) {

  std::vector<OpLocalError> errors;

  for (Operation *op : sortedOps) {
    if (op->getNumResults() == 0)
      continue;

    auto resTy = dyn_cast<FloatType>(op->getResult(0).getType());
    if (!resTy)
      continue;

    auto itRes = valueToRootIdx.find(op->getResult(0));
    if (itRes == valueToRootIdx.end())
      continue;
    size_t resRootIdx = itRes->second;

    OpLocalError errInfo;
    errInfo.op = op;

    bool allOperandsMapped = true;
    for (Value v : op->getOperands()) {
      if (!valueToRootIdx.contains(v)) {
        allOperandsMapped = false;
        break;
      }
    }
    if (!allOperandsMapped)
      continue;

    for (unsigned p = 0; p < samplingResult.sampled; ++p) {
      double exactResult = samplingResult.results[p][resRootIdx];
      double exactRounded = roundToTypeAsDouble(resTy, exactResult);

      SmallVector<Attribute> operandAttrs;
      operandAttrs.reserve(op->getNumOperands());
      bool operandsOk = true;

      for (Value v : op->getOperands()) {
        Type t = v.getType();
        size_t operandIdx = valueToRootIdx.lookup(v);
        double rivalVal = samplingResult.results[p][operandIdx];

        if (auto ft = dyn_cast<FloatType>(t)) {
          operandAttrs.push_back(makeRoundedFloatAttr(ft, rivalVal));
        } else if (auto intTy = dyn_cast<IntegerType>(t);
                   intTy && intTy.getWidth() == 1) {
          operandAttrs.push_back(
              BoolAttr::get(op->getContext(), rivalVal != 0.0));
        } else {
          operandsOk = false;
          break;
        }
      }

      if (!operandsOk) {
        ++errInfo.foldFailures;
        continue;
      }

      auto folded = foldWithConstantOperands(op, operandAttrs);
      if (failed(folded) || folded->empty()) {
        ++errInfo.foldFailures;
        continue;
      }

      auto fpAttr = dyn_cast<FloatAttr>((*folded)[0]);
      if (!fpAttr) {
        ++errInfo.foldFailures;
        continue;
      }

      double fpResult = fpAttr.getValueAsDouble();
      uint64_t ulp = ulpDistance(resTy, exactRounded, fpResult);

      if (ulp == UINT64_MAX)
        continue;

      errInfo.maxUlp = std::max(errInfo.maxUlp, ulp);
      errInfo.sumUlp += static_cast<double>(ulp);
      ++errInfo.count;
    }

    errors.push_back(errInfo);
  }

  return errors;
}

} // namespace herbie
