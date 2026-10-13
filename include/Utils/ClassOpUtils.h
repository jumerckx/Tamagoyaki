//===- ClassOpUtils.h - Stateless helpers for equivalence::ClassOp --*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Free-function helpers for reading, creating, and navigating
// `equivalence.class` operations and their leader chain. These carry no e-graph
// state; the congruence engine and PDL rewrite functions both build on them.
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_UTILS_CLASSOPUTILS_H
#define TAMAGOYAKI_SRC_UTILS_CLASSOPUTILS_H

#include "EquivalenceDialect.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/iterator.h"
#include "llvm/ADT/iterator_range.h"

namespace mlir::ematch {

/// Lazy forward iterator over the values of an e-class. It first visits the
/// inputs of the class itself and then follows the leader chain outward,
/// visiting the inputs of each enclosing class in turn. An inner class's
/// leader always lives in an enclosing graph scope, so every visited value
/// dominates (is visible from) the starting class. A value that is not an
/// equivalence.class result is visited on its own.
///
/// An equivalence.refine result is expanded into the values of its target
/// followed by those of its source, recursively, so the whole chain of
/// refinements is visited. Every class and refinement is visited at most once,
/// which also makes the traversal terminate on cyclic refinements.
class ClassValIterator
    : public llvm::iterator_facade_base<
          ClassValIterator, std::forward_iterator_tag, mlir::Value,
          std::ptrdiff_t, mlir::Value *, mlir::Value> {
public:
  /// The end iterator.
  ClassValIterator() = default;
  /// Iterate over the class of `val` (or just `val` if it is not a class).
  explicit ClassValIterator(mlir::Value val);

  mlir::Value operator*() const;
  ClassValIterator &operator++();
  bool operator==(const ClassValIterator &other) const {
    return classOp == other.classOp && index == other.index &&
           single == other.single && pending.size() == other.pending.size();
  }

private:
  /// Start visiting `val`: a class, a refinement (whose operands are queued),
  /// or a single value.
  void enter(mlir::Value val);

  /// Move to the next value to visit: follow the leader chain while the
  /// current class has no input left at `index`, then continue with the
  /// pending values of enclosing refinements.
  void skipExhausted();

  equivalence::ClassOp classOp;
  unsigned index = 0;
  /// Set when iterating over a value that is not part of a class.
  mlir::Value single;
  /// Refinement operands still to be visited (LIFO).
  SmallVector<mlir::Value, 2> pending;
  /// Classes and refinements that were already entered.
  SmallPtrSet<mlir::Operation *, 4> visited;
};

using ClassValRange = llvm::iterator_range<ClassValIterator>;

/// Get all values in the e-class of `val`, including the values of the
/// classes reachable through the leader chain and the chain of refinements.
/// The range is lazy; use
/// `llvm::to_vector` to materialize it.
ClassValRange getClassVals(mlir::PatternRewriter &rewriter, mlir::Value val);

/// Return true if the refinement tree of `from` (see ClassValIterator)
/// reaches `to`, or a class equivalent to `to`, i.e. `from` is already known
/// to be refinable into `to`.
bool refinesTo(mlir::Value from, mlir::Value to);

/// Return the last refinement in the chain built on top of `val` (the value
/// that `val`'s users refer to), or `val` itself if it was never refined.
mlir::Value getRefinementTop(mlir::Value val);

/// Helper function to get the first value from a ClassOp
mlir::Value getClassRepresentative(mlir::PatternRewriter &rewriter,
                                   mlir::Value val);

/// Follow the leader chain of a ClassOp to find the canonical leader,
/// performing path compression along the way.
equivalence::ClassOp getCanonicalLeader(equivalence::ClassOp classOp);

/// Return the root of the leader chain of `classOp` without path compression,
/// so it is safe to call while the IR must not be mutated (e.g. matching).
equivalence::ClassOp getRootLeader(equivalence::ClassOp classOp);

/// Return true if `lhs` and `rhs` are in the same e-class: either the same
/// value, or equivalence.class results with the same root leader.
bool areEquivalent(mlir::Value lhs, mlir::Value rhs);

/// Helper function to get the result of a ClassOp
mlir::Value getClassResult(mlir::PatternRewriter &rewriter, mlir::Value val);

SmallVector<Value> getClassResults(mlir::PatternRewriter &rewriter,
                                   mlir::ValueRange vals);

/// Return the ClassOp associated with `val` (as its defining op or as a user),
/// or null if `val` is not part of any e-class yet.
equivalence::ClassOp getClassOpIfExists(mlir::Value val);

/// Helper function to get or create a ClassOp for a value
equivalence::ClassOp getClassOp(mlir::PatternRewriter &rewriter,
                                mlir::Value val);

/// Erase the first occurrence of `target` from `classOp`'s input list. Swaps
/// with the last element first so the erase is O(1).
void swappedErase(equivalence::ClassOp classOp, mlir::Value target);

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_UTILS_CLASSOPUTILS_H
