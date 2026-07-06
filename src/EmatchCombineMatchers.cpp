//===- EmatchCombineMatchers.cpp - Combine matchers for e-matching --------===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// `ematch-combine-matchers` merges every `match.matcher` in a module into one
// combined matcher, materializing the matcher tree as IR (`match.try`,
// `match.switch_op_name`, `match.switch_type`). It is a variant of the upstream
// `match-combine-matchers` pass: the pool construction, failure-tree building,
// IR emission, switch folding, and navigation sinking are all reused verbatim;
// only the *predicate ordering* differs.
//
// Where the upstream pass orders predicates by frequency, this pass orders them
// by operation-navigation position: it walks the tree of navigated operations
// depth-first and emits, at each operation, all predicates that depend only on
// the operations navigated so far (`has_name`, `check_*`, ...) before descending
// to the next `match.get_defining_op`. That makes every discriminating name
// check a branch point *above* the next defining-op navigation, so once
// `ematchify` turns each `get_defining_op` into a loop over an
// equivalence class, the later loops only run for candidates that already passed
// the earlier checks — avoiding the multiplicative blow-up the frequency
// ordering produces.
//
// The canonical predicate "pool" is the same SSA-native structure as upstream:
//  * Predicate identity     := `Operation *` into the pool.
//  * Canonical value ID     := `Value` produced by a pool op (or `poolRoot`).
//  * Dependency edges       := SSA def-use in the pool.
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"

#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include <functional>
#include <memory>
#include <tuple>
#include <utility>
#include <vector>

using namespace mlir;
using namespace mlir::match;

namespace mlir::ematch {
#define GEN_PASS_DEF_EMATCHCOMBINEMATCHERSPASS
#include "EmatchPasses.h.inc"
} // namespace mlir::ematch

namespace {

//===----------------------------------------------------------------------===//
// Pool key
//
// Hash key used to dedup canonical pool ops. Two input-matcher ops collapse to
// the same pool op iff they have the same op name, same raw attribute
// dictionary, and their operands map to the same pool SSA values.
//===----------------------------------------------------------------------===//

struct PoolKey {
  OperationName name;
  DictionaryAttr attrs;
  SmallVector<Value, 4> operands;

  bool operator==(const PoolKey &o) const {
    return name == o.name && attrs == o.attrs && operands == o.operands;
  }
};

} // namespace

namespace llvm {
template <>
struct DenseMapInfo<PoolKey> {
  static unsigned getHashValue(const PoolKey &k) {
    return llvm::hash_combine(
        k.name, k.attrs,
        llvm::hash_combine_range(k.operands.begin(), k.operands.end()));
  }
  static bool isEqual(const PoolKey &a, const PoolKey &b) { return a == b; }
};
} // namespace llvm

namespace {

//===----------------------------------------------------------------------===//
// MatcherInfo: per-input-matcher state.
//===----------------------------------------------------------------------===//

struct MatcherInfo {
  MatcherOp matcher;

  /// The (unique) `match.success` op in this matcher.
  SuccessOp success;

  /// Set of canonical pool ops this matcher exercises.
  DenseSet<Operation *> preds;

  /// Map from this matcher's SSA values to their canonical pool values.
  IRMapping toCanonical;
};

//===----------------------------------------------------------------------===//
// TreeNode: in-memory failure spine, materialized into IR at the end.
//===----------------------------------------------------------------------===//

struct TreeNode {
  enum class Kind { Test, Success };
  Kind kind;

  // ---- Test node ----
  Operation *pred = nullptr; ///< canonical pool op
  std::unique_ptr<TreeNode> successPath;
  std::unique_ptr<TreeNode> failurePath;

  // ---- Success node ----
  SuccessOp originalSuccess;
  SmallVector<Value, 4> successInputs; ///< canonical pool values
};

//===----------------------------------------------------------------------===//
// Combiner
//===----------------------------------------------------------------------===//

class Combiner {
public:
  Combiner(ModuleOp module) : module(module) {}
  LogicalResult run();

private:
  LogicalResult buildCanonicalPool();
  void orderPoolByOperationPosition();
  void finalizePoolOrder();
  void buildTree();
  void emitCombinedMatcher();

