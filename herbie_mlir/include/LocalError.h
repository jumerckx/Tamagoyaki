#ifndef HERBIE_MLIR_LOCAL_ERROR_H
#define HERBIE_MLIR_LOCAL_ERROR_H

#include "IntervalSearch.h"
#include "mlir/IR/Attributes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Value.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include <cstddef>
#include <cstdint>
#include <vector>

namespace herbie {

// ============================================================================
// Float Attribute Utilities
// ============================================================================

/// Create a FloatAttr from a double value, rounded to the given FloatType's
/// semantics (e.g., f32 rounds the double to single precision).
mlir::FloatAttr makeRoundedFloatAttr(mlir::FloatType ty, double value);

/// Round a double value to the given FloatType's precision and return as
/// double.
double roundToTypeAsDouble(mlir::FloatType ty, double value);

// ============================================================================
// Op Folding Utilities
// ============================================================================

/// Fold an operation with the given constant operand attributes.
/// Returns the result attributes on success, or failure if the op cannot
/// be folded to constants (e.g., fold returns Values instead of Attributes,
/// or the fold itself fails).
mlir::FailureOr<mlir::SmallVector<mlir::Attribute>>
foldWithConstantOperands(mlir::Operation *op,
                         mlir::ArrayRef<mlir::Attribute> operandAttrs);

// ============================================================================
// ULP Distance
// ============================================================================

/// Compute the ULP (unit in the last place) distance between two doubles
/// interpreted in the given FloatType's representation.
/// For f32, values are first cast to float before computing ordinal distance.
uint64_t ulpDistance(mlir::FloatType ty, double a, double b);

// ============================================================================
// Local Error Computation
// ============================================================================

/// Per-operation local error statistics aggregated over all sample points.
struct OpLocalError {
  mlir::Operation *op = nullptr;
  uint64_t maxUlp = 0;
  double sumUlp = 0.0;
  unsigned count = 0;
  unsigned foldFailures = 0;

  double meanUlp() const { return count > 0 ? sumUlp / count : 0.0; }
};

/// Compute local error for all operations in `sortedOps` using sampled data.
///
/// @param sortedOps     Operations in topological order.
/// @param valueToRootIdx  Maps each MLIR Value to its index in the rival
///                        machine's root array (and thus in
///                        samplingResult.results[point][idx]).
/// @param samplingResult  The sampled points and their exact (high-precision)
///                        evaluation results from Rival.
/// @return A vector of OpLocalError, one per operation that has float results.
std::vector<OpLocalError>
computeLocalErrors(mlir::ArrayRef<mlir::Operation *> sortedOps,
                   const mlir::DenseMap<mlir::Value, size_t> &valueToRootIdx,
                   const SamplingResult &samplingResult);

} // namespace herbie

#endif // HERBIE_MLIR_LOCAL_ERROR_H
