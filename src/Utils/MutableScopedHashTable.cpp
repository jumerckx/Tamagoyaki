// MutableScopedHashTable.cpp

#include "Utils/MutableScopedHashTable.h"
#include "mlir/IR/Operation.h"
#include "vendor/mlir/SimpleOperationInfo.h"
#include "llvm/Support/Allocator.h"
#include "llvm/Support/RecyclingAllocator.h"

namespace mlir::ematch {

// Explicit instantiations
// \cond
using AllocatorTy = llvm::RecyclingAllocator<
    llvm::BumpPtrAllocator,
    MutableScopedHashTableVal<mlir::Operation *, mlir::Operation *>>;
// \endcond

template class MutableScopedHashTableVal<::mlir::Operation *,
                                          ::mlir::Operation *>;
template class MutableScopedHashTableScope<::mlir::Operation *,
                                           ::mlir::Operation *,
                                           SimpleOperationInfo, AllocatorTy>;
template class MutableScopedHashTable<::mlir::Operation *, ::mlir::Operation *,
                                      SimpleOperationInfo, AllocatorTy>;

} // namespace mlir::ematch
