//===- EmatchDetail.h - Internal ematch helpers ------------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implementation-internal helpers shared between the ematch translation unit
// files (EmatchTransforms.cpp, EmatchPasses.cpp). NOT part of the public API —
// downstream users should include EmatchUtils.h instead.
//
//===----------------------------------------------------------------------===//

#ifndef TAMAGOYAKI_SRC_EMATCHDETAIL_H
#define TAMAGOYAKI_SRC_EMATCHDETAIL_H

#include "mlir/IR/Operation.h"
#include "mlir/IR/PatternMatch.h"

namespace mlir::ematch {

/// Register the e-class traversal helpers used by the matcher bytecode to walk
/// the e-graph (get_class_vals, get_class_representative, ...).
void registerEmatchRewrites(PDLPatternModule &pdlPattern);

/// Operations in the equivalence dialect are skipped when walking the IR for
/// matching: they form the e-graph scaffolding, not user payload.
bool isEquivalenceDialectOp(Operation *op);

} // namespace mlir::ematch

#endif // TAMAGOYAKI_SRC_EMATCHDETAIL_H
