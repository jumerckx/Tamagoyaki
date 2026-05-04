//===- ClassOpUnionFind.h - Union-find data structure for ClassOp -----*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef EQUIVALENCE_SRC_UTILS_CLASSOPUNIONFIND_H
#define EQUIVALENCE_SRC_UTILS_CLASSOPUNIONFIND_H

#include "EquivalenceDialect.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Support/LLVM.h"

namespace mlir::ematch {

/// Helper function to get all values from a ClassOp
SmallVector<mlir::Value> getClassVals(mlir::PatternRewriter &rewriter,
                                      mlir::Value val);

/// Helper function to get the first value from a ClassOp
mlir::Value getClassRepresentative(mlir::PatternRewriter &rewriter,
                                   mlir::Value val);

/// Follow the leader chain of a ClassOp to find the canonical leader,
/// performing path compression along the way.
equivalence::ClassOp getCanonicalLeader(equivalence::ClassOp classOp);

/// Helper function to get the result of a ClassOp
mlir::Value getClassResult(mlir::PatternRewriter &rewriter, mlir::Value val);

SmallVector<Value> getClassResults(mlir::PatternRewriter &rewriter,
                                   mlir::ValueRange vals);

/// Helper function to get or create a ClassOp for a value
equivalence::ClassOp getClassOp(mlir::PatternRewriter &rewriter,
                                mlir::Value val);

/// Union-find data structure for managing equivalence classes of ClassOp
class ClassOpUnionFind {
public:
  /// Union two individual values
  void classUnion(mlir::PatternRewriter &rewriter, mlir::Value a,
                  mlir::Value b);

  /// Union an operation's results with corresponding values
  void classUnion(mlir::PatternRewriter &rewriter, mlir::Operation *op,
                  mlir::ValueRange vals);

  /// Union two value ranges pairwise
  void classUnion(mlir::PatternRewriter &rewriter, mlir::ValueRange a,
                  mlir::ValueRange b);

  /// Queue a union of two individual values for later processing
  void queueClassUnion(mlir::Value a, mlir::Value b);

  /// Queue unions of an operation's results with corresponding values
  void queueClassUnion(mlir::Operation *op, mlir::ValueRange vals);

  /// Queue pairwise unions of two value ranges
  void queueClassUnion(mlir::ValueRange a, mlir::ValueRange b);

  /// Process all pending queued class unions
  void processPendingClassUnions(mlir::PatternRewriter &rewriter);

  /// Repair the parents of each ClassOp in the worklist.
  /// This also clears the worklist.
  /// Returns false when the worklist was empty, otherwise true.
  bool rebuild(HashConsPatternRewriter &rewriter);

  /// Create a hash-cons scope for the given graph's region and insert every
  /// non-ClassOp operation into it. Duplicate operations encountered during
  /// insertion are collected and merged via `mergeResults`, mirroring the
  /// pair-collect-then-process pattern used by `repair`.
  void hashconsGraph(HashConsPatternRewriter &rewriter,
                     equivalence::GraphOp graph);

  /// Repair e-graph by potentially deduplicating the parents (=users) of
  /// the given operation.  When `op` is a ClassOp this dedups users of the
  /// class result; for any other operation it dedups users of `op`'s
  /// results.  A `keep` operation pushed to the worklist by `mergeResults`
  /// is repaired this way so that newly redirected users that became
  /// identical can be collapsed.
  void repair(HashConsPatternRewriter &rewriter, mlir::Operation *op);

  /// Merge the results of two duplicate parent operations
  /// (`other` -> `keep`), reconciling their owning ClassOps if any.
  /// Used by `repair` when collapsing duplicate users of a ClassOp.
  /// After redirecting `other`'s users onto `keep`, `keep` is pushed onto
  /// the worklist so that any users that became identical are repaired in
  /// the next rebuild iteration.
  void mergeResults(HashConsPatternRewriter &rewriter, mlir::Operation *other,
                    mlir::Operation *keep);

  /// Worklist of operations whose parents (=users) potentially need to be
  /// repaired.  Entries may be ClassOps (added by `classUnion` whose
  /// canonical leader needs to absorb the merged class) or arbitrary
  /// operations (added by `mergeResults` because the redirected users may
  /// have become identical).  Entries may become stale (detached or
  /// erased) before being processed; such entries are skipped during
  /// rebuild via an `op->getBlock()` check.
  SmallVector<mlir::Operation *> worklist;

private:
  SmallVector<equivalence::ClassOp> pendingErase;
  SmallVector<std::pair<mlir::Value, mlir::Value>> pendingClassUnions;
};

} // namespace mlir::ematch

#endif // EQUIVALENCE_SRC_UTILS_CLASSOPUNIONFIND_H
