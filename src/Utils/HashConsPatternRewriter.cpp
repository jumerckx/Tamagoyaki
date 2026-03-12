//- HashConsPatternRewriter.cpp - Hash consing for pattern rewriting -*-C++ -*//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/HashConsPatternRewriter.h"
#include "EquivalenceDialect.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Region.h"
#include "mlir/Support/LLVM.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include <cassert>
#include <memory>
#include <utility>

#define DEBUG_TYPE "hashcons"

using namespace mlir;
using namespace mlir::ematch;

HashConsPatternRewriter::HashConsPatternRewriter(MLIRContext *ctx)
    : PatternRewriter(ctx) {}

void HashConsPatternRewriter::startOpModification(Operation *op) {
  LLVM_DEBUG(llvm::dbgs() << "operation being modified (start): " << *op
                          << "\n");
  if (dyn_cast<equivalence::ClassOp>(*op))
    return;
  (void)erase(op);
  PatternRewriter::startOpModification(op);
}

void HashConsPatternRewriter::cancelOpModification(Operation *op) {
  LLVM_DEBUG(llvm::dbgs() << "operation being modified (cancel): " << *op
                          << "\n");
  if (dyn_cast<equivalence::ClassOp>(*op))
    return;
  (void)insert(op);
  PatternRewriter::cancelOpModification(op);
}

void HashConsPatternRewriter::finalizeOpModification(Operation *op) {
  LLVM_DEBUG(llvm::dbgs() << "operation being modified (finalize): " << *op
                          << "\n");
  if (dyn_cast<equivalence::ClassOp>(*op))
    return;
  (void)insert(op);
  PatternRewriter::finalizeOpModification(op);
}

LogicalResult HashConsPatternRewriter::erase(Operation *op) {
  Region *region = op->getParentRegion();
  assert(region && "erase: operation has no parent region");

  ScopedMapTy::ScopeTy *scope = getScope(region);
  assert(scope && "erase: no scope registered for region");

  bool erased = scope->erase(op);
  LLVM_DEBUG({
    if (erased) {
      llvm::dbgs() << "erased operation from hash-cons scope: " << *op << "\n";
    } else {
      llvm::dbgs() << "did not find operation to erase " << *op << "\n";
    }
  });
  if (erased) {
    nodeCount--;
  }
  return success();
}

LogicalResult HashConsPatternRewriter::insert(Operation *op) {
  Region *region = op->getParentRegion();
  assert(region && "insert: operation has no parent region");
  assert(!llvm::isa<equivalence::ClassOp>(op));

  ScopedMapTy::ScopeTy *scope = getScope(region);
  assert(scope && "insert: no scope registered for region");

  // Check if an equivalent operation already exists in the scope
  if (Operation *existing = scope->lookupOrDefault(op)) {
    LLVM_DEBUG(llvm::dbgs()
               << "insert: equivalent operation already exists: " << *existing
               << ", skipping insert of: " << *op << "\n");
    return failure();
  }

  scope->insert(op, op);
  nodeCount++;
  LLVM_DEBUG(llvm::dbgs() << "inserted operation into hash-cons scope: " << *op
                          << "\n");
  return success();
}

Operation *HashConsPatternRewriter::lookup(Operation *op) {
  Region *region = op->getParentRegion();
  assert(region && "lookup: operation has no parent region");

  ScopedMapTy::ScopeTy *scope = getScope(region);
  assert(scope && "lookup: no scope registered for region");

  return scope->lookupOrDefault(op);
}

ScopedMapTy::ScopeTy *HashConsPatternRewriter::createRootScope(Region *region) {
  assert(region && "region cannot be null");
  assert(!scopeMap.count(region) && "scope already exists for region");

  auto scope = std::make_unique<ScopedMapTy::ScopeTy>(hashcons);
  ScopedMapTy::ScopeTy *ptr = scope.get();
  scopeMap[region] = std::move(scope);

  LLVM_DEBUG(llvm::dbgs() << "created root scope for region\n");
  return ptr;
}

ScopedMapTy::ScopeTy *
HashConsPatternRewriter::createChildScope(Region *region,
                                          Region *parentRegion) {
  assert(region && "region cannot be null");
  assert(parentRegion && "parent region cannot be null");
  assert(!scopeMap.count(region) && "scope already exists for region");

  ScopedMapTy::ScopeTy *parentScope = getScope(parentRegion);
  assert(parentScope && "parent region has no registered scope");

  auto scope = std::make_unique<ScopedMapTy::ScopeTy>(hashcons, parentScope);
  ScopedMapTy::ScopeTy *ptr = scope.get();
  scopeMap[region] = std::move(scope);

  LLVM_DEBUG(llvm::dbgs() << "created child scope for region\n");
  return ptr;
}

ScopedMapTy::ScopeTy *HashConsPatternRewriter::getScope(Region *region) {
  auto it = scopeMap.find(region);
  return (it != scopeMap.end()) ? it->second.get() : nullptr;
}

void HashConsPatternRewriter::removeScope(Region *region) {
  scopeMap.erase(region);
  LLVM_DEBUG(llvm::dbgs() << "removed scope for region\n");
}