  Operation *getOrCreatePoolOp(Operation *modelOp,
                               ArrayRef<Value> canonicalOperands);

  void propagate(std::unique_ptr<TreeNode> &node, MatcherInfo &info,
                 unsigned predIdx);

  void emitNode(OpBuilder &builder, Location loc, TreeNode *node,
                IRMapping &mapping);

  void foldSwitches(Region &region);

  void sinkNavigationOps(Region &region);

  ModuleOp module;

  /// Canonical pool: a standalone block whose ops are the unique predicates.
  /// The block argument is the canonical root operation value.
  std::unique_ptr<Block> poolBody;
  Value poolRoot;

  /// Hash-based dedup for canonical pool ops.
  DenseMap<PoolKey, Operation *> poolDedup;

  /// Frequency (coverage) of a pool op across matchers, and its creation order.
  DenseMap<Operation *, unsigned> primary;
  DenseMap<Operation *, unsigned> insertionIndex;

  /// Pool ops in final (operation-position) order. Block order is kept in sync.
  std::vector<Operation *> sortedPoolOps;

  std::vector<MatcherInfo> matcherInfos;

  std::unique_ptr<TreeNode> treeRoot;
};

} // namespace

//===----------------------------------------------------------------------===//
// Phase 1: build the canonical pool by walking input matchers.
//===----------------------------------------------------------------------===//

Operation *Combiner::getOrCreatePoolOp(Operation *modelOp,
                                       ArrayRef<Value> canonicalOperands) {
  PoolKey key{modelOp->getName(), modelOp->getAttrDictionary(),
              SmallVector<Value, 4>(canonicalOperands)};
  if (auto it = poolDedup.find(key); it != poolDedup.end())
    return it->second;

  IRMapping mapping;
  for (auto [orig, canonical] :
       llvm::zip(modelOp->getOperands(), canonicalOperands))
    mapping.map(orig, canonical);
  Operation *poolOp = modelOp->cloneWithoutRegions(mapping);
  poolBody->push_back(poolOp);

  insertionIndex[poolOp] = poolDedup.size();
  poolDedup[key] = poolOp;
  return poolOp;
}

LogicalResult Combiner::buildCanonicalPool() {
  SmallVector<MatcherOp> inputMatchers(module.getOps<MatcherOp>());

  poolBody = std::make_unique<Block>();
  poolRoot = poolBody->addArgument(
      pdl::OperationType::get(module.getContext()), module.getLoc());

  for (MatcherOp matcher : inputMatchers) {
    MatcherInfo info;
    info.matcher = matcher;

    Block &body = matcher.getBodyRegion().front();
    info.toCanonical.map(body.getArgument(0), poolRoot);

    for (Operation &op : body) {
      if (auto succ = dyn_cast<SuccessOp>(&op)) {
        if (info.success)
          return op.emitOpError("ematch-combine-matchers expects exactly one "
                                "`match.success` per input matcher");
        info.success = succ;
        continue;
      }

      if (isa<TryOp, SwitchOpNameOp, SwitchTypeOp>(&op))
        return op.emitOpError(
            "ematch-combine-matchers does not support nested `try`/`switch_*` "
            "in input matchers");

      SmallVector<Value, 4> canonicalOperands;
      canonicalOperands.reserve(op.getNumOperands());
      for (Value operand : op.getOperands())
        canonicalOperands.push_back(info.toCanonical.lookup(operand));

      Operation *poolOp = getOrCreatePoolOp(&op, canonicalOperands);

      for (auto [origRes, poolRes] :
           llvm::zip(op.getResults(), poolOp->getResults()))
        info.toCanonical.map(origRes, poolRes);

      if (info.preds.insert(poolOp).second)
        ++primary[poolOp];
    }

    if (!info.success)
      return matcher.emitOpError(
          "ematch-combine-matchers expects a `match.success` in every input "
          "matcher");

    matcherInfos.push_back(std::move(info));
  }

  return success();
}

