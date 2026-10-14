//===- CongruenceEngine.h - Scope-aware e-graph congruence engine ---*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// `CongruenceEngine` drives equality saturation over an `equivalence.graph`:
// it unions e-classes, hash-conses e-nodes, and rebuilds congruence to a
// fixpoint. The union-find itself is not a standalone structure — it lives in
// the IR as the `leader` operand chain of `equivalence.class` ops (path
// compression happens in `getCanonicalLeader`, see ClassOpUtils.h).
//
// Layering:
//   GraphScope       (pure scope-tree queries)
//   ClassOpUtils     (stateless ClassOp/value helpers)
//   ScopeRepIndex    (per-component scope-rep bookkeeping)
//   CongruenceEngine (this file: worklist, rebuild, hash-cons + rewriter glue)
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_UTILS_CONGRUENCEENGINE_H
#define TAMAGOYAKI_SRC_UTILS_CONGRUENCEENGINE_H

#include "EquivalenceDialect.h"
#include "Utils/ClassOpUtils.h"
#include "Utils/HashConsPatternRewriter.h"
#include "Utils/ScopeRepIndex.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/SmallVector.h"
#include <utility>

namespace mlir::ematch {

/// Scope-aware congruence engine for equality saturation over
/// `equivalence.graph` e-graphs.
class CongruenceEngine {
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

  /// Record that `a` may be replaced by `b` (but not vice versa) by adding a
  /// `refines` edge from the e-class of `a` to that of `b`. No-op if they are
  /// in the same e-class or the edge exists. Redundant edges and cycles are
  /// left to `rebuild`. Returns true if the e-graph changed.
  bool classRefine(mlir::PatternRewriter &rewriter, mlir::Value a,
                   mlir::Value b);

  /// Refine an operation's results into corresponding values
  void classRefine(mlir::PatternRewriter &rewriter, mlir::Operation *op,
                   mlir::ValueRange vals);

  /// Refine one value range into another, pairwise
  void classRefine(mlir::PatternRewriter &rewriter, mlir::ValueRange a,
                   mlir::ValueRange b);

  /// Queue a refinement of `a` into `b` for later processing
  void queueClassRefine(mlir::Value a, mlir::Value b);

  /// Queue refinements of an operation's results into corresponding values
  void queueClassRefine(mlir::Operation *op, mlir::ValueRange vals);

  /// Queue pairwise refinements of one value range into another
  void queueClassRefine(mlir::ValueRange a, mlir::ValueRange b);

  /// Process all pending queued refinements
  void processPendingClassRefines(mlir::PatternRewriter &rewriter);

  /// `op` was (re-)inserted into the hash-cons table. If one of its operands
  /// has refinements, schedule it for congruence (see `rebuildRefinements`).
  void notifyENodeInserted(mlir::Operation *op);

  /// Repair the parents of each ClassOp in the worklist, then restore the
  /// refinement invariants (see `rebuildRefinements`), to a fixpoint.
  /// This also clears the worklist.
  /// Returns false when there was nothing to do, otherwise true.
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

  /// `dup` was found congruent to an existing e-node while being re-keyed
  /// after an operand change. Schedule `repair` (via the worklist) so the
  /// duplicate is collapsed through the same path as any other duplicate
  /// parent. Safe to call mid-`rebuild`.
  void repairDuplicate(mlir::Operation *dup);

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
  /// Per-component scope-rep bookkeeping (see ScopeRepIndex.h).
  ScopeRepIndex index;

  // Component roots touched since the last rebuild. Entries may go stale;
  // rebuild re-canonicalizes and skips dead ops.
  llvm::SetVector<equivalence::ClassOp> dirtyRoots;

  /// Set once any refinement exists, so e-graphs without refinements never
  /// pay for `rebuildRefinements`.
  bool hasRefinements = false;

  /// Classes with outgoing `refines` edges, and classes that are the target
  /// of one. Fused classes are dropped by `fuseSameScope`.
  llvm::SetVector<equivalence::ClassOp> refinedClasses;
  llvm::SetVector<equivalence::ClassOp> refineTargets;

  /// Classes whose refinements (in either direction) or whose e-nodes changed
  /// since the last `rebuildRefinements`.
  llvm::SetVector<equivalence::ClassOp> dirtyRefinements;

  SmallVector<equivalence::ClassOp> pendingErase;
  SmallVector<std::pair<mlir::Value, mlir::Value>> pendingClassUnions;
  SmallVector<std::pair<mlir::Value, mlir::Value>> pendingClassRefines;

  /// Fold same-scope `dup` into `survivor` and detach `dup` for erasure.
  void fuseSameScope(HashConsPatternRewriter &rewriter,
                     equivalence::ClassOp dup, equivalence::ClassOp survivor);

  /// Move every user of `rep` to the deepest rep in `row` that still encloses
  /// the user, queueing affected classes for congruence repair.
  void retargetUsersToDeepest(equivalence::ClassOp rep,
                              SmallVectorImpl<equivalence::ClassOp> &row);

  /// Restore the invariants of refinement edges after unions (drop edges
  /// into the own e-class and duplicates), union the e-classes on cycles, and
  /// close refinements under congruence: if `a` refines into `b`, then `f(a)`
  /// refines into `f(b)` whenever both e-nodes exist. Only the classes in
  /// `dirtyRefinements` are checked for congruence. Returns true if the
  /// e-graph changed.
  bool rebuildRefinements(mlir::PatternRewriter &rewriter);

  /// Union the e-classes on every cycle of `refines` edges. Returns true if
  /// any were unioned.
  bool unionRefinementCycles(mlir::PatternRewriter &rewriter);

  /// Collect pairs of e-nodes `(f(.., a, ..), f(.., b, ..))`, given that `a`
  /// refines into `b`.
  void collectCongruentRefinements(
      mlir::Value a, mlir::Value b,
      SmallVectorImpl<std::pair<mlir::Operation *, mlir::Operation *>> &pairs);
};

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_UTILS_CONGRUENCEENGINE_H
