//===- ClassOpUnionFind.cpp - Union-find data structure for ClassOp ---*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/ClassOpUnionFind.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/SimpleOperationInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/ScopeExit.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <cstddef>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

//===----------------------------------------------------------------------===//
// Scope primitives (Milestone 0)
//
// A "scope" is the body region of an `equivalence.graph`, and the scope tree
// is the graph-nesting tree (an inner graph's body is enclosed by the body of
// the graph it sits inside, regardless of any intervening non-graph regions
// such as an `scf.for` body). `ScopeId` is therefore just `Region *`, derived
// purely from IR nesting; no attribute or side table is needed.
//
// Only *graph nesting* counts as a scope boundary. A ClassOp that wraps a
// function argument (or any value defined outside every graph) lives in the
// func body and has a null scope; it is a leaf "portal" into the graph it
// feeds, and `classUnion` physically merges it into that graph's class rather
// than chaining — exactly as the original single-scope implementation did.
//===----------------------------------------------------------------------===//

namespace {
using ScopeId = mlir::Region *;

/// The nearest enclosing `equivalence.graph` body region of `op`, or null if
/// `op` is not inside any graph.
ScopeId enclosingGraphScope(Operation *op) {
  for (Region *r = op->getParentRegion(); r;) {
    Operation *parent = r->getParentOp();
    if (!parent)
      return nullptr;
    if (isa<equivalence::GraphOp>(parent))
      return r; // r is a graph body.
    r = parent->getParentRegion();
  }
  return nullptr;
}

ScopeId scopeOf(Operation *op) { return enclosingGraphScope(op); }
ScopeId scopeOf(equivalence::ClassOp c) { return scopeOf(c.getOperation()); }

/// The enclosing scope of scope `s` (the next graph body out), or null at the
/// outermost graph / for a null scope.
ScopeId parentScope(ScopeId s) {
  if (!s)
    return nullptr;
  return enclosingGraphScope(s->getParentOp());
}

/// Distance from the outermost graph (0 for a top-level graph body); a null
/// (out-of-graph) scope also reports 0.
unsigned depthOf(ScopeId s) {
  unsigned d = 0;
  for (ScopeId p = parentScope(s); p; p = parentScope(p))
    ++d;
  return d;
}
unsigned depthOf(equivalence::ClassOp c) { return depthOf(scopeOf(c)); }

/// Ancestor-or-equal test: does graph scope `outer` enclose `inner`? A scope
/// encloses itself, so equal scopes test true.
bool encloses(ScopeId outer, ScopeId inner) {
  for (ScopeId s = inner;; s = parentScope(s)) {
    if (s == outer)
      return true;
    if (!s)
      return false;
  }
}

/// Find the (unique) rep of `row` living in scope `s`, or null. Linear scan;
/// rows have at most (#scopes) entries, so this beats a nested map.
equivalence::ClassOp *findByScope(SmallVectorImpl<equivalence::ClassOp> &row,
                                  ScopeId s) {
  for (auto &c : row)
    if (scopeOf(c) == s)
      return &c;
  return nullptr;
}

/// The outermost (minimum-depth) rep of a non-empty row.
equivalence::ClassOp outermost(SmallVectorImpl<equivalence::ClassOp> &row) {
  equivalence::ClassOp best = row.front();
  unsigned bestDepth = depthOf(best);
  for (equivalence::ClassOp c : row) {
    unsigned d = depthOf(c);
    if (d < bestDepth) {
      best = c;
      bestDepth = d;
    }
  }
  return best;
}

/// The nearest *strictly enclosing* rep of scope `s` present in `row`, or null
/// if none (i.e. `s` is the outermost occupied scope).
equivalence::ClassOp
nearestEnclosingRep(SmallVectorImpl<equivalence::ClassOp> &row, ScopeId s) {
  for (ScopeId p = parentScope(s); p; p = parentScope(p))
    if (equivalence::ClassOp *hit = findByScope(row, p))
      return *hit;
  return {};
}

/// The deepest rep enclosing scope `s` (walk `s` outward to the first rep in
/// `row`), or null if none encloses `s`.
equivalence::ClassOp
deepestRepEnclosing(SmallVectorImpl<equivalence::ClassOp> &row, ScopeId s) {
  for (ScopeId p = s; p; p = parentScope(p))
    if (equivalence::ClassOp *hit = findByScope(row, p))
      return *hit;
  return {};
}
} // namespace