//===----------------------------------------------------------------------===//
// Phase 2: order canonical pool ops by operation-navigation position.
//===----------------------------------------------------------------------===//

namespace {

/// A navigation op that introduces a fresh operation (an e-class loop after
/// ematchify): `get_defining_op`, or `get_each` whose element type
/// is an operation (upward `get_users`+`get_each` navigation).
static bool isOperationDefiningNav(Operation *op) {
  if (isa<GetDefiningOpOp>(op))
    return true;
  if (auto each = dyn_cast<GetEachOp>(op))
    return isa<pdl::OperationType>(each.getResult().getType());
  return false;
}

/// The operation node a value descends from: walk up the (single) navigation
/// chain until an operation-defining nav is reached (return it) or the pool root
/// block argument is reached (return nullptr, the root sentinel).
static Operation *operationNodeOf(Value v) {
  while (Operation *def = v.getDefiningOp()) {
    if (isOperationDefiningNav(def))
      return def;
    if (def->getNumOperands() == 0)
      break;
    // Value-producing navigation ops carry their navigation source as operand 0
    // (`is_not_null` -> optionalValue, `get_operand`/`get_result` -> op, ...).
    v = def->getOperand(0);
  }
  return nullptr;
}

/// The set of operation nodes a pool op depends on (union over all operands, so
/// multi-operand predicates such as `equal` depend on all their operations). The
/// root is recorded as the nullptr sentinel.
static void collectOpDeps(Operation *op, DenseSet<Operation *> &deps) {
  SmallVector<Value, 4> worklist(op->getOperands());
  DenseSet<Value> visited;
  while (!worklist.empty()) {
    Value v = worklist.pop_back_val();
    if (!visited.insert(v).second)
      continue;
    Operation *def = v.getDefiningOp();
    if (!def) {
      deps.insert(nullptr); // reached the pool root
      continue;
    }
    if (isOperationDefiningNav(def)) {
      deps.insert(def); // this node subsumes its ancestors
      continue;
    }
    for (Value o : def->getOperands())
      worklist.push_back(o);
  }
}

/// Scheduling tier within one operation node: tests first, then cheap
/// navigation, then loop navigation. Readiness (SSA) still dominates.
static int scheduleTier(Operation *op) {
  if (isOperationDefiningNav(op))
    return 2; // loop navigation
  if (isa<GetOperandOp, GetOperandsOp, GetResultOp, GetResultsOp, GetAttributeOp,
          GetValueTypeOp, GetAttributeTypeOp, GetUsersOp, ExtractOp>(op))
    return 1; // cheap navigation
  return 0;   // tests / everything else
}

} // namespace

void Combiner::finalizePoolOrder() {
  // The operation-position DFS order is already SSA-valid (producers precede
  // consumers within a node; parent nodes precede child nodes; each op is
  // emitted no earlier than any op it depends on). We must NOT run a
  // wave/ASAP topological sort here: that would pull shallower independent
  // navigations (e.g. the sibling `get_defining_op`) ahead of the deeper
  // discriminating predicates (`has_name`) and destroy the grouping. Simply
  // reflect the DFS order into the pool block so SSA dominance holds.
  for (Operation *op : sortedPoolOps)
    op->moveBefore(poolBody.get(), poolBody->end());
}

