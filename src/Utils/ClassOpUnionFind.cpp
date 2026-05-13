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
#include <cassert>
#include <cstddef>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

SmallVector<mlir::Value> mlir::ematch::getClassVals(
    mlir::PatternRewriter &rewriter, mlir::Value val) {
  Operation *defOp = val.getDefiningOp();
  if (defOp == nullptr) {
    return {val};
  } else if (auto classOp = dyn_cast<equivalence::ClassOp>(defOp)) {
    return llvm::to_vector(classOp->getOperands());
  }
  return {val};
}

mlir::Value mlir::ematch::getClassRepresentative(
    mlir::PatternRewriter &rewriter, mlir::Value val) {
  return getClassVals(rewriter, val)[0];
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

mlir::Value mlir::ematch::getClassResult(
    mlir::PatternRewriter &rewriter, mlir::Value val) {
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

SmallVector<mlir::Value> mlir::ematch::getClassResults(
    mlir::PatternRewriter &rewriter, mlir::ValueRange vals) {
  SmallVector<Value> results;
  results.reserve(vals.size());

  for (Value val : vals) {
    results.push_back(getClassResult(rewriter, val));
  }

  return results;
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

equivalence::ClassOp mlir::ematch::getClassOp(
    mlir::PatternRewriter &rewriter, mlir::Value val) {

  if (auto classOp = getClassOpIfExists(val)) {
    return classOp;
  }
  // If the value is not part of an eclass yet, create one
  OpBuilder builder(val.getContext());
  assert(!val.getDefiningOp() ||
         !dyn_cast<equivalence::ClassOp>(val.getDefiningOp()));
  builder.setInsertionPointAfterValue(val);
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

  // Lazy union: just point `other` at `leader` via the leader operand.
  other.getLeaderMutable().assign(leader.getResult());

  // We push `other` such that at the start of `rebuild`,
  worklist.push_back(other);
}

void ClassOpUnionFind::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::Operation *op,
                                  mlir::ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    classUnion(rewriter, result, val);
}

void ClassOpUnionFind::classUnion(mlir::PatternRewriter &rewriter,
                                  mlir::ValueRange a,
                                  mlir::ValueRange b) {
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

void ClassOpUnionFind::queueClassUnion(mlir::ValueRange a,
                                       mlir::ValueRange b) {
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

bool ClassOpUnionFind::rebuild(HashConsPatternRewriter &rewriter) {
  TAMAGOYAKI_SCOPED_TIMER("rebuild");
  LLVM_DEBUG({
    llvm::dbgs() << "Starting rebuild. Worklist contains " << worklist.size()
                 << " entries\n";
  });

  if (worklist.empty())
    return false;

  // Track ops that get erased during the loop below. Operations queued in
  // `todo` (or `worklist` re-entry) may be freed by `repair`'s
  // `replaceOp`, so we must not dereference their pointers afterwards.
  // Just checking `op->getBlock()` is unsafe because the Operation memory
  // itself may have been freed.
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

  while (!worklist.empty()) {
    llvm::SetVector<Operation *> todo;
    for (Operation *op : worklist) {
      if (!op || erasedOps.contains(op) || !op->getBlock()) {
        continue; // op has already been removed/erased
      }

      auto c = llvm::dyn_cast<equivalence::ClassOp>(op);
      if (!c) {
        // Non-ClassOp entries come from `mergeResults`: their users may
        // have become identical and need to be deduplicated.
        todo.insert(op);
        continue;
      }

      auto leader = getCanonicalLeader(c);
      if (c != leader) { // c needs to be canonicalized
        // add operands to leader (deduplicated)
        SmallPtrSet<Value, 8> existing(leader.getInputs().begin(),
                                       leader.getInputs().end());
        SmallVector<Value, 8> newOperands;
        for (Value operand : c.getInputs()) {
          assert(
              !operand.getDefiningOp() ||
              !llvm::dyn_cast<equivalence::ClassOp>(operand.getDefiningOp()));
          if (existing.insert(operand).second)
            newOperands.push_back(operand);
        }
        auto mutableInputs = leader.getInputsMutable();
        mutableInputs.append(newOperands);

        // update all users of c
        rewriter.replaceAllUsesWith(c.getResult(), leader.getResult());

        // remove c from IR and queue for erasure
        c.getInputsMutable().clear();
        c.getLeaderMutable().clear();
        c->remove();
        pendingErase.push_back(c);
      }
      todo.insert(leader.getOperation());
    }
    worklist.clear();

    for (Operation *op : todo) {
      if (!op || erasedOps.contains(op) || !op->getBlock())
        continue;
      if (auto c = llvm::dyn_cast<equivalence::ClassOp>(op)) {
        if (c.getInputs().empty())
          continue;
      }
      repair(rewriter, op);
    }
  }

  // Now that the worklist is fully drained, erase all dead eclasses that
  // were deferred during classUnion.
  SmallPtrSet<Operation *, 8> erased;
  for (equivalence::ClassOp dead : pendingErase) {
    if (erased.insert(dead.getOperation()).second)
      rewriter.eraseOp(dead);
  }
  pendingErase.clear();

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
    bool erased = rewriter.erase(keep).succeeded();
    assert(erased);
    bool inserted = rewriter.insert(keep).succeeded();
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

    bool erased = rewriter.erase(keep).succeeded();
    assert(erased);
    bool inserted = rewriter.insert(keep).succeeded();
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
        auto otherInputs = classOther.getInputsMutable();
        SmallVector<Value> filtered;
        for (Value v : classOther.getInputs()) {
          if (v != resKeep)
            filtered.push_back(v);
        }
        if (filtered.size() != otherInputs.size())
          otherInputs.assign(filtered);
        classUnion(rewriter, classKeep.getResult(), classOther.getResult());
      } else {
        SmallPtrSet<Value, 8> seen;
        SmallVector<Value> uniqueOperands;
        for (Value operand : classKeep.getInputs()) {
          if (seen.insert(operand).second)
            uniqueOperands.push_back(operand);
        }
        classKeep.getInputsMutable().assign(uniqueOperands);
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