SmallVector<mlir::Value>
mlir::ematch::getClassVals(mlir::PatternRewriter &rewriter, mlir::Value val) {
  Operation *defOp = val.getDefiningOp();
  if (defOp == nullptr) {
    return {val};
  } else if (auto classOp = dyn_cast<equivalence::ClassOp>(defOp)) {
    return llvm::to_vector(classOp.getInputs());
  }
  return {val};
}

mlir::Value
mlir::ematch::getClassRepresentative(mlir::PatternRewriter &rewriter,
                                     mlir::Value val) {
  Operation *defOp = val.getDefiningOp();
  if (defOp == nullptr) {
    return val;
  } else if (auto classOp = dyn_cast<equivalence::ClassOp>(defOp)) {
    return classOp.getInputs().front();
  }
  return val;
}

equivalence::ClassOp
mlir::ematch::getCanonicalLeader(equivalence::ClassOp classOp) {
  assert(classOp->getBlock());
  Value leaderVal = classOp.getLeader();
  if (!leaderVal)
    return classOp; // I am the leader.

  auto parentOp = cast<equivalence::ClassOp>(leaderVal.getDefiningOp());
  assert(parentOp->getBlock());
  if (!parentOp.getLeader())
    return parentOp; // My parent is the leader.

  // Path compression: find root leader and update my pointer.
  equivalence::ClassOp root = getCanonicalLeader(parentOp);
  classOp.getLeaderMutable().assign(root.getResult());
  return root;
}

mlir::Value mlir::ematch::getClassResult(mlir::PatternRewriter &rewriter,
                                         mlir::Value val) {
  if (val == nullptr) {
    return val;
  }
  if (auto classOp = val.hasOneUse()
                         ? dyn_cast<equivalence::ClassOp>(*val.user_begin())
                         : nullptr) {
    return classOp.getResult();
  }
  return val;
}

SmallVector<mlir::Value>
mlir::ematch::getClassResults(mlir::PatternRewriter &rewriter,
                              mlir::ValueRange vals) {
  SmallVector<Value> results;
  results.reserve(vals.size());

  for (Value val : vals) {
    results.push_back(getClassResult(rewriter, val));
  }

  return results;
}

// Erase the first occurrence of target from classOp input list.
// Instead of using erase directly, it first swaps with the last element to make
// erase O(1).
static void swappedErase(equivalence::ClassOp classOp, Value target) {
  auto inputs = classOp.getInputsMutable();

  // Instead of searching the operand in the inputs, which is O(#inputs),
  // search it from the uses.
  // Since the uses are limited by the number of classes, this is cheaper.
  for (auto &use : target.getUses()) {
    if (use.getOwner() != classOp.getOperation())
      continue;

    unsigned i = use.getOperandNumber();
    // Check whether it's an actual input, and not a leader.
    if (i >= inputs.size())
      continue;

    // Perform actual swap-erase.
    unsigned last = inputs.size() - 1;
    if (i != last)
      classOp->setOperand(i, inputs[last].get());
    inputs.erase(last);
    return;
  }
}

equivalence::ClassOp getClassOpIfExists(Value val) {
  if (auto *defOp = val.getDefiningOp()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*defOp))
      return classOp;
  }
  for (Operation *user : val.getUsers()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*user))
      return classOp;
  }
  return nullptr;
}

