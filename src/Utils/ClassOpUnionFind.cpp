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
      builder, val.getLoc(), TypeRange{val.getType()}, ValueRange{val});
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

  equivalence::ClassOp leader = classA;
  equivalence::ClassOp other = classB;

  rewriter.replaceAllUsesWith(other.getResult(), leader.getResult());

  // Find operands in `other` that aren't already in `leader`.
  // Operands need to be deduplicated because it can happen that the same
  // operand was used by different parent eclasses after their children were
  // merged
  SmallPtrSet<Value, 8> existing(leader->operand_begin(),
                                 leader->operand_end());
  SmallVector<Value, 8> newOperands;
  for (Value operand : other->getOperands()) {
    if (existing.insert(operand).second)
      newOperands.push_back(operand);
  }
  // add newOperands to the end of the operand list
  leader->setOperands(leader->getNumOperands(), 0, newOperands);

  // Defer erasure: the worklist may still reference `other`, so we can't
  // erase it immediately. Collect it for cleanup after rebuild completes.
  // Drop all operands so the dead op doesn't keep values alive.
  other->setOperands(ValueRange{});
  pendingErase.push_back(other);

  assert(leader->getNumOperands() > 0 &&
         "Leader ClassOp must have at least one operand");
  worklist.push_back(leader->getOperand(0));
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

/// Given a representative value (an operand of some ClassOp), find the
/// ClassOp that currently contains it by scanning its users.
static equivalence::ClassOp findContainingClassOp(Value representative) {
  for (Operation *user : representative.getUsers()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(user))
      return classOp;
  }
  llvm_unreachable("Representative value must be an operand of a ClassOp");
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

  while (!worklist.empty()) {
    // Create an ordered set of unique leaders from the worklist.
    // Each worklist entry is a representative value; find its containing
    // ClassOp to get the current leader.
    llvm::SetVector<equivalence::ClassOp> todo;
    for (Value representative : worklist) {
      todo.insert(findContainingClassOp(representative));
    }
    worklist.clear();

    // Repair each unique leader
    for (equivalence::ClassOp c : todo) {
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
  for (equivalence::ClassOp dead : pendingErase) {
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
