//===- ScopeRepIndex.cpp - Scope-partitioned e-class rep index --*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/ScopeRepIndex.h"
#include "EquivalenceDialect.h"
#include "Utils/GraphScope.h"
#include <cassert>
#include <cstddef>
#include <mlir/Support/LLVM.h>
#include <utility>

using namespace mlir;
using namespace mlir::ematch;

SmallVector<equivalence::ClassOp> &
ScopeRepIndex::rowFor(equivalence::ClassOp root) {
  auto it = scopeReps.find(root);
  if (it != scopeReps.end())
    return it->second;
  auto &row = scopeReps[root];
  row.push_back(root); // singleton component, root trivially outermost.
  return row;
}

void ScopeRepIndex::mergeScopeRows(equivalence::ClassOp winRoot,
                                   equivalence::ClassOp loseRoot) {
  auto loseIt = scopeReps.find(loseRoot);
  if (loseIt == scopeReps.end())
    return; // defensive: nothing to fold in.

  // Move `lose` out and erase its key first: appending into `win` below may
  // rehash `scopeReps`, which would invalidate any reference into it.
  SmallVector<equivalence::ClassOp> lose = std::move(loseIt->second);
  scopeReps.erase(loseRoot);

  auto &win = rowFor(winRoot); // seeds `{winRoot}` on first access.
  for (equivalence::ClassOp r : lose) {
    if (equivalence::ClassOp *s = findByScope(win, scopeOf(r)))
      sameScopeDups.push_back({r, *s}); // r must fuse into the existing rep.
    else
      win.push_back(r);
    assert(encloses(scopeOf(winRoot), scopeOf(r)) &&
           "winRoot must enclose every merged rep");
  }
}

void ScopeRepIndex::forgetClass(equivalence::ClassOp c) {
  scopeReps.erase(c); // its own (root) row, if any.
  for (auto &kv : scopeReps) {
    auto &row = kv.second;
    for (size_t i = 0, e = row.size(); i < e; ++i)
      if (row[i] == c) {
        row[i] = row.back();
        row.pop_back();
        break;
      }
  }
}

void ScopeRepIndex::reorientComponent(
    SmallVectorImpl<equivalence::ClassOp> &row) {
  if (row.empty())
    return;
  equivalence::ClassOp rootRep = outermost(row);
  rootRep.getLeaderMutable().clear();
  for (equivalence::ClassOp r : row) {
    if (r == rootRep)
      continue;
    equivalence::ClassOp tgt = nearestEnclosingRep(row, scopeOf(r));
    assert(tgt && encloses(scopeOf(tgt), scopeOf(r)) &&
           "every non-root rep has a strictly-enclosing rep");
    r.getLeaderMutable().assign(tgt.getResult());
  }
}

#ifndef NDEBUG
void ScopeRepIndex::verify() {
  for (auto &kv : scopeReps) {
    auto &row = kv.second;
    for (size_t i = 0, e = row.size(); i < e; ++i) {
      assert(row[i]->getBlock() && "stale rep in index");
      for (size_t j = i + 1; j < e; ++j)
        assert(scopeOf(row[i]) != scopeOf(row[j]) &&
               "two reps share a scope in one row");
    }
    if (!row.empty())
      assert(kv.first == outermost(row) &&
             "row must be keyed by its outermost rep");
  }
}
#endif