equivalence::ClassOp mlir::ematch::getClassOp(mlir::PatternRewriter &rewriter,
                                              mlir::Value val) {

  if (auto classOp = getClassOpIfExists(val)) {
    return classOp;
  }
  // If the value is not part of an eclass yet, create one
  OpBuilder builder(val.getContext());
  assert(!val.getDefiningOp() ||
         !dyn_cast<equivalence::ClassOp>(val.getDefiningOp()));
  builder.setInsertionPointAfterValue(val);

  // E-classes must never live outside a graph. A value defined outside every
  // graph (e.g. a function argument or module-level constant) would otherwise
  // get its ClassOp placed next to the definition, in the func body. Hoist such
  // "portal" classes to the start of the outermost graph that encloses a use,
  // so they share that graph's scope and merge into it like any other class.
  Region *defRegion = val.getParentRegion();
  bool definedInGraph = false;
  for (Region *r = defRegion; r; r = r->getParentRegion())
    if (r->getParentOp() && isa<equivalence::GraphOp>(r->getParentOp())) {
      definedInGraph = true;
      break;
    }
  if (!definedInGraph) {
    equivalence::GraphOp target;
    for (Operation *user : val.getUsers()) {
      equivalence::GraphOp outer;
      for (Operation *p = user; p; p = p->getParentOp())
        if (auto g = dyn_cast<equivalence::GraphOp>(p))
          outer = g; // keep walking: ends on the outermost enclosing graph.
      if (outer) {
        target = outer;
        break;
      }
    }
    if (target)
      builder.setInsertionPointToStart(&target.getBody().front());
  }

  auto classOp = equivalence::ClassOp::create(
      builder, val.getLoc(), TypeRange{val.getType()}, ValueRange{val},
      /*leader=*/Value{}, /*min_cost_index=*/nullptr);
  rewriter.replaceUsesWithIf(
      val, classOp.getResult(),
      [&classOp](OpOperand &operand) { return operand.getOwner() != classOp; });
  return classOp;
}

void ClassOpUnionFind::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::Value a, mlir::Value b) {
  if (a == b) {
    return;
  }

  equivalence::ClassOp classA = getClassOp(rewriter, a);
  equivalence::ClassOp classB = getClassOp(rewriter, b);

  if (classA == classB)
    return;

  equivalence::ClassOp leader = getCanonicalLeader(classA);
  equivalence::ClassOp other = getCanonicalLeader(classB);

  if (leader == other)
    return;

  // Orientation is dictated by scope, not by rank: the leader operand is a real
  // SSA edge `other -> leader`, so `leader` must enclose `other`. On a
  // cross-scope union the outer (smaller-depth) class is therefore forced to be
  // the parent. Only when both already share a scope is the direction free, and
  // there we fall back to union-by-rank for near-O(1) finds.
  unsigned dl = depthOf(leader);
  unsigned dor = depthOf(other);

  if (dl != dor) {
    if (dl > dor)
      std::swap(leader, other);
  } else {
    if (unionRank.lookup(leader.getOperation()) <
        unionRank.lookup(other.getOperation()))
      std::swap(leader, other);
  }

  assert(encloses(scopeOf(leader), scopeOf(other)) &&
         "incomparable scopes must not occur");

  // Seed both rows before merging so `mergeScopeRows` sees a `{leader}` row to
  // collide against and a `{other}`-or-bigger row to fold in.
  rowFor(leader);
  rowFor(other);

  // Inner -> outer (or same-scope): SSA-valid, never inward.
  other.getLeaderMutable().assign(leader.getResult());

  if (dl == dor && unionRank.lookup(leader.getOperation()) ==
                       unionRank.lookup(other.getOperation()))
    unionRank[leader.getOperation()] =
        unionRank.lookup(leader.getOperation()) + 1;

  mergeScopeRows(leader, other);
  dirtyRoots.insert(leader);
}

void ClassOpUnionFind::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::Operation *op, mlir::ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    classUnion(rewriter, result, val);
}

void ClassOpUnionFind::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::ValueRange a, mlir::ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    classUnion(rewriter, va, vb);
}

void ClassOpUnionFind::queueClassUnion(mlir::Value a, mlir::Value b) {
  pendingClassUnions.emplace_back(a, b);
}

void ClassOpUnionFind::queueClassUnion(mlir::Operation *op,
                                       mlir::ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    queueClassUnion(result, val);
}

void ClassOpUnionFind::queueClassUnion(mlir::ValueRange a, mlir::ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    queueClassUnion(va, vb);
}

void ClassOpUnionFind::processPendingClassUnions(PatternRewriter &rewriter) {
  for (auto [a, b] : pendingClassUnions) {
    classUnion(rewriter, a, b);
  }
  pendingClassUnions.clear();
}