void Combiner::orderPoolByOperationPosition() {
  sortedPoolOps.clear();

  // (A) Build the operation tree. Every operation-defining nav has exactly one
  // value source, hence exactly one parent (nullptr = root sentinel).
  SmallVector<Operation *> rootChildren;
  DenseMap<Operation *, SmallVector<Operation *, 4>> childrenOf;
  for (Operation &op : *poolBody) {
    if (!isOperationDefiningNav(&op))
      continue;
    Operation *parent = operationNodeOf(op.getOperand(0));
    if (parent)
      childrenOf[parent].push_back(&op);
    else
      rootChildren.push_back(&op);
  }

  // Order siblings by coverage (shared by the most matchers) then creation
  // order, mirroring xDSL's `best_op` heuristic and preserving prefix sharing.
  auto sortChildren = [&](SmallVectorImpl<Operation *> &kids) {
    llvm::sort(kids, [&](Operation *a, Operation *b) {
      return std::make_tuple(primary[a], insertionIndex[b]) >
             std::make_tuple(primary[b], insertionIndex[a]);
    });
  };
  sortChildren(rootChildren);
  for (auto &entry : childrenOf)
    sortChildren(entry.second);

  // (B) DFS pre-order index per node (root = 0). Nodes visited later in the DFS
  // get larger indices.
  DenseMap<Operation *, unsigned> dfsIndex;
  unsigned counter = 0;
  std::function<void(ArrayRef<Operation *>)> assignIdx =
      [&](ArrayRef<Operation *> kids) {
        for (Operation *c : kids) {
          dfsIndex[c] = ++counter;
          assignIdx(childrenOf[c]);
        }
      };
  assignIdx(rootChildren);

  auto indexOf = [&](Operation *node) -> unsigned {
    return node ? dfsIndex[node] : 0;
  };

  // (C) Assign every pool op to a node. An operation-defining nav belongs to its
  // own node; any other op is emitted at the dep node navigated last in DFS
  // order (largest index), i.e. where its dependency set first becomes fully
  // satisfied. This also places cross-sibling predicates (e.g. `equal(B,C)`)
  // after both operations are navigated, which is SSA-valid.
  DenseMap<Operation *, SmallVector<Operation *, 4>> ownOf;
  SmallVector<Operation *> rootOwn;
  for (Operation &op : *poolBody) {
    Operation *node;
    if (isOperationDefiningNav(&op)) {
      node = &op;
    } else {
      DenseSet<Operation *> deps;
      collectOpDeps(&op, deps);
      node = nullptr;
      unsigned best = 0;
      for (Operation *d : deps) {
        unsigned idx = indexOf(d);
        if (idx >= best) {
          best = idx;
          node = d;
        }
      }
    }
    if (node)
      ownOf[node].push_back(&op);
    else
      rootOwn.push_back(&op);
  }

  // (D) DFS emission: at each node, list-schedule its own ops (producers before
  // consumers; among ready ops prefer lower tier, tie-break by creation order),
  // then recurse into children.
  auto listScheduleInto = [&](ArrayRef<Operation *> ownList) {
    DenseSet<Operation *> own(ownList.begin(), ownList.end());
    DenseSet<Operation *> scheduled;
    auto isReady = [&](Operation *op) {
      for (Value v : op->getOperands())
        if (Operation *def = v.getDefiningOp())
          if (own.contains(def) && !scheduled.contains(def))
            return false;
      return true;
    };
    for (size_t emitted = 0; emitted < ownList.size(); ++emitted) {
      Operation *best = nullptr;
      int bestTier = 0;
      unsigned bestIdx = 0;
      for (Operation *op : ownList) {
        if (scheduled.contains(op) || !isReady(op))
          continue;
        int tier = scheduleTier(op);
        unsigned idx = insertionIndex[op];
        if (!best || tier < bestTier || (tier == bestTier && idx < bestIdx)) {
          best = op;
          bestTier = tier;
          bestIdx = idx;
        }
      }
      assert(best && "node ops must be schedulable: the SSA graph is acyclic");
      scheduled.insert(best);
      sortedPoolOps.push_back(best);
    }
  };

  std::function<void(Operation *, ArrayRef<Operation *>)> emitDfs =
      [&](Operation *node, ArrayRef<Operation *> kids) {
        listScheduleInto(node ? ArrayRef<Operation *>(ownOf[node]) : rootOwn);
        for (Operation *c : kids)
          emitDfs(c, childrenOf[c]);
      };
  emitDfs(/*root=*/nullptr, rootChildren);

  assert(sortedPoolOps.size() == poolDedup.size() &&
         "every pool op must be emitted exactly once");

  finalizePoolOrder();
}

//===----------------------------------------------------------------------===//
// Phase 3: build the in-memory failure tree.
//===----------------------------------------------------------------------===//

