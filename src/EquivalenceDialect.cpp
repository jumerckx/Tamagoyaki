//===- EquivalenceDialect.cpp - Equivalence dialect ---------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Definition of the equivalence dialect: op/attribute registration and the op
// methods (verifiers, folders, canonicalizers, interface impls). The reusable
// transforms/analyses live in EquivalenceTransforms.cpp and the pass drivers in
// EquivalencePasses.cpp.
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"

#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OperationSupport.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/RegionKindInterface.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Support/LogicalResult.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include <mlir/Interfaces/LoopLikeInterface.h>
#include <mlir/Support/WalkResult.h>

using namespace mlir;
using namespace mlir::equivalence;

#include "EquivalenceDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// Equivalence dialect.
//===----------------------------------------------------------------------===//

void mlir::equivalence::EquivalenceDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "EquivalenceOps.cpp.inc"

      >();
  registerAttributes();
}

//===----------------------------------------------------------------------===//
// Equivalence ops
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "EquivalenceOps.cpp.inc"

namespace mlir::equivalence {
mlir::RegionKind GraphOp::getRegionKind(unsigned index) {
  return mlir::RegionKind::Graph;
}

//===----------------------------------------------------------------------===//
// GraphOp LoopLikeOpInterface
//===----------------------------------------------------------------------===//

// A graph is not itself a loop, but it implements LoopLikeOpInterface so that
// loop-invariant code motion can hoist operations out of the graph region.
// The "loop body" inspected for invariant ops is the graph's own region, while
// the notion of "outside the loop" (for both the invariance check and the
// destination of hoisted ops) is delegated to the nearest enclosing loop. The
// net effect of running LICM on a graph nested in a loop is that invariant ops
// are lifted clear of that loop.

// The enclosing loop whose looplike behaviour this graph forwards to, or null
// if the graph is not nested in a loop.
static LoopLikeOpInterface getEnclosingLoop(GraphOp op) {
  return op->getParentOfType<LoopLikeOpInterface>();
}

bool GraphOp::isDefinedOutsideOfLoop(Value value) {
  if (LoopLikeOpInterface loop = getEnclosingLoop(*this))
    return loop.isDefinedOutsideOfLoop(value);
  // With no enclosing loop there is nowhere to hoist to, so treat nothing as
  // defined outside; this prevents LICM from moving anything.
  return false;
}

SmallVector<Region *> GraphOp::getLoopRegions() { return {&getBody()}; }

void GraphOp::moveOutOfLoop(Operation *op) {
  if (LoopLikeOpInterface loop = getEnclosingLoop(*this))
    loop.moveOutOfLoop(op);
}
} // namespace mlir::equivalence

mlir::LogicalResult mlir::equivalence::ClassOp::verify() {
  // verify() only enforces the structural invariants that must always hold for
  // a class op to be meaningful. The stronger normal-form properties — a class
  // result is never an operand of another class, a class's operands are used
  // only by the class, and operands are unique — are *not* checked here: they
  // are transiently broken by other ops' canonicalizations (e.g. `c1 + 0 -> c1`
  // floats a class result into a class operand, and rerouting external uses can
  // collapse two operands to the same value) and are the responsibility of the
  // `equivalence-restore-invariants` normalization pass, not of
  // well-formedness.
  if (getInputs().empty()) {
    return emitOpError("must have at least one operand");
  }

  if (Value leader = getLeader()) {
    Operation *defOp = leader.getDefiningOp();
    if (!defOp || !isa<ClassOp>(defOp)) {
      return emitOpError("leader must be the result of a class operation");
    }
  }

  return success();
}

mlir::OpFoldResult mlir::equivalence::ClassOp::fold(FoldAdaptor adaptor) {
  // A class that lists its own result as an operand: that operand is redundant
  // and can be dropped in place.
  for (auto [idx, input] : llvm::enumerate(getInputs())) {
    auto innerClass = input.getDefiningOp<ClassOp>();
    if (innerClass == getOperation()) {
      getInputsMutable().erase(static_cast<unsigned>(idx));
      return getResult();
    }
  }

  // Drop duplicate operands. A value appearing more than once adds nothing to
  // the equivalence set, and the verifier requires operands to be unique.
  SmallPtrSet<Value, 8> seen;
  for (auto [idx, input] : llvm::enumerate(getInputs())) {
    if (!seen.insert(input).second) {
      getInputsMutable().erase(static_cast<unsigned>(idx));
      // A precomputed selection refers to operands by index, so it is now
      // stale.
      (*this)->removeAttr("min_cost_index");
      return getResult();
    }
  }

  // A trivial e-class — a single input — is interchangeable with that input.
  if (!getLeader() && (getInputs().size() == 1))
    return getInputs().front();

  return {};
}