void ClassOpUnionFind::repairDuplicate(Operation *dup) {
  // `dup` was found congruent to an existing e-node while being re-keyed after
  // an operand change. Both share operands, so scheduling repair of an
  // operand-defining op lets repair()'s normal duplicate-merging path collapse
  // them.
  for (Value operand : dup->getOperands())
    if (Operation *def = operand.getDefiningOp()) {
      worklist.push_back(def);
      return;
    }

  // The congruence is detected while re-keying `dup` after one of its operands
  // was rewritten to a ClassOp result, so at least one operand must have a
  // defining op. If none does, the duplicate would silently leak.
  llvm_unreachable("repairDuplicate: congruent op has no defining-op operand");
}

//===----------------------------------------------------------------------===//
// Scope-index maintenance (Milestone 1) and rebuild phase helpers (Milestone 2)
//===----------------------------------------------------------------------===//

SmallVector<equivalence::ClassOp> &
ClassOpUnionFind::rowFor(equivalence::ClassOp root) {
  auto it = scopeReps.find(root);
  if (it != scopeReps.end())
    return it->second;
  auto &row = scopeReps[root];
  row.push_back(root); // singleton component, root trivially outermost.
  return row;
}

void ClassOpUnionFind::mergeScopeRows(equivalence::ClassOp winRoot,
                                      equivalence::ClassOp loseRoot) {
  auto loseIt = scopeReps.find(loseRoot);
  if (loseIt == scopeReps.end())
    return; // defensive: nothing to fold in.

  // Move `lose` out and erase its key first: appending into `win` below may
  // rehash `scopeReps`, which would invalidate any reference into it.
  SmallVector<equivalence::ClassOp> lose = std::move(loseIt->second);
  scopeReps.erase(loseRoot);

  auto &win = scopeReps[winRoot];
  for (equivalence::ClassOp r : lose) {
    if (equivalence::ClassOp *s = findByScope(win, scopeOf(r)))
      sameScopeDups.push_back({r, *s}); // r must fuse into the existing rep.
    else
      win.push_back(r);
    assert(encloses(scopeOf(winRoot), scopeOf(r)) &&
           "winRoot must enclose every merged rep (root-is-outermost)");
  }
}

void ClassOpUnionFind::forgetClass(equivalence::ClassOp c) {
  scopeReps.erase(c); // its own (root) row, if any.
  for (auto &kv : scopeReps) {
    auto &row = kv.second;
    for (size_t i = 0, e = row.size(); i < e; ++i)
      if (row[i] == c) {
        row[i] = row.back();
        row.pop_back();
        break;
      }
  }
}

void ClassOpUnionFind::fuseSameScope(HashConsPatternRewriter &rewriter,
                                     equivalence::ClassOp dup,
                                     equivalence::ClassOp survivor) {
  assert(scopeOf(dup) == scopeOf(survivor) &&
         "fuseSameScope requires a shared scope");

  // Dedup-append dup's inputs into survivor.
  llvm::SmallPtrSet<Value, 16> existing(survivor.getInputs().begin(),
                                        survivor.getInputs().end());
  SmallVector<Value> add;
  for (Value in : dup.getInputs())
    if (existing.insert(in).second)
      add.push_back(in);
  survivor.getInputsMutable().append(add);

  // Redirect every user of dup (e-nodes and any child class whose leader
  // operand pointed at dup) onto survivor. Same scope => still SSA-valid.
  rewriter.replaceAllUsesWith(dup.getResult(), survivor.getResult());

  dup.getInputsMutable().clear();
  dup.getLeaderMutable().clear();
  dup->remove();
  pendingErase.push_back(dup);
  forgetClass(dup);
}

void ClassOpUnionFind::reorientComponent(
    SmallVectorImpl<equivalence::ClassOp> &row) {
  if (row.empty())
    return;
  equivalence::ClassOp rootRep = outermost(row);
  rootRep.getLeaderMutable().clear();
  for (equivalence::ClassOp r : row) {
    if (r == rootRep)
      continue;
    equivalence::ClassOp tgt = nearestEnclosingRep(row, scopeOf(r));
    assert(tgt && encloses(scopeOf(tgt), scopeOf(r)) &&
           "every non-root rep has a strictly-enclosing rep");
    r.getLeaderMutable().assign(tgt.getResult());
  }
}

