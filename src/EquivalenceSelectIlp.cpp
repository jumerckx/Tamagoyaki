//===- EquivalenceSelectIlp.cpp - ILP-based e-node selection ----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Driver for the `equivalence-select-ilp` pass, which selects one e-node per
// e-class by solving an integer linear program. The ILP is solved with HiGHS
// (https://highs.dev).
//
// This file is compiled unconditionally so that the pass is always registered.
// The HiGHS-backed body, however, is only available when the project is
// configured with `-DTAMAGOYAKI_ENABLE_HIGHS=ON` (the default). Without HiGHS
// the pass still registers but fails at run time with a diagnostic, so builds
// that disable the dependency stay linkable and the pass is simply unavailable.
//
// The formulation is the exact acyclic-extraction ILP (see e.g. the topological
// levels model of Goharshady et al.), with pruning and warm-starting layered on
// top:
//
//   minimise   sum_i c_i s_i                                            (5a)
//   s.t.  sum_{i in C_j} s_i = A_j          for every e-class j         (5b)
//         s_i <= A_k                        for i, child class k        (5c)
//         A_r = 1                           for every root class r      (5d)
//         L_j - L_k + M Opp_i >= 1          for i, child k, j=class(i)  (5e)
//         s_i + Opp_i = 1                   for every e-node i          (5f)
//         s_i = 0                           for every pruned e-node i   (5g)
//         s_n <- s_n^heu   (warm start)                                 (5h)
//         s_i, A_j, Opp_i in {0,1}                                      (5i)
//
// with M = |C| + 1 and level variables L_j in [0, |C|].
//
// Mapping onto the equivalence dialect:
//   * Every `equivalence.class` op is an explicit e-class; every op result that
//     is *not* consumed solely by a single class op is an implicit singleton
//     e-class. Together these are C.
//   * The members (e-nodes) of an explicit class are its input operands; the
//     single member of an implicit class is the producing op. Block-argument
//     inputs are free leaf e-nodes.
//   * The children of an e-node are the e-classes of its operands.
//   * Roots R are the classes of the values yielded by the graph.
//
// The solution is written back as `min_cost_index` on each explicit class op,
// exactly as the greedy selector does, so `equivalence-extract` is unchanged.
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <cstdint>
#include <initializer_list>
#include <limits>
#include <string>
#include <utility>
#include <vector>

#ifdef TAMAGOYAKI_HIGHS_ENABLED
#include "Highs.h"
#endif

using namespace mlir;
using namespace mlir::equivalence;