void Combiner::propagate(std::unique_ptr<TreeNode> &node, MatcherInfo &info,
                         unsigned predIdx) {
  if (predIdx == sortedPoolOps.size()) {
    auto leaf = std::make_unique<TreeNode>();
    leaf->kind = TreeNode::Kind::Success;
    leaf->originalSuccess = info.success;
    leaf->successInputs.reserve(info.success.getInputs().size());
    for (Value input : info.success.getInputs())
      leaf->successInputs.push_back(info.toCanonical.lookup(input));
    leaf->failurePath = std::move(node);
    node = std::move(leaf);
    return;
  }

  Operation *current = sortedPoolOps[predIdx];
  if (!info.preds.contains(current)) {
    propagate(node, info, predIdx + 1);
    return;
  }

  if (!node) {
    auto fresh = std::make_unique<TreeNode>();
    fresh->kind = TreeNode::Kind::Test;
    fresh->pred = current;
    node = std::move(fresh);
    propagate(node->successPath, info, predIdx + 1);
    return;
  }

  if (node->kind == TreeNode::Kind::Test && node->pred == current) {
    propagate(node->successPath, info, predIdx + 1);
    return;
  }

  // Different predicate already at this position: recurse into the failure path;
  // this builds a chain of `try` alternatives.
  propagate(node->failurePath, info, predIdx);
}

void Combiner::buildTree() {
  for (MatcherInfo &info : matcherInfos)
    propagate(treeRoot, info, /*predIdx=*/0);
}

//===----------------------------------------------------------------------===//
// Phase 4: emit IR by cloning canonical pool ops into the combined matcher.
//===----------------------------------------------------------------------===//

void Combiner::emitNode(OpBuilder &builder, Location loc, TreeNode *node,
                        IRMapping &mapping) {
  bool hadTestSibling = false;
  while (node) {
    if (node->kind == TreeNode::Kind::Success) {
      SmallVector<Value, 4> inputs;
      inputs.reserve(node->successInputs.size());
      for (Value canonical : node->successInputs)
        inputs.push_back(mapping.lookup(canonical));
      SuccessOp orig = node->originalSuccess;
      SuccessOp::create(builder, loc, orig.getRewriterAttr(),
                        orig.getBenefitAttr(), inputs);
      node = node->failurePath.get();
      continue;
    }

    if (node->failurePath || hadTestSibling) {
      TryOp tryOp = TryOp::create(builder, loc);
      Block &tryBlock = tryOp.getBody().emplaceBlock();
      {
        OpBuilder::InsertionGuard guard(builder);
        builder.setInsertionPointToStart(&tryBlock);
        IRMapping tryMapping = mapping;
        builder.clone(*node->pred, tryMapping);
        emitNode(builder, loc, node->successPath.get(), tryMapping);
      }
      hadTestSibling = true;
      node = node->failurePath.get();
    } else {
      builder.clone(*node->pred, mapping);
      node = node->successPath.get();
    }
  }
}

//===----------------------------------------------------------------------===//
// Switch folding
//===----------------------------------------------------------------------===//

namespace {

template <typename TestOpT, typename GetTestedValueFn, typename GetCaseAttrFn>
static bool foldSwitchAt(Block &block, Block::iterator startIt,
                         GetTestedValueFn getTested, GetCaseAttrFn getCaseAttr,
                         SmallVectorImpl<TryOp> &cases, Value &operand,
                         SmallVectorImpl<Attribute> &caseAttrs) {
  operand = nullptr;
  cases.clear();
  caseAttrs.clear();
  for (auto it = startIt; it != block.end(); ++it) {
    auto tryOp = dyn_cast<TryOp>(*it);
    if (!tryOp)
      break;
    Block &tb = tryOp.getBody().front();
    if (tb.empty())
      break;
    auto testOp = dyn_cast<TestOpT>(&tb.front());
    if (!testOp)
      break;
    Value tested = getTested(testOp);
    if (tested.getParentBlock() == &tb)
      break;
    if (!operand)
      operand = tested;
    else if (operand != tested)
      break;
    cases.push_back(tryOp);
    caseAttrs.push_back(getCaseAttr(testOp));
  }
  return cases.size() >= 2;
}

} // namespace