void ClassOpUnionFind::retargetUsersToDeepest(
    equivalence::ClassOp rep, SmallVectorImpl<equivalence::ClassOp> &row) {
  SmallVector<OpOperand *> toFix;
  for (OpOperand &u : rep.getResult().getUses()) {
    Operation *user = u.getOwner();
    // Scope-chain links (a child class pointing its leader at rep) are
    // maintained by Phase B, not here.
    if (auto uc = llvm::dyn_cast<equivalence::ClassOp>(user))
      if (uc.getLeader() == rep.getResult())
        continue;
    equivalence::ClassOp want = deepestRepEnclosing(row, scopeOf(user));
    if (want && want != rep)
      toFix.push_back(&u);
  }
  for (OpOperand *u : toFix) {
    equivalence::ClassOp want =
        deepestRepEnclosing(row, scopeOf(u->getOwner()));
    u->set(want.getResult());
    worklist.push_back(rep.getOperation());  // rep lost a user
    worklist.push_back(want.getOperation()); // want gained one
  }
}

#ifndef NDEBUG
void ClassOpUnionFind::verifyIndex() {
  for (auto &kv : scopeReps) {
    auto &row = kv.second;
    for (size_t i = 0, e = row.size(); i < e; ++i) {
      assert(row[i]->getBlock() && "stale rep in index");
      for (size_t j = i + 1; j < e; ++j)
        assert(scopeOf(row[i]) != scopeOf(row[j]) &&
               "two reps share a scope in one row");
    }
    if (!row.empty())
      assert(kv.first == outermost(row) &&
             "row must be keyed by its outermost rep");
  }
}
#endif

