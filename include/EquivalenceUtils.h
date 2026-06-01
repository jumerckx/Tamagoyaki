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
#include <mlir/IR/Operation.h>

namespace mlir::equivalence {

/// Transform a function by wrapping its body in a GraphOp.
/// If insertSingleElementEqs is true, all values are wrapped in ClassOps.
/// Returns success if the transformation was successful.
LogicalResult insertGraphInFunction(func::FuncOp funcOp,
                                    bool insertSingleElementEqs);

/// The size of a GraphOp, expressed as the number of e-classes and e-nodes it
/// contains.
struct GraphSize {
  int classes = 0;
  int nodes = 0;
};

/// Compute the number of e-classes and e-nodes in a GraphOp. Each ClassOp is an
/// e-class. Each result of a non-ClassOp is an e-node; results that are not
/// already wrapped in a (single-use) ClassOp count as an implicit e-class too.
GraphSize computeGraphSize(GraphOp graphOp);

/// A NodeCostFn takes an Operation* and returns its base cost.
/// Return -1 to indicate "unresolvable / infinitely expensive".
using NodeCostFn = std::function<int64_t(Operation *)>;

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

/// Compute total costs for all operations in a GraphOp using bottom-up
/// fixed-point iteration. Returns the cost map. For each ClassOp, the cost
/// is the minimum among its operands. For other ops, the cost is computed
/// via the reductionFn applied to base cost and child costs.
DenseMap<Operation *, int64_t>
computeGraphCosts(GraphOp graphOp, const NodeCostFn &nodeCostFn,
                  llvm::StringRef costAttributeName = "equivalence.cost",
                  const CostReductionFn &reductionFn = costReductionSum);

/// Convenience overload using a uniform default cost for all operations.
inline DenseMap<Operation *, int64_t>
computeGraphCosts(GraphOp graphOp, int64_t defaultCost,
                  llvm::StringRef costAttributeName = "equivalence.cost",
                  const CostReductionFn &reductionFn = costReductionSum) {
  return computeGraphCosts(
      graphOp, [defaultCost](Operation *) { return defaultCost; },
      costAttributeName, reductionFn);
}

/// Run greedy cost-based selection on a single GraphOp.
/// Assigns min_cost_index attributes to ClassOps based on minimum-cost
/// operands.
void selectGreedy(GraphOp graphOp, const NodeCostFn &nodeCostFn,
                  llvm::StringRef costAttributeName = "equivalence.cost",
                  const CostReductionFn &reductionFn = costReductionSum);

/// Convenience overload using a uniform default cost for all operations.
inline void
selectGreedy(GraphOp graphOp, int64_t defaultCost,
             llvm::StringRef costAttributeName = "equivalence.cost",
             const CostReductionFn &reductionFn = costReductionSum) {
  selectGreedy(
      graphOp, [defaultCost](Operation *) { return defaultCost; },
      costAttributeName, reductionFn);
}

/// Run constant-driven selection on a single GraphOp. For each ClassOp that
/// does not already have a min_cost_index and that has a constant operand,
/// selects that constant by setting min_cost_index. Classes without a constant
/// operand or that already have a selection are left untouched.
void selectConstants(GraphOp graphOp);

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
