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
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Debug.h"
#include <cassert>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

SmallVector<Value> mlir::ematch::getClassVals(PatternRewriter &rewriter,
                                              Value val) {
  Operation *defOp = val.getDefiningOp();
  if (defOp == nullptr) {
    return {val};
  } else if (auto classOp = dyn_cast<equivalence::ClassOp>(defOp)) {
    return llvm::to_vector(classOp->getOperands());
  }
  return {val};
}

Value mlir::ematch::getClassRepresentative(PatternRewriter &rewriter,
                                           Value val) {
  return getClassVals(rewriter, val)[0];
}

equivalence::ClassOp
mlir::ematch::getCanonicalLeader(equivalence::ClassOp classOp) {
  Value leaderVal = classOp.getLeader();
  if (!leaderVal)
    return classOp; // I am the leader.

  auto parentOp = cast<equivalence::ClassOp>(leaderVal.getDefiningOp());
  if (!parentOp.getLeader())
    return parentOp; // My parent is the leader.

  // Path compression: find root leader and update my pointer.
  equivalence::ClassOp root = getCanonicalLeader(parentOp);
  classOp.getLeaderMutable().assign(root.getResult());
  return root;
}

Value mlir::ematch::getClassResult(PatternRewriter &rewriter, Value val) {
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

SmallVector<Value> mlir::ematch::getClassResults(PatternRewriter &rewriter,
                                                 ValueRange vals) {
  SmallVector<Value> results;
  results.reserve(vals.size());

  for (Value val : vals) {
    results.push_back(getClassResult(rewriter, val));
  }

  return results;
}

equivalence::ClassOp mlir::ematch::getClassOp(PatternRewriter &rewriter,
                                              Value val) {

  Operation *defOp = val.getDefiningOp();
  if (defOp != nullptr && dyn_cast<equivalence::ClassOp>(*defOp)) {
    return cast<equivalence::ClassOp>(*defOp);
  }
  if (auto classOp = val.hasOneUse()
                         ? dyn_cast<equivalence::ClassOp>(*val.user_begin())
                         : nullptr) {
    return classOp;
  }

  // If the value is not part of an eclass yet, create one
  OpBuilder builder(val.getContext());
  builder.setInsertionPointAfterValue(val);
  auto classOp = equivalence::ClassOp::create(
      builder, val.getLoc(), TypeRange{val.getType()}, ValueRange{val},
      /*leader=*/Value{}, /*min_cost_index=*/nullptr);
  rewriter.replaceUsesWithIf(
      val, classOp.getResult(),
      [&classOp](OpOperand &operand) { return operand.getOwner() != classOp; });
  return classOp;
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, Value a, Value b) {
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

  worklist.push_back(leader);
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, Operation *op,
                                  ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    classUnion(rewriter, result, val);
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, ValueRange a,
                                  ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    classUnion(rewriter, va, vb);
}

void ClassOpUnionFind::queueClassUnion(Value a, Value b) {
  pendingClassUnions.emplace_back(a, b);
}

void ClassOpUnionFind::queueClassUnion(Operation *op, ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    queueClassUnion(result, val);
}

void ClassOpUnionFind::queueClassUnion(ValueRange a, ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    queueClassUnion(va, vb);
}

void ClassOpUnionFind::processPendingClassUnions(PatternRewriter &rewriter) {
  for (auto [a, b] : pendingClassUnions) {
    LLVM_DEBUG({
      llvm::dbgs() << "Unioning:\n\t";
      a.dump();
      llvm::dbgs() << "\t";
      b.dump();
    });
    classUnion(rewriter, a, b);
  }
  pendingClassUnions.clear();
}

bool ClassOpUnionFind::rebuild(HashConsPatternRewriter &rewriter) {
  TAMAGOYAKI_SCOPED_TIMER("rebuild");
  LLVM_DEBUG({
    llvm::dbgs() << "Starting rebuild. Worklist contains " << worklist.size()
                 << " classes\n";
    llvm::dbgs() << "Worklist: ";
    for (auto rep : worklist) {
      llvm::dbgs() << "\t";
      rep.dump();
    }
  });

  if (worklist.empty())
    return false;

  // Materialize lazy unions: collect all non-leader ClassOps reachable from
  // the worklist, redirect their users to the canonical leader, merge their
  // inputs into the leader, and schedule them for erasure.
  {
    // Collect the set of canonical leaders so we can walk their chains.
    SmallVector<equivalence::ClassOp> leaders;
    llvm::SmallPtrSet<Operation *, 8> seenLeaders;
    for (equivalence::ClassOp c : worklist) {
      equivalence::ClassOp root = getCanonicalLeader(c);
      if (seenLeaders.insert(root.getOperation()).second)
        leaders.push_back(root);
    }

    // For every leader, find all ClassOps that point to it (directly or
    // through a chain — we already path-compressed above so one hop suffices
    // for anything reachable from the worklist).
    // Walk the users of each leader result to find children.
    for (equivalence::ClassOp leader : leaders) {
      // Collect non-leader ClassOps whose canonical leader is `leader`.
      SmallVector<equivalence::ClassOp> children;
      for (OpOperand &use : leader.getResult().getUses()) {
        auto child = dyn_cast<equivalence::ClassOp>(use.getOwner());
        if (child && child != leader && child.getLeader() == leader.getResult())
          children.push_back(child);
      }

      for (equivalence::ClassOp child : children) {
        // Reroute all users of `child` to `leader`.
        rewriter.replaceAllUsesWith(child.getResult(), leader.getResult());

        // Merge child's inputs into leader, deduplicating.
        SmallPtrSet<Value, 8> existing(leader.getInputs().begin(),
                                       leader.getInputs().end());
        SmallVector<Value, 8> newOperands;
        for (Value operand : child.getInputs()) {
          if (existing.insert(operand).second)
            newOperands.push_back(operand);
        }
        auto mutableInputs = leader.getInputsMutable();
        mutableInputs.append(newOperands);

        // Clear the child and schedule for erasure.
        child.getInputsMutable().clear();
        child.getLeaderMutable().clear();
        pendingErase.push_back(child);
      }
    }
  }

  while (!worklist.empty()) {
    llvm::SetVector<equivalence::ClassOp> todo;
    for (equivalence::ClassOp c : worklist) {
      // Skip ClassOps that were merged away: their inputs were cleared.
      if (c.getInputs().size() > 0)
        todo.insert(getCanonicalLeader(c));
    }
    worklist.clear();

    for (equivalence::ClassOp c : todo) {
      if (c.getInputs().empty())
        continue;
      repair(rewriter, c);
    }
  }

  // Now that the worklist is fully drained, erase all dead eclasses that
  // were deferred during classUnion.
  LLVM_DEBUG({
    llvm::dbgs() << "Pending erases:\n";
    for (equivalence::ClassOp dead : pendingErase) {
      llvm::dbgs() << "\t";
      dead.dump();
    }
  });
  SmallPtrSet<Operation *, 8> erased;
  for (equivalence::ClassOp dead : pendingErase) {
    if (erased.insert(dead.getOperation()).second)
      rewriter.eraseOp(dead);
  }
  pendingErase.clear();

  return true;
}

void ClassOpUnionFind::repair(HashConsPatternRewriter &rewriter,
                              equivalence::ClassOp classOp) {
  if (classOp->getBlock() == nullptr) {
    return;
  }

  llvm::DenseMap<Operation *, Operation *, SimpleOperationInfo> uniqueParents;
  // Collect pairs of duplicate operations to merge AFTER the loop
  SmallVector<std::pair<Operation *, Operation *>> toMerge;

  SmallPtrSet<Operation *, 8> scheduledForMerge;
  for (Operation *op1 : classOp.getResult().getUsers()) {
    Operation *op2 = uniqueParents.lookup(op1);

    if (op2) {
      if (scheduledForMerge.insert(op1).second)
        toMerge.emplace_back(op1, op2);
    } else {
      uniqueParents[op1] = op1;
    }
  }
  // Now perform all merges after we're done with the hash map
  for (auto [op1, op2] : toMerge) {
    if (op1 == op2)
      continue;
    // Collect eclass pairs before replacement
    SmallVector<std::pair<equivalence::ClassOp, equivalence::ClassOp>>
        eclassPairs;
    for (auto [res1, res2] : llvm::zip(op1->getResults(), op2->getResults())) {
      equivalence::ClassOp eclass1 = getClassOp(rewriter, res1);
      equivalence::ClassOp eclass2 = getClassOp(rewriter, res2);
      eclassPairs.emplace_back(eclass1, eclass2);
    }

    assert(rewriter.erase(op1).succeeded());
    rewriter.replaceOp(op1, op2->getResults());
    assert(rewriter.insert(op2).succeeded());

    for (auto [eclass1, eclass2] : eclassPairs) {
      if (eclass1 == eclass2) {
        SmallPtrSet<Value, 8> seen;
        SmallVector<Value> uniqueOperands;
        for (Value operand : eclass1->getOperands()) {
          if (seen.insert(operand).second)
            uniqueOperands.push_back(operand);
        }
        eclass1->setOperands(uniqueOperands);
      } else {
        classUnion(rewriter, eclass1.getResult(), eclass2.getResult());
      }
    }
  }
}