bool ClassOpUnionFind::rebuild(HashConsPatternRewriter &rewriter) {
  TAMAGOYAKI_SCOPED_TIMER("rebuild");
  LLVM_DEBUG({
    llvm::dbgs() << "Starting rebuild. Worklist=" << worklist.size()
                 << " sameScopeDups=" << sameScopeDups.size()
                 << " dirtyRoots=" << dirtyRoots.size() << "\n";
  });

  if (sameScopeDups.empty() && dirtyRoots.empty() && worklist.empty())
    return false;

  // Track ops that get erased during the loop below. Operations queued in
  // `todo` (or `worklist` re-entry) may be freed by `repair`'s `replaceOp`, so
  // we must not dereference their pointers afterwards. Just checking
  // `op->getBlock()` is unsafe because the Operation memory itself may have
  // been freed.
  SmallPtrSet<Operation *, 16> erasedOps;
  struct EraseTracker : public RewriterBase::ForwardingListener {
    EraseTracker(OpBuilder::Listener *previous,
                 SmallPtrSet<Operation *, 16> &erased)
        : RewriterBase::ForwardingListener(previous), erased(erased) {}
    void notifyOperationErased(Operation *op) override {
      erased.insert(op);
      RewriterBase::ForwardingListener::notifyOperationErased(op);
    }
    SmallPtrSet<Operation *, 16> &erased;
  };
  OpBuilder::Listener *previousListener = rewriter.getListener();
  EraseTracker tracker(previousListener, erasedOps);
  rewriter.setListener(&tracker);
  auto restoreListener =
      llvm::scope_exit([&] { rewriter.setListener(previousListener); });

  auto isDead = [&](Operation *op) {
    return !op || erasedOps.contains(op) || !op->getBlock();
  };

  LLVM_DEBUG(verifyIndex());

  while (!sameScopeDups.empty() || !dirtyRoots.empty() || !worklist.empty()) {
    // ---- Phase A: collapse SAME-SCOPE duplicates only ----
    {
      SmallVector<std::pair<equivalence::ClassOp, equivalence::ClassOp>> batch;
      std::swap(batch, sameScopeDups);
      for (auto [dup, survivor] : batch) {
        if (isDead(dup.getOperation()) || isDead(survivor.getOperation()))
          continue;
        fuseSameScope(rewriter, dup, survivor);
        equivalence::ClassOp root = getCanonicalLeader(survivor);
        dirtyRoots.insert(root);
        worklist.push_back(survivor.getOperation());
      }
    }

    // ---- Collect the dirty components, re-canonicalized and deduped ----
    SmallVector<equivalence::ClassOp> roots;
    {
      SmallVector<equivalence::ClassOp> dirty(dirtyRoots.begin(),
                                              dirtyRoots.end());
      dirtyRoots.clear();
      SmallPtrSet<Operation *, 16> seen;
      for (equivalence::ClassOp d : dirty) {
        if (isDead(d.getOperation()))
          continue;
        equivalence::ClassOp root = getCanonicalLeader(d);
        if (isDead(root.getOperation()))
          continue;
        if (seen.insert(root.getOperation()).second)
          roots.push_back(root);
      }
    }

    // ---- Phase B: reorient leaders outward, per dirty component ----
    for (equivalence::ClassOp root : roots) {
      auto it = scopeReps.find(root);
      if (it != scopeReps.end())
        reorientComponent(it->second);
    }

    // ---- Phase C: push users to the deepest visible rep, per component ----
    for (equivalence::ClassOp root : roots) {
      auto it = scopeReps.find(root);
      if (it == scopeReps.end())
        continue;
      // Snapshot the rep list: retargetUsersToDeepest pushes to the worklist
      // but does not mutate the row, yet repairs later in this loop might.
      SmallVector<equivalence::ClassOp> reps(it->second.begin(),
                                             it->second.end());
      for (equivalence::ClassOp rep : reps) {
        if (isDead(rep.getOperation()))
          continue;
        retargetUsersToDeepest(rep, it->second);
      }
    }

    // ---- Phase D: congruence repair (existing machinery) ----
    {
      llvm::SetVector<Operation *> todo;
      SmallVector<Operation *> current;
      std::swap(current, worklist);
      for (Operation *op : current) {
        if (isDead(op))
          continue;
        if (auto c = llvm::dyn_cast<equivalence::ClassOp>(op)) {
          equivalence::ClassOp leader = getCanonicalLeader(c);
          if (isDead(leader.getOperation()))
            continue;
          todo.insert(leader.getOperation());
        } else {
          // Non-ClassOp entries come from `mergeResults`/Phase C: their users
          // may have become identical and need to be deduplicated.
          todo.insert(op);
        }
      }
      for (Operation *op : todo) {
        if (isDead(op))
          continue;
        if (auto c = llvm::dyn_cast<equivalence::ClassOp>(op))
          if (c.getInputs().empty())
            continue;
        repair(rewriter, op);
      }
    }
  }

  // Now that all phases have reached a fixpoint, erase the dead eclasses that
  // were detached during Phase A.
  SmallPtrSet<Operation *, 8> erased;
  for (equivalence::ClassOp dead : pendingErase) {
    if (erased.insert(dead.getOperation()).second) {
      forgetClass(dead);
      rewriter.eraseOp(dead);
    }
  }
  pendingErase.clear();

  LLVM_DEBUG(verifyIndex());
  return true;
}

void ClassOpUnionFind::hashconsGraph(HashConsPatternRewriter &rewriter,
                                     equivalence::GraphOp graph) {
  TAMAGOYAKI_SCOPED_TIMER("hashconsGraph");

  Region *region = &graph.getBody();
  rewriter.createRootScope(region);

  SmallVector<std::pair<Operation *, Operation *>> toMerge;
  SmallPtrSet<Operation *, 8> scheduledForMerge;

  for (Operation &opRef : graph.getBody().getOps()) {
    Operation *op = &opRef;
    if (llvm::isa<equivalence::ClassOp>(op))
      continue;
    if (succeeded(rewriter.insert(op)))
      continue;

    Operation *existing = rewriter.lookup(op);
    assert(existing && existing != op &&
           "insert failed but no duplicate found");
    if (scheduledForMerge.insert(op).second)
      toMerge.emplace_back(op, existing);
  }

  for (auto [other, keep] : toMerge) {
    [[maybe_unused]] bool erased = rewriter.erase(keep).succeeded();
    assert(erased);
    [[maybe_unused]] bool inserted = rewriter.insert(keep).succeeded();
    assert(inserted);

    mergeResults(rewriter, other, keep);
    rewriter.replaceOp(other, keep);
  }
  rebuild(rewriter);
}