mlir::LogicalResult
mlir::equivalence::ClassOp::canonicalize(ClassOp op,
                                         PatternRewriter &rewriter) {
  // Drop self-referential and duplicate operands.
  {
    SmallPtrSet<Value, 8> seen;
    SmallVector<Value> unique;
    for (Value input : op.getInputs()) {
      if (input.getDefiningOp() == op.getOperation())
        continue; // self-reference
      if (seen.insert(input).second)
        unique.push_back(input);
    }
    if (!unique.empty() && unique.size() != op.getInputs().size()) {
      rewriter.modifyOpInPlace(op, [&] {
        // Operand indices change, so any precomputed selection is stale.
        op->removeAttr("min_cost_index");
        op.getInputsMutable().assign(unique);
      });
      return success();
    }
  }

  // Merge a nested e-class into this one. If an operand is itself the result of
  // another class, the two classes denote the same equivalence set and can be
  // collapsed: the inner class absorbs this class's remaining operands and this
  // class is replaced by the inner class result. This is the structural rewrite
  // that establishes "a class result is never an operand of another class".
  if (!op.getLeader()) {
    for (auto [idx, input] : llvm::enumerate(op.getInputs())) {
      auto innerClass = input.getDefiningOp<ClassOp>();
      if (!innerClass || innerClass == op.getOperation())
        continue;

      SmallVector<Value> merged = llvm::to_vector(innerClass.getInputs());
      SmallPtrSet<Value, 8> seen(merged.begin(), merged.end());
      for (auto [j, other] : llvm::enumerate(op.getInputs())) {
        if (j == idx)
          continue;
        if (seen.insert(other).second)
          merged.push_back(other);
      }

      rewriter.modifyOpInPlace(innerClass, [&] {
        // Operand indices change, so any precomputed selection is stale.
        innerClass->removeAttr("min_cost_index");
        innerClass.getInputsMutable().assign(merged);
      });
      rewriter.replaceOp(op, innerClass.getResult());
      return success();
    }
  }

  Value result = op.getResult();
  bool changed = false;

  // Every operand of an e-class is, by definition, equivalent to the class
  // itself. Any other operation that still refers to the operand directly
  // should instead route through the class result. Rewriting these uses
  // establishes the invariant that a class's operands are used only by the
  // class operation.
  for (Value input : op.getInputs()) {
    rewriter.replaceUsesWithIf(input, result, [&](OpOperand &use) {
      if (use.getOwner() == op.getOperation())
        return false;
      changed = true;
      return true;
    });
  }

  return success(changed);
}

mlir::LogicalResult mlir::equivalence::GraphOp::verify() {
  auto walkResult = getBody().walk([&](Operation *op) -> WalkResult {
    if (isa<YieldOp>(op))
      return WalkResult::advance();
    if (!mlir::isSpeculatable(op) &&
        !op->hasAttrOfType<UnitAttr>("equivalence.allow_unspeculatable")) {
      return op->emitOpError(
          "operation in equivalence.graph region must be "
          "speculatable or carry the "
          "`equivalence.allow_unspeculatable` unit attribute");
    }
    return WalkResult::advance();
  });
  return failure(walkResult.wasInterrupted());
}

//===----------------------------------------------------------------------===//
// Equivalence attributes
//===----------------------------------------------------------------------===//

#define GET_ATTRDEF_CLASSES
#include "EquivalenceAttrs.cpp.inc"

void mlir::equivalence::EquivalenceDialect::registerAttributes() {
  addAttributes<
#define GET_ATTRDEF_LIST
#include "EquivalenceAttrs.cpp.inc"

      >();
}
