// This file is adapted from mlir/CSE.h (part of the LLVM Project).
// It contains the SimpleOperationInfo struct used for hashing operations.
// Importantly, we also add the IgnoreCommutativity flag

#ifndef MLIR_SIMPLE_OPERATION_INFO_H
#define MLIR_SIMPLE_OPERATION_INFO_H

#include "mlir/IR/Operation.h"
#include "mlir/IR/OperationSupport.h"
#include "llvm/ADT/DenseMapInfo.h"

namespace mlir::ematch {

struct SimpleOperationInfo : public llvm::DenseMapInfo<Operation *> {
  static unsigned getHashValue(const Operation *opC) {
    return OperationEquivalence::computeHash(
        const_cast<Operation *>(opC),
        /*hashOperands=*/OperationEquivalence::directHashValue,
        /*hashResults=*/OperationEquivalence::ignoreHashValue,
        OperationEquivalence::IgnoreLocations |
            OperationEquivalence::IgnoreCommutativity);
  }
  static bool isEqual(const Operation *lhsC, const Operation *rhsC) {
    auto *lhs = const_cast<Operation *>(lhsC);
    auto *rhs = const_cast<Operation *>(rhsC);
    if (lhs == rhs)
      return true;
    if (lhs == getTombstoneKey() || lhs == getEmptyKey() ||
        rhs == getTombstoneKey() || rhs == getEmptyKey())
      return false;
    return OperationEquivalence::isEquivalentTo(
        const_cast<Operation *>(lhsC), const_cast<Operation *>(rhsC),
        OperationEquivalence::IgnoreLocations |
            OperationEquivalence::IgnoreCommutativity);
  }
};

} // namespace mlir::ematch

#endif // MLIR_SIMPLE_OPERATION_INFO_H
