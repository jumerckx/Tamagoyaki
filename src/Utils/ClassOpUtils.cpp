//===- ClassOpUtils.cpp - Stateless helpers for equivalence::ClassOp -*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/ClassOpUtils.h"
#include "EquivalenceDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/TypeRange.h"
#include "llvm/ADT/STLExtras.h"
#include <cassert>
#include <llvm/ADT/SmallVector.h>
#include <mlir/IR/PatternMatch.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>

using namespace mlir;
using namespace mlir::ematch;

ClassValIterator::ClassValIterator(Value val) {
  enter(val);
  skipExhausted();
}

void ClassValIterator::enter(Value val) {
  if (auto refineOp = val.getDefiningOp<equivalence::RefineOp>()) {
    // Visit the target before the source: the source is pushed first so the
    // target is popped first.
    if (visited.insert(refineOp).second) {
      pending.push_back(refineOp.getSource());
      pending.push_back(refineOp.getTarget());
    }
  } else if (auto classOp = val.getDefiningOp<equivalence::ClassOp>()) {
    if (visited.insert(classOp).second) {
      this->classOp = classOp;
      index = 0;
    }
  } else {
    single = val;
  }
}

Value ClassValIterator::operator*() const {
  if (single)
    return single;
  // Op wrappers have no const accessors.
  return equivalence::ClassOp(classOp).getInputs()[index];
}

ClassValIterator &ClassValIterator::operator++() {
  if (single)
    single = nullptr;
  else
    ++index;
  skipExhausted();
  return *this;
}

void ClassValIterator::skipExhausted() {
  while (true) {
    if (single)
      return;
    if (classOp) {
      if (index < classOp.getInputs().size())
        return;
      Value leader = classOp.getLeader();
      auto next = leader ? leader.getDefiningOp<equivalence::ClassOp>()
                         : equivalence::ClassOp();
      classOp =
          next && visited.insert(next).second ? next : equivalence::ClassOp();
      index = 0;
      continue;
    }
    if (pending.empty())
      return;
    enter(pending.pop_back_val());
  }
}

ClassValRange mlir::ematch::getClassVals(mlir::PatternRewriter &rewriter,
                                         mlir::Value val) {
  return ClassValRange(ClassValIterator(val), ClassValIterator());
}

mlir::Value
mlir::ematch::getClassRepresentative(mlir::PatternRewriter &rewriter,
                                     mlir::Value val) {
  return *ClassValIterator(val);
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

equivalence::ClassOp mlir::ematch::getRootLeader(equivalence::ClassOp classOp) {
  while (Value leader = classOp.getLeader())
    classOp = cast<equivalence::ClassOp>(leader.getDefiningOp());
  return classOp;
}

bool mlir::ematch::areEquivalent(Value lhs, Value rhs) {
  if (lhs == rhs)
    return true;
  auto lhsClass = lhs.getDefiningOp<equivalence::ClassOp>();
  auto rhsClass = rhs.getDefiningOp<equivalence::ClassOp>();
  if (!lhsClass || !rhsClass)
    return false;
  return getRootLeader(lhsClass) == getRootLeader(rhsClass);
}

bool mlir::ematch::refinesTo(Value from, Value to) {
  auto toClass = to.getDefiningOp<equivalence::ClassOp>();
  equivalence::ClassOp toRoot = toClass ? getRootLeader(toClass) : nullptr;
  SmallVector<Value> worklist{from};
  SmallPtrSet<Operation *, 8> visited;
  while (!worklist.empty()) {
    Value val = worklist.pop_back_val();
    if (val == to)
      return true;
    Operation *def = val.getDefiningOp();
    if (!def || !visited.insert(def).second)
      continue;
    if (auto refineOp = dyn_cast<equivalence::RefineOp>(def)) {
      worklist.push_back(refineOp.getSource());
      worklist.push_back(refineOp.getTarget());
    } else if (auto classOp = dyn_cast<equivalence::ClassOp>(def)) {
      if (toRoot && getRootLeader(classOp) == toRoot)
        return true;
    }
  }
  return false;
}

Value mlir::ematch::getRefinementTop(Value val) {
  bool advanced = true;
  while (advanced) {
    advanced = false;
    for (OpOperand &use : val.getUses()) {
      auto refineOp = dyn_cast<equivalence::RefineOp>(use.getOwner());
      if (refineOp && &use == &refineOp.getSourceMutable()) {
        val = refineOp.getResult();
        advanced = true;
        break;
      }
    }
  }
  return val;
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

equivalence::ClassOp mlir::ematch::getClassOpIfExists(Value val) {
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
  auto classOp = equivalence::ClassOp::create(
      builder, val.getLoc(), TypeRange{val.getType()}, ValueRange{val},
      /*leader=*/Value{}, /*min_cost_index=*/nullptr);
  rewriter.replaceUsesWithIf(
      val, classOp.getResult(),
      [&classOp](OpOperand &operand) { return operand.getOwner() != classOp; });
  return classOp;
}

void mlir::ematch::swappedErase(equivalence::ClassOp classOp, Value target) {
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
