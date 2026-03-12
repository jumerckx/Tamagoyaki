//- HashConsPatternRewriter.h - Hash consing for pattern rewriting -*- C++ -*-//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_UTILS_HASHCONSPATTERNREWRITER_H
#define TAMAGOYAKI_SRC_UTILS_HASHCONSPATTERNREWRITER_H

#include "MutableScopedHashTable.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Region.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/SimpleOperationInfo.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/RecyclingAllocator.h"
#include <memory>

namespace mlir::ematch {

/// Allocator type for hash consing
using AllocatorTy = llvm::RecyclingAllocator<
    llvm::BumpPtrAllocator,
    mlir::ematch::MutableScopedHashTableVal<Operation *, Operation *>>;

/// Scoped hash table type for operation deduplication
using ScopedMapTy = MutableScopedHashTable<Operation *, Operation *,
                                           SimpleOperationInfo, AllocatorTy>;

/// Pattern rewriter with hash consing support
class HashConsPatternRewriter : public PatternRewriter {
public:
  explicit HashConsPatternRewriter(MLIRContext *ctx);

  void startOpModification(Operation *op) override;
  void cancelOpModification(Operation *op) override;
  void finalizeOpModification(Operation *op) override;

  /// Erase an operation from its region's hash-cons scope.
  /// Returns success if the operation was found and removed.
  LogicalResult erase(Operation *op);

  /// Insert an operation into its region's hash-cons scope
  LogicalResult insert(Operation *op);

  /// Lookup an operation in its region's scope (searches parent scopes too)
  /// Returns nullptr if not found or no scope registered
  Operation *lookup(Operation *op);

  /// Create a root scope for a region (no parent)
  ScopedMapTy::ScopeTy *createRootScope(Region *region);

  /// Create a child scope for a region with a parent region's scope
  ScopedMapTy::ScopeTy *createChildScope(Region *region, Region *parentRegion);

  /// Get the scope for a region, or nullptr if not registered
  ScopedMapTy::ScopeTy *getScope(Region *region);

  /// Remove a scope registration (does not destroy the scope)
  void removeScope(Region *region);

  /// Get the current node count
  uint64_t getNodeCount() const { return nodeCount; }

  /// Set the current node count
  void setNodeCount(uint64_t count) { nodeCount = count; }

private:
  ScopedMapTy hashcons;

  /// Maps regions to their corresponding hash-cons scopes
  llvm::DenseMap<Region *, std::unique_ptr<ScopedMapTy::ScopeTy>> scopeMap;

  /// Counter for the number of nodes in the e-graph
  uint64_t nodeCount = 0;
};

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_UTILS_HASHCONSPATTERNREWRITER_H
