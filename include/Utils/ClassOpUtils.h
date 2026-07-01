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
