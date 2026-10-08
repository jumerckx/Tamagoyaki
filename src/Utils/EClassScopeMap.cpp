//===- EClassScopeMap.cpp - Per-scope instances of an e-class ---*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/EClassScopeMap.h"
#include "EquivalenceDialect.h"
#include "Utils/GraphScope.h"
#include <cassert>
#include <cstddef>
#include <mlir/Support/LLVM.h>
#include <utility>

using namespace mlir;
using namespace mlir::ematch;

SmallVector<equivalence::ClassOp> &
EClassScopeMap::instancesFor(equivalence::ClassOp root) {
  auto it = instancesByRoot.find(root);
  if (it != instancesByRoot.end())
    return it->second;
  auto &instances = instancesByRoot[root];
  instances.push_back(root); // singleton e-class, root trivially outermost.
  return instances;
}

void EClassScopeMap::mergeInstanceSets(equivalence::ClassOp winRoot,
                                       equivalence::ClassOp loseRoot) {
  auto loseIt = instancesByRoot.find(loseRoot);
  if (loseIt == instancesByRoot.end())
    return; // defensive: nothing to fold in.

  // Move `lose` out and erase its key first: appending into `win` below may
  // rehash `instancesByRoot`, which would invalidate any reference into it.
  SmallVector<equivalence::ClassOp> lose = std::move(loseIt->second);
  instancesByRoot.erase(loseRoot);

  auto &win = instancesFor(winRoot); // seeds `{winRoot}` on first access.
  for (equivalence::ClassOp r : lose) {
    if (equivalence::ClassOp *s = findByScope(win, scopeOf(r)))
      pendingFuses.push_back({r, *s}); // r must fuse into the existing rep.
    else
      win.push_back(r);
    assert(encloses(scopeOf(winRoot), scopeOf(r)) &&
           "winRoot must enclose every merged rep");
  }
}

void EClassScopeMap::forgetClass(equivalence::ClassOp c) {
  instancesByRoot.erase(c); // its own (root) instances, if any.
  for (auto &kv : instancesByRoot) {
    auto &instances = kv.second;
    for (size_t i = 0, e = instances.size(); i < e; ++i)
      if (instances[i] == c) {
        instances[i] = instances.back();
        instances.pop_back();
        break;
      }
  }
}

void EClassScopeMap::reorientEClass(
    SmallVectorImpl<equivalence::ClassOp> &instances) {
  if (instances.empty())
    return;
  equivalence::ClassOp rootRep = outermost(instances);
  rootRep.getLeaderMutable().clear();
  for (equivalence::ClassOp r : instances) {
    if (r == rootRep)
      continue;
    equivalence::ClassOp tgt = nearestEnclosingRep(instances, scopeOf(r));
    assert(tgt && encloses(scopeOf(tgt), scopeOf(r)) &&
           "every non-root rep has a strictly-enclosing rep");
    r.getLeaderMutable().assign(tgt.getResult());
  }
}

#ifndef NDEBUG
void EClassScopeMap::verify() {
  for (auto &kv : instancesByRoot) {
    auto &instances = kv.second;
    for (size_t i = 0, e = instances.size(); i < e; ++i) {
      assert(instances[i]->getBlock() && "stale rep in index");
      for (size_t j = i + 1; j < e; ++j)
        assert(scopeOf(instances[i]) != scopeOf(instances[j]) &&
               "two reps share a scope in one instance set");
    }
    if (!instances.empty())
      assert(kv.first == outermost(instances) &&
             "instance set must be keyed by its outermost rep");
  }
}
#endif
