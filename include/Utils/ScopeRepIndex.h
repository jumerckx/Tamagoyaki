//===- ScopeRepIndex.h - Scope-partitioned e-class rep index ----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The `ScopeRepIndex` tracks, per union-find component, one representative
// `equivalence.class` op per graph scope (see GraphScope.h). It is the
// bookkeeping half of the scope-aware e-graph: it knows which reps a component
// occupies and how they nest, but performs no hash-consing and drives no
// pattern rewriter. All IR mutation that touches users, hash-cons tables, or
// the worklist lives in `CongruenceEngine`.
//
// The one exception is `reorientComponent`, which rewires ClassOp leader
// operands directly (no rewriter) so the in-IR leader chain matches the index's
// nesting; it is kept here because it restores this index's structural
// invariant.
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_UTILS_SCOPEREPINDEX_H
#define TAMAGOYAKI_SRC_UTILS_SCOPEREPINDEX_H

#include "EquivalenceDialect.h"
#include "mlir/IR/Operation.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include <utility>

namespace mlir::ematch {

/// Per-component index of scope representatives, keyed by union-find root.
///
/// Each row holds at most one ClassOp per scope (the reps); the keying root is
/// the row's outermost entry. Rows are seeded lazily (see `rowFor`).
struct ScopeRepIndex {
  // Per-component scope index, keyed by the union-find root.
  llvm::DenseMap<equivalence::ClassOp, SmallVector<equivalence::ClassOp>>
      scopeReps;

  // {dup, survivor} pairs that share a scope: dup is folded into survivor and
  // erased during rebuild. Populated by `mergeScopeRows`, drained by
  // `CongruenceEngine::rebuild`.
  SmallVector<std::pair<equivalence::ClassOp, equivalence::ClassOp>>
      sameScopeDups;

  // Union by rank, tracked out-of-IR. Since this only affects the
  // union-by-rank heuristic, not correctness, no special handling is required
  // for deletes / modifies.
  llvm::DenseMap<mlir::Operation *, unsigned> unionRank;

  /// Return the row for `root`, seeding it with `{root}` on first access.
  SmallVector<equivalence::ClassOp> &rowFor(equivalence::ClassOp root);

  /// Merge `loseRoot`'s row into `winRoot`'s, queueing same-scope collisions
  /// into `sameScopeDups`. `winRoot` must enclose every entry.
  void mergeScopeRows(equivalence::ClassOp winRoot,
                      equivalence::ClassOp loseRoot);

  /// Drop every trace of `c` from the index. Harmless if `c` is absent.
  void forgetClass(equivalence::ClassOp c);

  /// Point every non-outermost rep's leader at its nearest enclosing rep in
  /// `row`; clear the outermost rep's leader. Rewires leader operands directly.
  void reorientComponent(SmallVectorImpl<equivalence::ClassOp> &row);

#ifndef NDEBUG
  /// Consistency check on `scopeReps`.
  void verify();
#endif
};

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_UTILS_SCOPEREPINDEX_H
