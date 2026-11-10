#pragma once

#include "EquivalenceDialect.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Pass/Pass.h"

namespace cranelift {

#define GEN_PASS_DECL
#include "CraneliftPasses.h.inc"

/// Move the speculatable, non-terminator operations of the reachable blocks of
/// `funcOp` into a new `equivalence.graph`, hash-consing them, and make their
/// uses outside the graph use its results. The graph is created in front of
/// `funcOp`, so the IR does not verify until `elaborate` erases it again. When
/// `keepInPlace` returns true for an operation, it stays where it is, even if
/// it is speculatable. `funcOp` must have a body.
mlir::equivalence::GraphOp
convertToSoN(mlir::FunctionOpInterface funcOp,
             llvm::function_ref<bool(mlir::Operation *)> keepInPlace = nullptr);

/// Place the operations of `graphOp`, from which a program has been extracted,
/// back into `funcOp`, then erase `graphOp`. A dominator-tree preorder walk of
/// the blocks places each operation before its first use, reused by the
/// blocks that block dominates. `funcOp` must not have blocks unreachable from
/// its entry.
void elaborate(mlir::FunctionOpInterface funcOp,
               mlir::equivalence::GraphOp graphOp);

} // namespace cranelift
