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

  /// Repair e-graph by potentially deduplicating the parents of
  /// a merged ClassOp.
  void repair(HashConsPatternRewriter &rewriter, equivalence::ClassOp classOp);

  /// Worklist of ClassOps whose parents potentially need to be repaired.
  /// Entries may become stale (operands cleared) if they were merged into
  /// another class; such entries are skipped during rebuild.
  SmallVector<equivalence::ClassOp> worklist;

private:
  SmallVector<equivalence::ClassOp> pendingErase;
  SmallVector<std::pair<mlir::Value, mlir::Value>> pendingClassUnions;
};

} // namespace mlir::ematch

#endif // EQUIVALENCE_SRC_UTILS_CLASSOPUNIONFIND_H