void Combiner::foldSwitches(Region &region) {
  for (Block &block : region) {
    for (auto it = block.begin(); it != block.end();) {
      // --- has_name -> switch_op_name ---
      {
        SmallVector<TryOp> cases;
        SmallVector<Attribute> attrs;
        Value operand;
        if (foldSwitchAt<HasNameOp>(
                block, it, [](HasNameOp h) { return h.getOp(); },
                [](HasNameOp h) -> Attribute { return h.getNameAttr(); }, cases,
                operand, attrs)) {
          OpBuilder builder(cases.front());
          Location loc = cases.front().getLoc();
          auto switchOp = SwitchOpNameOp::create(
              builder, loc, operand, builder.getArrayAttr(attrs),
              /*caseRegionsCount=*/cases.size());
          for (auto [i, caseTry] : llvm::enumerate(cases)) {
            Region &caseRegion = switchOp.getCaseRegions()[i];
            Block &newBlock = caseRegion.emplaceBlock();
            Block &oldBlock = caseTry.getBody().front();
            oldBlock.front().erase(); // drop the has_name test
            newBlock.getOperations().splice(newBlock.end(),
                                            oldBlock.getOperations());
          }
          for (TryOp t : cases)
            t.erase();
          it = std::next(Block::iterator(switchOp));
          continue;
        }
      }

      // --- has_type -> switch_type ---
      {
        SmallVector<TryOp> cases;
        SmallVector<Attribute> attrs;
        Value operand;
        if (foldSwitchAt<HasTypeOp>(
                block, it, [](HasTypeOp h) { return h.getTypeValue(); },
                [](HasTypeOp h) -> Attribute { return h.getConstantTypeAttr(); },
                cases, operand, attrs)) {
          OpBuilder builder(cases.front());
          Location loc = cases.front().getLoc();
          auto switchOp = SwitchTypeOp::create(
              builder, loc, operand, builder.getArrayAttr(attrs),
              /*caseRegionsCount=*/cases.size());
          for (auto [i, caseTry] : llvm::enumerate(cases)) {
            Region &caseRegion = switchOp.getCaseRegions()[i];
            Block &newBlock = caseRegion.emplaceBlock();
            Block &oldBlock = caseTry.getBody().front();
            oldBlock.front().erase();
            newBlock.getOperations().splice(newBlock.end(),
                                            oldBlock.getOperations());
          }
          for (TryOp t : cases)
            t.erase();
          it = std::next(Block::iterator(switchOp));
          continue;
        }
      }

      ++it;
    }
  }

  for (Block &block : region)
    for (Operation &op : block)
      for (Region &nested : op.getRegions())
        foldSwitches(nested);
}

//===----------------------------------------------------------------------===//
// Navigation sinking
//===----------------------------------------------------------------------===//

namespace {

/// Pure navigation ops: side-effect-free value producers that can be freely
/// re-placed as long as they still dominate their uses. `get_each` is excluded
/// (it carries control flow / lowers to a foreach loop), so an
/// operation-introducing `get_defining_op` stays where the ordering placed it.
static bool isPureNavigationOp(Operation *op) {
  return isa<GetOperandOp, GetOperandsOp, GetResultOp, GetResultsOp,
             GetAttributeOp, GetDefiningOpOp, GetValueTypeOp, GetAttributeTypeOp,
             GetUsersOp, ExtractOp>(op);
}

static Operation *ancestorInBlock(Operation *u, Block *block) {
  Operation *cur = u;
  while (cur->getBlock() != block) {
    cur = cur->getBlock()->getParentOp();
    assert(cur && "expected block to be an ancestor of the use");
  }
  return cur;
}

static Region *childRegionContaining(Operation *anchor, Operation *u) {
  Operation *cur = u;
  while (cur->getParentOp() != anchor)
    cur = cur->getParentOp();
  return cur->getParentRegion();
}

static std::pair<Block *, Operation *> computeSinkTarget(Operation *n) {
  Value v = n->getResult(0);
  if (v.use_empty())
    return {nullptr, nullptr};

  SmallVector<Operation *, 4> users(v.getUsers());
  Block *block = n->getBlock();
  while (true) {
    Operation *earliest = nullptr;
    Operation *commonAnchor = nullptr;
    bool allSameAnchor = true;
    for (Operation *u : users) {
      Operation *anchor = ancestorInBlock(u, block);
      if (!earliest || anchor->isBeforeInBlock(earliest))
        earliest = anchor;
      if (!commonAnchor)
        commonAnchor = anchor;
      else if (commonAnchor != anchor)
        allSameAnchor = false;
    }

    if (allSameAnchor && commonAnchor->getNumRegions() > 0 &&
        !llvm::is_contained(users, commonAnchor)) {
      Region *target = nullptr;
      bool single = true;
      for (Operation *u : users) {
        Region *r = childRegionContaining(commonAnchor, u);
        if (!target)
          target = r;
        else if (target != r) {
          single = false;
          break;
        }
      }
      if (single && target && target->hasOneBlock()) {
        block = &target->front();
        continue;
      }
    }

    return {block, earliest};
  }
}

} // namespace

