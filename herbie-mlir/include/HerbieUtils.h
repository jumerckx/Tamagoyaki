#ifndef HERBIE_UTILS_H
#define HERBIE_UTILS_H

#include "EquivalenceDialect.h"
#include "mlir/IR/Operation.h"
#include "mlir/Support/LLVM.h"

namespace mlir::herbie {
/// Compute topological sort of operations in a GraphOp, considering only
/// operations selected by min_cost_index attributes on ClassOps.
/// Returns the sorted operations (excluding YieldOp).
SmallVector<Operation *> computeSelectedTopoSort(equivalence::GraphOp graphOp);
} // namespace mlir::herbie

#endif // HERBIE_UTILLS_H
