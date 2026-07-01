//===- GraphScope.h - Graph-nesting scope primitives -----------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// A "scope" is the body region of an `equivalence.graph`; scopes nest along the
// graph-nesting tree. `ScopeId` is just that `Region *`, derived from IR
// nesting. A value defined outside every graph (e.g. a function argument) has a
// null scope.
//
// These are pure, stateless queries over the IR-nesting tree. They form the
// bottom layer of the scope-aware e-graph: the representative index
// (`ScopeRepIndex`) and the congruence engine (`CongruenceEngine`) are both
// phrased in terms of them.
//
// NB: This graph-nesting "scope" is unrelated to the hash-cons dedup scope
// (`ScopedMapTy::ScopeTy`) managed by `HashConsPatternRewriter`; both happen to
// be keyed by graph-body regions but are otherwise distinct mechanisms.
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_UTILS_GRAPHSCOPE_H
#define TAMAGOYAKI_SRC_UTILS_GRAPHSCOPE_H

#include "EquivalenceDialect.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Region.h"
#include "mlir/Support/LLVM.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir::ematch {

/// A scope is the body region of an `equivalence.graph`. A null scope means
/// "outside every graph".
using ScopeId = mlir::Region *;

/// The scope of `op`: the nearest enclosing `equivalence.graph` body region, or
/// null if `op` is not inside any graph.
ScopeId scopeOf(Operation *op);
ScopeId scopeOf(equivalence::ClassOp c);

/// The enclosing scope of scope `s` (the next graph body out), or null at the
/// outermost graph / for a null scope.
ScopeId parentScope(ScopeId s);

/// Distance from the outermost graph (0 for a top-level graph body); a null
/// (out-of-graph) scope also reports 0.
unsigned depthOf(ScopeId s);
unsigned depthOf(equivalence::ClassOp c);

/// Ancestor-or-equal test: does graph scope `outer` enclose `inner`? A scope
/// encloses itself, so equal scopes test true.
bool encloses(ScopeId outer, ScopeId inner);

/// Find the (unique) rep of `row` living in scope `s`, or null. Linear scan;
/// rows have at most #scopes entries, so this beats a nested map.
equivalence::ClassOp *findByScope(SmallVectorImpl<equivalence::ClassOp> &row,
                                  ScopeId s);

/// The outermost (minimum-depth) rep of a non-empty row.
equivalence::ClassOp outermost(SmallVectorImpl<equivalence::ClassOp> &row);

/// The nearest *strictly enclosing* rep of scope `s` present in `row`, or null
/// if none (i.e. `s` is the outermost occupied scope).
equivalence::ClassOp
nearestEnclosingRep(SmallVectorImpl<equivalence::ClassOp> &row, ScopeId s);

/// The deepest rep enclosing scope `s` (walk `s` outward to the first rep in
/// `row`), or null if none encloses `s`.
equivalence::ClassOp
deepestRepEnclosing(SmallVectorImpl<equivalence::ClassOp> &row, ScopeId s);

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_UTILS_GRAPHSCOPE_H
