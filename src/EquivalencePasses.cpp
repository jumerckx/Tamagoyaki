//===- EquivalencePasses.cpp - Equivalence pass drivers ----------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The equivalence dialect's pass drivers. Each pass is a thin wrapper that
// walks the module and delegates to the reusable transforms/analyses in
// EquivalenceTransforms.cpp (declared in EquivalenceUtils.h).
//
//===----------------------------------------------------------------------===//

#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/Support/LLVM.h"
#include "llvm/Support/raw_ostream.h"
#include <cstdint>
#include <mlir/IR/Block.h>
#include <mlir/Interfaces/FunctionInterfaces.h>
#include <string>

using namespace mlir;
using namespace mlir::equivalence;

namespace mlir::equivalence {
#define GEN_PASS_DEF_EQUIVALENCEINSERTGRAPH
#define GEN_PASS_DEF_EQUIVALENCESELECTGREEDY
#define GEN_PASS_DEF_EQUIVALENCESELECTCONSTANTS
#define GEN_PASS_DEF_EQUIVALENCEEXTRACT
#define GEN_PASS_DEF_EQUIVALENCEGRAPHSIZE
#define GEN_PASS_DEF_EQUIVALENCERESTOREINVARIANTS
#include "EquivalencePasses.h.inc"

namespace {

class EquivalenceInsertGraph
    : public impl::EquivalenceInsertGraphBase<EquivalenceInsertGraph> {
public:
  using impl::EquivalenceInsertGraphBase<
      EquivalenceInsertGraph>::EquivalenceInsertGraphBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();

    module->walk([&](FunctionOpInterface funcOp) {
      if (failed(insertGraphInFunction(funcOp, false))) {
        signalPassFailure();
      }
    });
  }
};

class EquivalenceSelectGreedy
    : public impl::EquivalenceSelectGreedyBase<EquivalenceSelectGreedy> {
public:
  using impl::EquivalenceSelectGreedyBase<
      EquivalenceSelectGreedy>::EquivalenceSelectGreedyBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    int64_t defaultCostVal = this->defaultCost;
    std::string costAttributeName = this->costAttributeName;

    module.walk([&](GraphOp graphOp) {
      selectGreedy(graphOp, defaultCostVal, costAttributeName);
    });
  }
};

class EquivalenceSelectConstants
    : public impl::EquivalenceSelectConstantsBase<EquivalenceSelectConstants> {
public:
  using impl::EquivalenceSelectConstantsBase<
      EquivalenceSelectConstants>::EquivalenceSelectConstantsBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    module.walk([&](GraphOp graphOp) { selectConstants(graphOp); });
  }
};

class EquivalenceExtract
    : public impl::EquivalenceExtractBase<EquivalenceExtract> {
public:
  using impl::EquivalenceExtractBase<
      EquivalenceExtract>::EquivalenceExtractBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();

    module.walk([&](GraphOp graphOp) {
      extractFromGraph(graphOp);

      if (this->removeGraphs) {
        Block &block = graphOp.getBody().front();
        bool hasClassOps = false;
        block.walk([&](ClassOp) { hasClassOps = true; });
        if (!hasClassOps)
          inlineGraphOp(graphOp);
      }
    });
  }
};

class EquivalenceRestoreInvariants
    : public impl::EquivalenceRestoreInvariantsBase<
          EquivalenceRestoreInvariants> {
public:
  using impl::EquivalenceRestoreInvariantsBase<
      EquivalenceRestoreInvariants>::EquivalenceRestoreInvariantsBase;
  void runOnOperation() final {
    if (failed(restoreClassInvariants(getOperation())))
      signalPassFailure();
  }
};

class EquivalenceGraphSize
    : public impl::EquivalenceGraphSizeBase<EquivalenceGraphSize> {
public:
  using impl::EquivalenceGraphSizeBase<
      EquivalenceGraphSize>::EquivalenceGraphSizeBase;
  void runOnOperation() final {
    ModuleOp module = getOperation();
    module.walk([&](GraphOp graphOp) {
      GraphSize size = computeGraphSize(graphOp);
      llvm::outs() << "Graph has " << size.classes << " e-classes and "
                   << size.nodes << " e-nodes.\n";
    });
  }
};

} // namespace
} // namespace mlir::equivalence
