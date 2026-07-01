//===- CongruenceEngine.cpp - Scope-aware e-graph congruence engine -*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/CongruenceEngine.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"
#include "Utils/ClassOpUtils.h"
#include "Utils/GraphScope.h"
#include "Utils/HashConsPatternRewriter.h"
#include "Utils/ScopeRepIndex.h"
#include "mlir/IR/PatternMatch.h"
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
// Union operations
//===----------------------------------------------------------------------===//

void CongruenceEngine::classUnion(mlir::PatternRewriter &rewriter,
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

  // The leader operand is an SSA edge `other -> leader`, so `leader` must
  // enclose `other`: on a cross-scope union the outer (smaller-depth) class
  // becomes the parent. Within one scope the direction is free, so we fall back
  // to union-by-rank.
  unsigned depthLeader = depthOf(leader);
  unsigned depthOther = depthOf(other);

  if (depthLeader != depthOther) {
    if (depthLeader > depthOther)
      std::swap(leader, other);
  } else {
    if (index.unionRank.lookup(leader.getOperation()) <
        index.unionRank.lookup(other.getOperation()))
      std::swap(leader, other);
  }

  assert(encloses(scopeOf(leader), scopeOf(other)) &&
         "incomparable scopes must not occur");

  // Seed `other`'s row before merging so `mergeScopeRows` has a `{other}`-or-
  // bigger row to fold in (it seeds `leader`'s `{leader}` row itself).
  index.rowFor(other);

  // Inner -> outer (or same-scope): SSA-valid, never inward.
  other.getLeaderMutable().assign(leader.getResult());

  if (depthLeader == depthOther) {
    unsigned &rankLeader = index.unionRank[leader.getOperation()];
    if (rankLeader == index.unionRank.lookup(other.getOperation()))
      ++rankLeader;
  }

  index.mergeScopeRows(leader, other);
  dirtyRoots.insert(leader);
}

void CongruenceEngine::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::Operation *op, mlir::ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    classUnion(rewriter, result, val);
}

void CongruenceEngine::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::ValueRange a, mlir::ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    classUnion(rewriter, va, vb);
}

void CongruenceEngine::queueClassUnion(mlir::Value a, mlir::Value b) {
  pendingClassUnions.emplace_back(a, b);
}

void CongruenceEngine::queueClassUnion(mlir::Operation *op,
                                       mlir::ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    queueClassUnion(result, val);
}

void CongruenceEngine::queueClassUnion(mlir::ValueRange a, mlir::ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    queueClassUnion(va, vb);
}

void CongruenceEngine::processPendingClassUnions(PatternRewriter &rewriter) {
  for (auto [a, b] : pendingClassUnions) {
    classUnion(rewriter, a, b);
  }
  pendingClassUnions.clear();
}

void CongruenceEngine::repairDuplicate(Operation *dup) {
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
// Rebuild helpers that mutate IR / drive the rewriter
//===----------------------------------------------------------------------===//

void CongruenceEngine::fuseSameScope(HashConsPatternRewriter &rewriter,
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
  index.forgetClass(dup);
}

void CongruenceEngine::retargetUsersToDeepest(
    equivalence::ClassOp rep, SmallVectorImpl<equivalence::ClassOp> &row) {
  SmallVector<OpOperand *> toFix;
  for (OpOperand &u : rep.getResult().getUses()) {
    Operation *user = u.getOwner();
    // Skip leader links (a child class pointing at rep); `reorientComponent`
    // owns those.
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

bool CongruenceEngine::rebuild(HashConsPatternRewriter &rewriter) {
  TAMAGOYAKI_SCOPED_TIMER("rebuild");
  LLVM_DEBUG({
    llvm::dbgs() << "Starting rebuild. Worklist=" << worklist.size()
                 << " sameScopeDups=" << index.sameScopeDups.size()
                 << " dirtyRoots=" << dirtyRoots.size() << "\n";
  });

  if (index.sameScopeDups.empty() && dirtyRoots.empty() && worklist.empty())
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

  LLVM_DEBUG(index.verify());

  while (!index.sameScopeDups.empty() || !dirtyRoots.empty() ||
         !worklist.empty()) {
    // Collapse same-scope duplicate classes.
    {
      SmallVector<std::pair<equivalence::ClassOp, equivalence::ClassOp>> batch;
      std::swap(batch, index.sameScopeDups);
      for (auto [dup, survivor] : batch) {
        if (isDead(dup.getOperation()) || isDead(survivor.getOperation()))
          continue;
        fuseSameScope(rewriter, dup, survivor);
        equivalence::ClassOp root = getCanonicalLeader(survivor);
        dirtyRoots.insert(root);
        worklist.push_back(survivor.getOperation());
      }
    }

    // Collect the dirty components, re-canonicalized and deduped.
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

    // Per component (independent across components): reorient leaders outward,
    // then push users down to the deepest visible rep.
    for (equivalence::ClassOp root : roots) {
      auto it = index.scopeReps.find(root);
      if (it == index.scopeReps.end())
        continue;
      index.reorientComponent(it->second);

      // Snapshot the rep list: retargetUsersToDeepest pushes to the worklist
      // but does not mutate the row, yet repairs later might.
      SmallVector<equivalence::ClassOp> reps(it->second.begin(),
                                             it->second.end());
      for (equivalence::ClassOp rep : reps) {
        if (isDead(rep.getOperation()))
          continue;
        retargetUsersToDeepest(rep, it->second);
      }
    }

    // Congruence repair.
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
          // Non-ClassOp entries come from `mergeResults` / user retargeting:
          // their users may have become identical and need deduplication.
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

  // Now that everything has reached a fixpoint, erase the dead eclasses
  // detached by `fuseSameScope`.
  SmallPtrSet<Operation *, 8> erased;
  for (equivalence::ClassOp dead : pendingErase) {
    if (erased.insert(dead.getOperation()).second) {
      index.forgetClass(dead);
      rewriter.eraseOp(dead);
    }
  }
  pendingErase.clear();

  LLVM_DEBUG(index.verify());
  return true;
}

//===----------------------------------------------------------------------===//
// Hash-consing and congruence repair
//===----------------------------------------------------------------------===//

void CongruenceEngine::hashconsGraph(HashConsPatternRewriter &rewriter,
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

void CongruenceEngine::repair(HashConsPatternRewriter &rewriter,
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

void CongruenceEngine::mergeResults(HashConsPatternRewriter &rewriter,
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
