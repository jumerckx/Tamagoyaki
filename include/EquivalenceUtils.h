#ifndef EQUIVALENCE_UTILS_H
#define EQUIVALENCE_UTILS_H

#include "EquivalenceDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "llvm/ADT/StringRef.h"
#include <algorithm>
#include <cstdint>
#include <functional>

namespace mlir::equivalence {

/// Transform a function by wrapping its body in a GraphOp.
/// If insertSingleElementEqs is true, all values are wrapped in ClassOps.
/// Returns success if the transformation was successful.
LogicalResult insertGraphInFunction(func::FuncOp funcOp,
                                    bool insertSingleElementEqs);

/// A CostReductionFn takes (baseCost, childCosts) and returns the combined
/// cost, or -1 if unresolvable.
using CostReductionFn =
    std::function<int64_t(int64_t baseCost, ArrayRef<int64_t> childCosts)>;

inline int64_t costReductionSum(int64_t baseCost,
                                ArrayRef<int64_t> childCosts) {
  int64_t total = baseCost;
  for (int64_t c : childCosts)
    total += c;
  return total;
}

// Take the sum of the local cost and the maximum of the childCosts.
inline int64_t costReductionMax(int64_t baseCost,
                                ArrayRef<int64_t> childCosts) {
  int64_t result = baseCost;
  int64_t maxChild = 0;
  for (int64_t c : childCosts)
    maxChild = std::max(maxChild, c);
  return result + maxChild;
}

/// Run greedy cost-based selection on a single GraphOp.
/// Assigns min_cost_index attributes to ClassOps based on minimum-cost
/// operands.
void selectGreedy(GraphOp graphOp, int64_t defaultCost,
                  llvm::StringRef costAttributeName = "equivalence.cost",
                  const CostReductionFn &reductionFn = costReductionSum);

/// Clear all selection state from a GraphOp: remove min_cost_index from
/// ClassOps and the cost attribute from all other operations.
void clearSelection(GraphOp graphOp,
                    llvm::StringRef costAttributeName = "equivalence.cost");

/// Extract selected nodes from equivalence classes in a GraphOp.
/// For each ClassOp with min_cost_index set, replaces its result with the
/// selected operand, erases non-selected operand ops, and removes the cost
/// attribute. ClassOps with no uses are erased entirely. ClassOps without
/// min_cost_index are left untouched.
void extractFromGraph(GraphOp graphOp);

/// Inline a GraphOp by splicing its body into the parent block, replacing
/// graph results with yielded values, and erasing the GraphOp.
void inlineGraphOp(GraphOp graphOp);

/// Compute topological sort of operations in a GraphOp, considering only
/// operations selected by min_cost_index attributes on ClassOps.
/// Returns the sorted operations (excluding YieldOp).
SmallVector<Operation *> computeSelectedTopoSort(GraphOp graphOp);

} // namespace mlir::equivalence

#endif // EQUIVALENCE_UTILS_H
