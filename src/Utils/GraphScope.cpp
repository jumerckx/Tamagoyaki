//===- GraphScope.cpp - Graph-nesting scope primitives ---------*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/GraphScope.h"
#include "llvm/Support/Casting.h"

using namespace mlir;
using namespace mlir::ematch;

ScopeId mlir::ematch::scopeOf(Operation *op) {
  for (Region *r = op->getParentRegion(); r;) {
    Operation *parent = r->getParentOp();
    if (!parent)
      return nullptr;
    if (isa<equivalence::GraphOp>(parent))
      return r; // r is a graph body.
    r = parent->getParentRegion();
  }
  return nullptr;
}

ScopeId mlir::ematch::scopeOf(equivalence::ClassOp c) {
  return scopeOf(c.getOperation());
}

ScopeId mlir::ematch::parentScope(ScopeId s) {
  if (!s)
    return nullptr;
  return scopeOf(s->getParentOp());
}

unsigned mlir::ematch::depthOf(ScopeId s) {
  unsigned d = 0;
  for (ScopeId p = parentScope(s); p; p = parentScope(p))
    ++d;
  return d;
}

unsigned mlir::ematch::depthOf(equivalence::ClassOp c) {
  return depthOf(scopeOf(c));
}

bool mlir::ematch::encloses(ScopeId outer, ScopeId inner) {
  for (ScopeId s = inner;; s = parentScope(s)) {
    if (s == outer)
      return true;
    if (!s)
      return false;
  }
}

equivalence::ClassOp *
mlir::ematch::findByScope(SmallVectorImpl<equivalence::ClassOp> &row,
                          ScopeId s) {
  for (auto &c : row)
    if (scopeOf(c) == s)
      return &c;
  return nullptr;
}

equivalence::ClassOp
mlir::ematch::outermost(SmallVectorImpl<equivalence::ClassOp> &row) {
  equivalence::ClassOp best = row.front();
  unsigned bestDepth = depthOf(best);
  for (equivalence::ClassOp c : row) {
    unsigned d = depthOf(c);
    if (d < bestDepth) {
      best = c;
      bestDepth = d;
    }
  }
  return best;
}

equivalence::ClassOp
mlir::ematch::nearestEnclosingRep(SmallVectorImpl<equivalence::ClassOp> &row,
                                  ScopeId s) {
  for (ScopeId p = parentScope(s); p; p = parentScope(p))
    if (equivalence::ClassOp *hit = findByScope(row, p))
      return *hit;
  return {};
}

equivalence::ClassOp
mlir::ematch::deepestRepEnclosing(SmallVectorImpl<equivalence::ClassOp> &row,
                                  ScopeId s) {
  for (ScopeId p = s; p; p = parentScope(p))
    if (equivalence::ClassOp *hit = findByScope(row, p))
      return *hit;
  return {};
}
