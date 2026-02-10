#ifndef EQUIVALENCE_UTILS_H
#define EQUIVALENCE_UTILS_H

#include "EquivalenceDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Support/LogicalResult.h"
#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace mlir::equivalence {

/// Transform a function by wrapping its body in a GraphOp.
/// If insertSingleElementEqs is true, all values are wrapped in ClassOps.
/// Returns success if the transformation was successful.
LogicalResult insertGraphInFunction(func::FuncOp funcOp,
                                    bool insertSingleElementEqs);

/// Run greedy cost-based selection on a single GraphOp.
/// Assigns min_cost_index attributes to ClassOps based on minimum-cost
/// operands.
void selectGreedy(GraphOp graphOp, int64_t defaultCost,
                  llvm::StringRef costAttributeName = "equivalence.cost");

} // namespace mlir::equivalence

#endif // EQUIVALENCE_UTILS_H
