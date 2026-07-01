//===- EmatchTransforms.cpp - Ematch lowering & saturation -------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the ematch transform library declared in EmatchUtils.h: lowering
// ematch ops to pdl_interp (`convertEmatchOpsToApplyRewrites`) and the equality
// saturation loop (`runSaturation`). The pass drivers that call these live in
// EmatchPasses.cpp.
//
//===----------------------------------------------------------------------===//

#include "EmatchUtils.h"

#include "EmatchDetail.h"
#include "EmatchDialect.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "TamagoyakiTiming.h"
#include "Utils/ClassOpUtils.h"
#include "Utils/CongruenceEngine.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Rewrite/PatternApplicator.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <cstdint>
#include <string>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

namespace mlir::ematch {

//===----------------------------------------------------------------------===//
// Lowering ematch ops to pdl_interp.apply_rewrite
//===----------------------------------------------------------------------===//

namespace {

template <typename OpTy>
struct EmatchToApplyRewritePattern : public OpRewritePattern<OpTy> {
  using OpRewritePattern<OpTy>::OpRewritePattern;

  LogicalResult matchAndRewrite(OpTy op,
                                PatternRewriter &rewriter) const final {
    StringRef name = op->getName().stripDialect();
    rewriter.replaceOpWithNewOp<pdl_interp::ApplyRewriteOp>(
        op, op->getResultTypes(), rewriter.getStringAttr(name),
        op->getOperands());
    return success();
  }
};

void populateEmatchToApplyRewritePatterns(RewritePatternSet &patterns) {
  patterns.add<EmatchToApplyRewritePattern<GetClassValsOp>,
               EmatchToApplyRewritePattern<GetClassRepresentativeOp>,
               EmatchToApplyRewritePattern<GetClassResultOp>,
               EmatchToApplyRewritePattern<GetClassResultsOp>,
               EmatchToApplyRewritePattern<UnionOp>,
               EmatchToApplyRewritePattern<DedupOp>>(patterns.getContext());
}

} // namespace

void convertEmatchOpsToApplyRewrites(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("convertEmatchOpsToApplyRewrites");
  RewritePatternSet patterns(module.getContext());
  populateEmatchToApplyRewritePatterns(patterns);
  GreedyRewriteConfig config;
  config.enableConstantCSE(false);
  config.enableFolding(false);
  (void)applyPatternsGreedily(module, std::move(patterns), config);
}

//===----------------------------------------------------------------------===//
// Shared matcher helpers (see EmatchDetail.h)
//===----------------------------------------------------------------------===//

void registerEmatchRewrites(PDLPatternModule &pdlPattern) {
  pdlPattern.registerRewriteFunction("get_class_vals", getClassVals);
  pdlPattern.registerRewriteFunction("get_class_representative",
                                     getClassRepresentative);
  pdlPattern.registerRewriteFunction("get_class_result", getClassResult);
  pdlPattern.registerRewriteFunction("get_class_results", getClassResults);
}

bool isEquivalenceDialectOp(Operation *op) {
  Dialect *dialect = op->getDialect();
  return dialect != nullptr && isa<equivalence::EquivalenceDialect>(dialect);
}

//===----------------------------------------------------------------------===//
// Equality saturation
//===----------------------------------------------------------------------===//

namespace {

struct PendingMatch {
  Operation *op;
  mlir::detail::PDLByteCode::MatchResult matchResult;
};

} // namespace

bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener, bool eagerRewrite) {
  TAMAGOYAKI_SCOPED_TIMER("runSaturation");
  RewritePatternSet patternList(ctx);

  CongruenceEngine uf{};
  HashConsPatternRewriter hashconsRewriter(ctx);
  hashconsRewriter.setEngine(&uf);
  if (listener)
    hashconsRewriter.setListener(listener);

  irModule.walk([&](equivalence::GraphOp graph) {
    uf.hashconsGraph(hashconsRewriter, graph);
  });

  registerEmatchRewrites(pdlPattern);
  pdlPattern.registerRewriteFunction("union", [&uf, eagerRewrite](
                                                  PatternRewriter &rewriter,
                                                  PDLResultList &results,
                                                  ArrayRef<PDLValue> args) {
    assert(args.size() == 2 && "union expects 2 arguments");

    PDLValue arg0 = args[0];
    PDLValue arg1 = args[1];

    if (eagerRewrite) {
      if (arg0.isa<Value>() && arg1.isa<Value>()) {
        uf.queueClassUnion(arg0.cast<Value>(), arg1.cast<Value>());
      } else if (arg0.isa<Operation *>() && arg1.isa<ValueRange>()) {
        uf.queueClassUnion(arg0.cast<Operation *>(), arg1.cast<ValueRange>());
      } else if (arg0.isa<ValueRange>() && arg1.isa<ValueRange>()) {
        uf.queueClassUnion(arg0.cast<ValueRange>(), arg1.cast<ValueRange>());
      } else {
        llvm_unreachable("union: unsupported argument types");
      }
    } else {
      if (arg0.isa<Value>() && arg1.isa<Value>()) {
        uf.classUnion(rewriter, arg0.cast<Value>(), arg1.cast<Value>());
      } else if (arg0.isa<Operation *>() && arg1.isa<ValueRange>()) {
        uf.classUnion(rewriter, arg0.cast<Operation *>(),
                      arg1.cast<ValueRange>());
      } else if (arg0.isa<ValueRange>() && arg1.isa<ValueRange>()) {
        uf.classUnion(rewriter, arg0.cast<ValueRange>(),
                      arg1.cast<ValueRange>());
      } else {
        llvm_unreachable("union: unsupported argument types");
      }
    }
    return success();
  });
  pdlPattern.registerRewriteFunction(
      "dedup", [&hashconsRewriter](PatternRewriter &rewriter, Operation *op) {
        if (Operation *existing = hashconsRewriter.lookup(op)) {
          DEBUG_WITH_TYPE("hashcons", llvm::dbgs()
                                          << "deduplicating operation: " << *op
                                          << "\n");
          assert(existing != op);
          rewriter.eraseOp(op);
          return existing;
        }
        DEBUG_WITH_TYPE("hashcons",
                        llvm::dbgs()
                            << "no duplicate, inserting into hashcons: " << *op
                            << "\n");
        (void)hashconsRewriter.insert(op);
        return op;
      });
  patternList.add(std::move(pdlPattern));

  FrozenRewritePatternSet frozenPatterns(std::move(patternList));

  SmallVector<PendingMatch> allMatches;

  const auto *bytecode = frozenPatterns.getPDLByteCode();
  if (!bytecode) {
    return false;
  }

  mlir::detail::PDLByteCodeMutableState bytecodeState;

  int nIters = 0;
  bool maxNodesExceeded = false;
  while (true) {
    TAMAGOYAKI_SCOPED_TIMER("iteration " + std::to_string(nIters + 1));
    LLVM_DEBUG({
      irModule.walk([&](equivalence::GraphOp graph) {
        equivalence::GraphSize size = equivalence::computeGraphSize(graph);
        llvm::dbgs() << "Graph has " << size.classes << " e-classes and "
                     << size.nodes << " e-nodes (iteration " << nIters
                     << ").\n";
      });
    });

    nIters++;
    if (nIters > maxIters) {
      break;
    }
    LLVM_DEBUG(llvm::dbgs()
               << "Equality saturation: starting iteration " << nIters << "\n");

    bytecode->initializeMutableState(bytecodeState);

    if (eagerRewrite) {
      // Collect operations upfront so newly inserted ops during rewriting
      // are not visited in the same iteration.
      SmallVector<Operation *> opsToProcess;
      irModule.walk([&](Operation *op) {
        if (isEquivalenceDialectOp(op))
          return;
        opsToProcess.push_back(op);
      });

      {
        TAMAGOYAKI_SCOPED_TIMER("match+rewrite (eager)");
        for (Operation *op : opsToProcess) {
          SmallVector<mlir::detail::PDLByteCode::MatchResult> opMatches;
          bytecode->match(op, hashconsRewriter, opMatches, bytecodeState);

          for (const auto &match : opMatches) {
            hashconsRewriter.setInsertionPoint(op);
            (void)bytecode->rewrite(hashconsRewriter, match, bytecodeState);
            if (maxNodes > 0 &&
                hashconsRewriter.getNodeCount() > (uint64_t)maxNodes) {
              LLVM_DEBUG(llvm::dbgs() << "Node limit exceeded: "
                                      << hashconsRewriter.getNodeCount()
                                      << " > " << maxNodes << "\n");
              maxNodesExceeded = true;
              break;
            }
          }
          if (maxNodesExceeded)
            break;
        }
        bytecodeState.cleanupAfterMatchAndRewrite();
      }

      uf.processPendingClassUnions(hashconsRewriter);
    } else {
      {
        TAMAGOYAKI_SCOPED_TIMER("match");
        irModule.walk([&](Operation *op) {
          if (isEquivalenceDialectOp(op))
            return;

          SmallVector<mlir::detail::PDLByteCode::MatchResult> opMatches;
          bytecode->match(op, hashconsRewriter, opMatches, bytecodeState);

          for (auto &match : opMatches)
            allMatches.push_back({op, std::move(match)});
        });
      }
      {
        TAMAGOYAKI_SCOPED_TIMER("rewrite");
        for (const auto &pm : allMatches) {
          hashconsRewriter.setInsertionPoint(pm.op);
          (void)bytecode->rewrite(hashconsRewriter, pm.matchResult,
                                  bytecodeState);
          if (maxNodes > 0 &&
              hashconsRewriter.getNodeCount() > (uint64_t)maxNodes) {
            LLVM_DEBUG(llvm::dbgs() << "Node limit exceeded: "
                                    << hashconsRewriter.getNodeCount() << " > "
                                    << maxNodes << "\n");
            maxNodesExceeded = true;
            break;
          }
        }
        allMatches.clear();
        bytecodeState.cleanupAfterMatchAndRewrite();
      }
    }

    bool didRebuild = uf.rebuild(hashconsRewriter);
    if (maxNodesExceeded || !didRebuild) {
      break;
    }
  }

  return true;
}

} // namespace mlir::ematch