namespace mlir::equivalence {
#define GEN_PASS_DEF_EQUIVALENCESELECTILP
#include "EquivalencePasses.h.inc"

namespace {

#ifdef TAMAGOYAKI_HIGHS_ENABLED

/// Marker attribute: e-nodes whose defining op carries it are pruned (5g).
constexpr llvm::StringLiteral kPrunedAttrName = "equivalence.pruned";

/// A single e-node candidate in the ILP.
struct ENode {
  int classId = -1;          // e-class this node belongs to
  int64_t cost = 0;          // local cost (objective coefficient)
  bool pruned = false;       // forced to 0 (unresolvable cost or marked)
  SmallVector<int> children; // deduplicated child e-class ids (>= 0)
  ClassOp classOp = nullptr; // explicit class this is a member of, if any
  int inputIndex = -1;       // operand index within `classOp`, else -1
};

/// The complete ILP model extracted from one GraphOp.
struct GraphModel {
  SmallVector<ENode> nodes;
  int numClasses = 0;
  // classId -> node indices belonging to that class.
  SmallVector<SmallVector<int>> classMembers;
  // classId -> is this a root class (forced active).
  SmallVector<char> classIsRoot;
};

/// Read the local cost of the operation defining `v`. Block arguments and
/// class results are free (cost 0). Returns -1 when the cost is unresolvable
/// (no attribute and a negative default), signalling the node should be pruned.
static int64_t localCost(Value v, int64_t defaultCost,
                         llvm::StringRef costAttributeName) {
  Operation *def = v.getDefiningOp();
  if (!def || isa<ClassOp>(def))
    return 0;
  if (auto attr = def->getAttrOfType<CostAttr>(costAttributeName))
    return attr.getValue();
  return defaultCost;
}

/// Build the ILP model from `graphOp`. Only the graph's own body is considered;
/// nested `equivalence.graph`s are handled by their own pass invocation and are
/// treated here as free leaves.
static GraphModel buildModel(GraphOp graphOp, int64_t defaultCost,
                             llvm::StringRef costAttributeName) {
  GraphModel model;
  Block &block = graphOp.getBody().front();

  // --- Assign e-class ids. Explicit classes first, then implicit ones. ---
  DenseMap<Operation *, int> classIdOfClassOp;
  DenseMap<Value, int> classIdOfValue; // implicit singleton classes

  for (Operation &op : block) {
    if (auto classOp = dyn_cast<ClassOp>(&op))
      classIdOfClassOp[classOp] = model.numClasses++;
  }

  auto isSolelyClassConsumed = [](Value r) {
    return r.hasOneUse() && isa<ClassOp>(*r.user_begin());
  };

  for (Operation &op : block) {
    if (isa<ClassOp, YieldOp, GraphOp>(op))
      continue;
    for (OpResult r : op.getResults()) {
      // A result consumed only by a single class op is a member of that class,
      // not a class in its own right. Everything else (yielded, fanned out,
      // used directly by another op) forms an implicit singleton e-class.
      if (r.use_empty() || isSolelyClassConsumed(r))
        continue;
      classIdOfValue[r] = model.numClasses++;
    }
  }

  model.classMembers.assign(model.numClasses, {});
  model.classIsRoot.assign(model.numClasses, 0);

  // Resolve the e-class of a value used as an operand (a child edge). Block
  // arguments and nested-graph results are free and return -1.
  auto classOfValue = [&](Value v) -> int {
    Operation *def = v.getDefiningOp();
    if (!def)
      return -1;
    if (isa<ClassOp>(def)) {
      auto it = classIdOfClassOp.find(def);
      return it == classIdOfClassOp.end() ? -1 : it->second;
    }
    auto it = classIdOfValue.find(v);
    return it == classIdOfValue.end() ? -1 : it->second;
  };

  // Child e-classes of the e-node that produces value `v`.
  auto childrenOfValue = [&](Value v) -> SmallVector<int> {
    SmallVector<int> children;
    Operation *def = v.getDefiningOp();
    if (!def)
      return children;
    if (isa<ClassOp>(def)) {
      // Degenerate nested-class member: its only child is that inner class.
      if (int c = classOfValue(v); c >= 0)
        children.push_back(c);
      return children;
    }
    for (Value operand : def->getOperands()) {
      int c = classOfValue(operand);
      if (c >= 0 && !llvm::is_contained(children, c))
        children.push_back(c);
    }
    return children;
  };

  auto addNode = [&](int classId, Value v, ClassOp classOp, int inputIndex) {
    ENode node;
    node.classId = classId;
    node.classOp = classOp;
    node.inputIndex = inputIndex;
    node.children = childrenOfValue(v);
    int64_t c = localCost(v, defaultCost, costAttributeName);
    if (c < 0) {
      node.pruned = true;
      node.cost = 0;
    } else {
      node.cost = c;
    }
    if (Operation *def = v.getDefiningOp())
      if (def->hasAttr(kPrunedAttrName))
        node.pruned = true;
    int idx = model.nodes.size();
    model.nodes.push_back(std::move(node));
    model.classMembers[classId].push_back(idx);
  };

  // --- Build e-nodes for every class member. ---
  for (Operation &op : block) {
    if (auto classOp = dyn_cast<ClassOp>(&op)) {
      int classId = classIdOfClassOp[classOp];
      for (auto [i, input] : llvm::enumerate(classOp.getInputs()))
        addNode(classId, input, classOp, static_cast<int>(i));
      continue;
    }
    if (isa<YieldOp, GraphOp>(op))
      continue;
    for (OpResult r : op.getResults()) {
      auto it = classIdOfValue.find(r);
      if (it != classIdOfValue.end())
        addNode(it->second, r, /*classOp=*/nullptr, /*inputIndex=*/-1);
    }
  }

  // --- Roots: the classes of the yielded values. ---
  if (auto yield = dyn_cast<YieldOp>(block.getTerminator()))
    for (Value v : yield.getValues())
      if (int c = classOfValue(v); c >= 0)
        model.classIsRoot[c] = 1;

  return model;
}

/// Compute a warm-start assignment (5h) from the greedy heuristic. Fills
/// `colValue` for all columns with a fully consistent selection: the greedy
/// choice per class, activation propagated from the roots, opposite variables,
/// and topological levels. Returns false if no usable heuristic exists.
static bool computeWarmStart(GraphOp graphOp, const GraphModel &model,
                             int64_t defaultCost,
                             llvm::StringRef costAttributeName, int sBase,
                             int aBase, int oppBase, int lBase,
                             std::vector<double> &colValue) {
  const int N = model.nodes.size();
  const int C = model.numClasses;

  DenseMap<Operation *, int64_t> opCosts =
      computeGraphCosts(graphOp, defaultCost, costAttributeName);

  // Greedy pick: for each class, the member with the lowest accumulated cost.
  SmallVector<int> pickedNode(C, -1);
  for (int j = 0; j < C; ++j) {
    int64_t best = std::numeric_limits<int64_t>::max();
    for (int i : model.classMembers[j]) {
      if (model.nodes[i].pruned)
        continue;
      // Accumulated subtree cost, mirroring the greedy selector.
      int64_t cost = 0;
      // A member's accumulated cost is the cost stored for its defining op;
      // block-arg / class members are free.
      // (classMembers preserves per-class order, so ties keep the first.)
      // Recover the value via the class-op input list when available.
      // For robustness fall back to the node's local cost.
      cost = model.nodes[i].cost;
      if (ClassOp classOp = model.nodes[i].classOp) {
        Value v = classOp.getInputs()[model.nodes[i].inputIndex];
        if (Operation *def = v.getDefiningOp()) {
          auto it = opCosts.find(def);
          if (it != opCosts.end())
            cost = it->second;
        } else {
          cost = 0;
        }
      }
      if (cost < best) {
        best = cost;
        pickedNode[j] = i;
      }
    }
    if (pickedNode[j] < 0)
      return false; // a class with no selectable member: no warm start
  }

  // Propagate activation from the roots along the picked members.
  SmallVector<char> active(C, 0);
  SmallVector<int> worklist;
  for (int j = 0; j < C; ++j)
    if (model.classIsRoot[j]) {
      active[j] = 1;
      worklist.push_back(j);
    }
  while (!worklist.empty()) {
    int j = worklist.pop_back_val();
    for (int child : model.nodes[pickedNode[j]].children)
      if (!active[child]) {
        active[child] = 1;
        worklist.push_back(child);
      }
  }

  // Selection / activation / opposite variables.
  for (int i = 0; i < N; ++i)
    colValue[sBase + i] = 0.0;
  for (int j = 0; j < C; ++j) {
    colValue[aBase + j] = active[j] ? 1.0 : 0.0;
    if (active[j])
      colValue[sBase + pickedNode[j]] = 1.0;
  }
  for (int i = 0; i < N; ++i)
    colValue[oppBase + i] = 1.0 - colValue[sBase + i];

  // Levels: L_j >= L_k + 1 along the selected edges. Fixed-point over active
  // classes; inactive classes stay at 0. Bounded by C iterations.
  SmallVector<int> level(C, 0);
  for (int iter = 0; iter < C; ++iter) {
    bool changed = false;
    for (int j = 0; j < C; ++j) {
      if (!active[j])
        continue;
      for (int child : model.nodes[pickedNode[j]].children) {
        if (child == j)
          continue;
        if (level[j] < level[child] + 1) {
          level[j] = level[child] + 1;
          changed = true;
        }
      }
    }
    if (!changed)
      break;
  }
  for (int j = 0; j < C; ++j)
    colValue[lBase + j] = static_cast<double>(std::min(level[j], C));

  return true;
}

/// Solve the extraction ILP for a single GraphOp and write the selection back
/// as `min_cost_index` attributes. Returns failure on solver error or an
/// infeasible model.
static LogicalResult solveGraph(GraphOp graphOp, int64_t defaultCost,
                                llvm::StringRef costAttributeName,
                                bool warmStart) {
  GraphModel model = buildModel(graphOp, defaultCost, costAttributeName);

  const int N = model.nodes.size();
  const int C = model.numClasses;
  if (N == 0 || C == 0)
    return success(); // nothing to select

  // Column layout: [ s_i | A_j | Opp_i | L_j ].
  const int sBase = 0;
  const int aBase = sBase + N;
  const int oppBase = aBase + C;
  const int lBase = oppBase + N;
  const int numCol = lBase + C;

  const double M = static_cast<double>(C) + 1.0;

  HighsModel hm;
  HighsLp &lp = hm.lp_;
  lp.num_col_ = numCol;
  lp.sense_ = ObjSense::kMinimize;
  lp.offset_ = 0.0;

  lp.col_cost_.assign(numCol, 0.0);
  lp.col_lower_.assign(numCol, 0.0);
  lp.col_upper_.assign(numCol, 0.0);
  lp.integrality_.assign(numCol, HighsVarType::kInteger);

  // s_i in {0,1}; objective coefficient c_i; pruned nodes fixed to 0 (5g, 5i).
  for (int i = 0; i < N; ++i) {
    lp.col_cost_[sBase + i] = static_cast<double>(model.nodes[i].cost);
    lp.col_lower_[sBase + i] = 0.0;
    lp.col_upper_[sBase + i] = model.nodes[i].pruned ? 0.0 : 1.0;
  }
  // A_j in {0,1}; root classes forced to 1 (5d, 5i).
  for (int j = 0; j < C; ++j) {
    lp.col_lower_[aBase + j] = model.classIsRoot[j] ? 1.0 : 0.0;
    lp.col_upper_[aBase + j] = 1.0;
  }
  // Opp_i in {0,1} (5i).
  for (int i = 0; i < N; ++i) {
    lp.col_lower_[oppBase + i] = 0.0;
    lp.col_upper_[oppBase + i] = 1.0;
  }
  // L_j in [0, C].
  for (int j = 0; j < C; ++j) {
    lp.col_lower_[lBase + j] = 0.0;
    lp.col_upper_[lBase + j] = static_cast<double>(C);
  }

  // Build the constraint matrix row-wise.
  std::vector<double> rowLower;
  std::vector<double> rowUpper;
  std::vector<HighsInt> aStart;
  std::vector<HighsInt> aIndex;
  std::vector<double> aValue;
  aStart.push_back(0);

  auto addRow = [&](std::initializer_list<std::pair<int, double>> entries,
                    double lower, double upper) {
    for (auto [col, coeff] : entries) {
      aIndex.push_back(col);
      aValue.push_back(coeff);
    }
    aStart.push_back(static_cast<HighsInt>(aIndex.size()));
    rowLower.push_back(lower);
    rowUpper.push_back(upper);
  };

  // (5b) sum_{i in C_j} s_i - A_j = 0.
  for (int j = 0; j < C; ++j) {
    for (int i : model.classMembers[j]) {
      aIndex.push_back(sBase + i);
      aValue.push_back(1.0);
    }
    aIndex.push_back(aBase + j);
    aValue.push_back(-1.0);
    aStart.push_back(static_cast<HighsInt>(aIndex.size()));
    rowLower.push_back(0.0);
    rowUpper.push_back(0.0);
  }

  // (5c) s_i - A_k <= 0  and  (5e) L_j - L_k + M Opp_i >= 1.
  for (int i = 0; i < N; ++i) {
    const ENode &node = model.nodes[i];
    for (int k : node.children) {
      addRow({{sBase + i, 1.0}, {aBase + k, -1.0}}, -kHighsInf, 0.0);
      if (k != node.classId)
        addRow(
            {{lBase + node.classId, 1.0}, {lBase + k, -1.0}, {oppBase + i, M}},
            1.0, kHighsInf);
    }
  }

  // (5f) s_i + Opp_i = 1.
  for (int i = 0; i < N; ++i)
    addRow({{sBase + i, 1.0}, {oppBase + i, 1.0}}, 1.0, 1.0);

  lp.num_row_ = static_cast<HighsInt>(rowLower.size());
  lp.row_lower_ = std::move(rowLower);
  lp.row_upper_ = std::move(rowUpper);
  lp.a_matrix_.format_ = MatrixFormat::kRowwise;
  lp.a_matrix_.start_ = std::move(aStart);
  lp.a_matrix_.index_ = std::move(aIndex);
  lp.a_matrix_.value_ = std::move(aValue);

  Highs highs;
  highs.setOptionValue("output_flag", false);
  if (highs.passModel(hm) != HighsStatus::kOk) {
    graphOp.emitError("HiGHS rejected the extraction ILP");
    return failure();
  }

  // (5h) warm start from the greedy heuristic.
  if (warmStart) {
    HighsSolution start;
    start.col_value.assign(numCol, 0.0);
    if (computeWarmStart(graphOp, model, defaultCost, costAttributeName, sBase,
                         aBase, oppBase, lBase, start.col_value))
      (void)highs.setSolution(start); // best-effort; ignored if not usable
  }

  if (highs.run() != HighsStatus::kOk) {
    graphOp.emitError("HiGHS failed to solve the extraction ILP");
    return failure();
  }
  if (highs.getModelStatus() != HighsModelStatus::kOptimal) {
    graphOp.emitError("extraction ILP is infeasible or unbounded");
    return failure();
  }

  // Write the selection back onto the explicit class ops as min_cost_index.
  const std::vector<double> &sol = highs.getSolution().col_value;
  OpBuilder builder(graphOp.getContext());
  for (int j = 0; j < C; ++j) {
    for (int i : model.classMembers[j]) {
      const ENode &node = model.nodes[i];
      if (!node.classOp || node.inputIndex < 0)
        continue;
      if (sol[sBase + i] > 0.5) {
        node.classOp->setAttr("min_cost_index",
                              builder.getI64IntegerAttr(node.inputIndex));
        break;
      }
    }
  }

  return success();
}

#endif // TAMAGOYAKI_HIGHS_ENABLED

class EquivalenceSelectIlp
    : public impl::EquivalenceSelectIlpBase<EquivalenceSelectIlp> {
public:
  using impl::EquivalenceSelectIlpBase<
      EquivalenceSelectIlp>::EquivalenceSelectIlpBase;

  void runOnOperation() final {
#ifndef TAMAGOYAKI_HIGHS_ENABLED
    getOperation().emitError()
        << "equivalence-select-ilp is unavailable: tamagoyaki was built "
           "without HiGHS support (reconfigure with "
           "-DTAMAGOYAKI_ENABLE_HIGHS=ON)";
    return signalPassFailure();
#else
    int64_t defaultCostVal = this->defaultCost;
    std::string attrName = this->costAttributeName;
    bool warm = this->warmStart;

    WalkResult result = getOperation().walk([&](GraphOp graphOp) {
      if (failed(solveGraph(graphOp, defaultCostVal, attrName, warm)))
        return WalkResult::interrupt();
      return WalkResult::advance();
    });
    if (result.wasInterrupted())
      return signalPassFailure();
#endif
  }
};

} // namespace
} // namespace mlir::equivalence