void ClassOpUnionFind::repair(HashConsPatternRewriter &rewriter,
                              Operation *op) {
  // For a ClassOp we look at users of its single class result; for any
  // other operation we look at users of all of its results.
  auto classOp = llvm::dyn_cast<equivalence::ClassOp>(op);

  llvm::DenseMap<Operation *, Operation *, SimpleOperationInfo> uniqueParents;
  // Collect pairs of duplicate operations to merge AFTER the loop
  SmallVector<std::pair<Operation *, Operation *>> toMerge;

  SmallPtrSet<Operation *, 8> scheduledForMerge;

  for (Operation *op1 : op->getUsers()) {
    if (classOp) {
      // Skip ClassOps that use this result as their leader pointer.
      if (auto op1class = llvm::dyn_cast<equivalence::ClassOp>(op1)) {
        assert(op1class.getLeader() == classOp.getResult());
        continue;
      }
    }
    Operation *op2 = uniqueParents.lookup(op1);

    if (op2) {
      assert(op2->getBlock());
      if (scheduledForMerge.insert(op1).second)
        toMerge.emplace_back(op1, op2);
    } else {
      uniqueParents[op1] = op1;
    }
  }
  // Now perform all merges after we're done with the hash map
  for (auto [other, keep] : toMerge) {
    if (keep == other)
      continue;

    [[maybe_unused]] bool erased = rewriter.erase(keep).succeeded();
    assert(erased);
    [[maybe_unused]] bool inserted = rewriter.insert(keep).succeeded();
    assert(inserted);

    mergeResults(rewriter, other, keep);
    // Don't just erase the op, instead, replace. Listeners such as the
    // OriginalOpTracker used in herbie-mlir should be able to tell what
    // `other` is replaced with:
    rewriter.replaceOp(other, keep);
  }
}

void ClassOpUnionFind::mergeResults(HashConsPatternRewriter &rewriter,
                                    Operation *other, Operation *keep) {
  for (auto [resOther, resKeep] :
       llvm::zip_equal(other->getResults(), keep->getResults())) {
    // Collect eclass pairs before replacement
    equivalence::ClassOp classKeep = getClassOpIfExists(resKeep);
    equivalence::ClassOp classOther = getClassOpIfExists(resOther);

    if (classKeep && classOther) {
      // Case 1: both values have a class — replace other's results with
      // keep's results, then union the two classes.
      rewriter.replaceAllUsesWith(resOther, resKeep);
      // The replaceAllUsesWith above rewrote resOther -> resKeep inside
      // classOther's input list.  That means resKeep is now an input of
      // *both* classKeep and classOther, breaking the single-class-
      // membership invariant.  Remove the stale occurrence from
      // classOther so that resKeep only belongs to classKeep.
      if (classKeep != classOther) {
        swappedErase(classOther, resKeep);
        classUnion(rewriter, classKeep.getResult(), classOther.getResult());
      } else {
        // resOther and resKeep were both inputs of the same class, and resOther
        // was replaced by resKeep. Therefore, there is only one duplicate of
        // resKeep.
        swappedErase(classKeep, resKeep);
      }
    } else if (classKeep) {
      // Case 2: only keep has a class — redirect other's results to the
      // class representative rather than the raw result.
      rewriter.replaceAllUsesWith(resOther, classKeep.getResult());
    } else if (classOther) {
      // Case 3: only other has a class — redirect keep's non-ClassOp users
      // through classOther first, then retarget classOther from resOther to
      // resKeep.
      rewriter.replaceUsesWithIf(
          resKeep, classOther.getResult(),
          [&](OpOperand &operand) { return operand.getOwner() != classOther; });
      rewriter.replaceAllUsesWith(resOther, resKeep);
    } else {
      // Case 4: neither has a class — simple replacement.
      rewriter.replaceAllUsesWith(resOther, resKeep);
    }
  }

  worklist.push_back(keep);
}