void Combiner::sinkNavigationOps(Region &region) {
  SmallVector<Operation *> navOps;
  region.walk([&](Operation *op) {
    if (isPureNavigationOp(op))
      navOps.push_back(op);
  });

  // Drop dead navigation ops first (iterate to a fixpoint).
  bool erased = true;
  while (erased) {
    erased = false;
    for (Operation *&op : navOps) {
      if (op && op->use_empty()) {
        op->erase();
        op = nullptr;
        erased = true;
      }
    }
  }
  llvm::erase(navOps, nullptr);

  // Sink each navigation op toward its first use (iterate to a fixpoint).
  bool changed = true;
  while (changed) {
    changed = false;
    for (Operation *op : navOps) {
      auto [block, before] = computeSinkTarget(op);
      if (!before)
        continue;
      if (op->getBlock() == block) {
        bool needMove = false;
        for (Operation *cur = op->getNextNode(); cur != before;
             cur = cur->getNextNode()) {
          assert(cur && "first use must come after the navigation op");
          if (!isPureNavigationOp(cur)) {
            needMove = true;
            break;
          }
        }
        if (!needMove)
          continue;
      }
      op->moveBefore(before);
      changed = true;
    }
  }
}

//===----------------------------------------------------------------------===//
// Top-level emission
//===----------------------------------------------------------------------===//

void Combiner::emitCombinedMatcher() {
  if (matcherInfos.empty())
    return;

  OpBuilder builder(module.getContext());
  Location loc = module.getLoc();
  builder.setInsertionPointToStart(module.getBody());

  StringAttr symName;
  if (auto firstName = matcherInfos.front().matcher.getSymNameAttr())
    symName = firstName;

  auto combined = MatcherOp::create(builder, loc, symName);
  Block *body = &combined.getBodyRegion().emplaceBlock();
  Value rootArg = body->addArgument(builder.getType<pdl::OperationType>(), loc);

  IRMapping mapping;
  mapping.map(poolRoot, rootArg);

  builder.setInsertionPointToStart(body);
  emitNode(builder, loc, treeRoot.get(), mapping);

  foldSwitches(combined.getBodyRegion());
  sinkNavigationOps(combined.getBodyRegion());

  for (MatcherInfo &info : matcherInfos)
    info.matcher.erase();
}

LogicalResult Combiner::run() {
  if (failed(buildCanonicalPool()))
    return failure();
  orderPoolByOperationPosition();
  buildTree();
  emitCombinedMatcher();
  return success();
}

//===----------------------------------------------------------------------===//
// Pass driver
//===----------------------------------------------------------------------===//

namespace mlir::ematch {
namespace {
struct EmatchCombineMatchersPass
    : public impl::EmatchCombineMatchersPassBase<EmatchCombineMatchersPass> {
  using impl::EmatchCombineMatchersPassBase<
      EmatchCombineMatchersPass>::EmatchCombineMatchersPassBase;

  void runOnOperation() final {
    Combiner combiner(getOperation());
    if (failed(combiner.run()))
      signalPassFailure();
  }
};
} // namespace
} // namespace mlir::ematch
