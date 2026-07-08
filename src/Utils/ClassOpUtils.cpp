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
