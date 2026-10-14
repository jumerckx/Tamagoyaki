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
#include <optional>
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

struct AreEquivalentToApplyConstraintPattern
    : public OpRewritePattern<AreEquivalentOp> {
  using OpRewritePattern<AreEquivalentOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(AreEquivalentOp op,
                                PatternRewriter &rewriter) const final {
    rewriter.replaceOpWithNewOp<pdl_interp::ApplyConstraintOp>(
        op, /*results=*/TypeRange{}, op->getName().stripDialect(),
        ValueRange{op.getLhs(), op.getRhs()},
        /*isNegated=*/false, op.getTrueDest(), op.getFalseDest());
    return success();
  }
};

void populateEmatchToApplyRewritePatterns(RewritePatternSet &patterns) {
  patterns.add<EmatchToApplyRewritePattern<GetClassValsOp>,
               EmatchToApplyRewritePattern<GetClassRepresentativeOp>,
               EmatchToApplyRewritePattern<GetClassResultOp>,
               EmatchToApplyRewritePattern<GetClassResultsOp>,
               EmatchToApplyRewritePattern<UnionOp>,
               EmatchToApplyRewritePattern<RefineOp>,
               EmatchToApplyRewritePattern<UnionOrRefineOp>,
               EmatchToApplyRewritePattern<DedupOp>,
               AreEquivalentToApplyConstraintPattern>(patterns.getContext());
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
  // PDL ranges must be materialized.
  pdlPattern.registerRewriteFunction(
      "get_class_vals", [](PatternRewriter &rewriter, Value val) {
        return llvm::to_vector(getClassVals(rewriter, val));
      });
  pdlPattern.registerRewriteFunction("get_class_representative",
                                     getClassRepresentative);
  pdlPattern.registerRewriteFunction("get_class_result", getClassResult);
  pdlPattern.registerRewriteFunction("get_class_results", getClassResults);
  pdlPattern.registerConstraintFunction(
      "are_equivalent", [](PatternRewriter &, Value lhs, Value rhs) {
        return success(areEquivalent(lhs, rhs));
      });
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

/// Apply `pairFn` to the (lhs, rhs) arguments of a union or refinement.
template <typename PairFn>
void applyToPair(PatternRewriter &rewriter, PDLValue lhs, PDLValue rhs,
                 PairFn pairFn) {
  if (lhs.isa<Value>() && rhs.isa<Value>()) {
    pairFn(rewriter, lhs.cast<Value>(), rhs.cast<Value>());
  } else if (lhs.isa<Operation *>() && rhs.isa<ValueRange>()) {
    pairFn(rewriter, lhs.cast<Operation *>(), rhs.cast<ValueRange>());
  } else if (lhs.isa<ValueRange>() && rhs.isa<ValueRange>()) {
    pairFn(rewriter, lhs.cast<ValueRange>(), rhs.cast<ValueRange>());
  } else {
    llvm_unreachable("union/refine: unsupported argument types");
  }
}

template <typename PairFn> PDLRewriteFunction makePairRewrite(PairFn pairFn) {
  return [pairFn](PatternRewriter &rewriter, PDLResultList &,
                  ArrayRef<PDLValue> args) -> LogicalResult {
    assert(args.size() == 2 && "union/refine expects 2 arguments");
    applyToPair(rewriter, args[0], args[1], pairFn);
    return success();
  };
}

/// `union_or_refine(lhs, rhs, checks...)`: union if every (operand, matched)
/// pair in `checks` is equivalent, otherwise refine `lhs` into `rhs`.
template <typename UnionFn, typename RefineFn>
PDLRewriteFunction makeUnionOrRefineRewrite(UnionFn unionFn,
                                            RefineFn refineFn) {
  return [unionFn, refineFn](PatternRewriter &rewriter, PDLResultList &,
                             ArrayRef<PDLValue> args) -> LogicalResult {
    assert(args.size() >= 2 && args.size() % 2 == 0 &&
           "union_or_refine expects lhs, rhs and (operand, matched) pairs");
    bool equivalent = true;
    for (size_t i = 2; i < args.size() && equivalent; i += 2)
      equivalent =
          areEquivalent(args[i].cast<Value>(), args[i + 1].cast<Value>());
    if (equivalent)
      applyToPair(rewriter, args[0], args[1], unionFn);
    else
      applyToPair(rewriter, args[0], args[1], refineFn);
    return success();
  };
}

} // namespace

bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener, bool eagerRewrite) {
  TAMAGOYAKI_SCOPED_TIMER("runSaturation");
  // Declared before every other local so that, once started, it outlives them
  // and covers their destruction (e-graph engine, hash-cons tables, bytecode).
  std::optional<mlir::TimingScope> teardownTimer;
  RewritePatternSet patternList(ctx);

  CongruenceEngine uf{};
  HashConsPatternRewriter hashconsRewriter(ctx);
  hashconsRewriter.setEngine(&uf);
  if (listener)
    hashconsRewriter.setListener(listener);

  // Saturation operates on the regions of equivalence.graph ops: each graph
  // registers a hash-cons scope that matching and rewriting depend on. Without
  // any graph (e.g. the user forgot to run equivalence-insert-graph), the
  // operations have no scope and the rewriter would assert. Bail out gracefully
  // instead, leaving the IR untouched.
  bool hasGraph = false;
  irModule.walk([&](equivalence::GraphOp graph) {
    hasGraph = true;
    uf.hashconsGraph(hashconsRewriter, graph);
  });
  if (!hasGraph) {
    LLVM_DEBUG(llvm::dbgs()
               << "runSaturation: no equivalence.graph found; nothing to "
                  "saturate. Did you run equivalence-insert-graph?\n");
    return false;
  }

  registerEmatchRewrites(pdlPattern);
  auto unionFn = [&uf, eagerRewrite](PatternRewriter &rewriter, auto lhs,
                                     auto rhs) {
    if (eagerRewrite)
      uf.queueClassUnion(lhs, rhs);
    else
      uf.classUnion(rewriter, lhs, rhs);
  };
  auto refineFn = [&uf, eagerRewrite](PatternRewriter &rewriter, auto lhs,
                                      auto rhs) {
    if (eagerRewrite)
      uf.queueClassRefine(lhs, rhs);
    else
      uf.classRefine(rewriter, lhs, rhs);
  };
  pdlPattern.registerRewriteFunction("union", makePairRewrite(unionFn));
  pdlPattern.registerRewriteFunction("refine", makePairRewrite(refineFn));
  pdlPattern.registerRewriteFunction(
      "union_or_refine", makeUnionOrRefineRewrite(unionFn, refineFn));
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

  FrozenRewritePatternSet frozenPatterns = [&] {
    TAMAGOYAKI_SCOPED_TIMER("freezePatterns");
    return FrozenRewritePatternSet(std::move(patternList));
  }();

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
      uf.processPendingClassRefines(hashconsRewriter);
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

  teardownTimer.emplace(tamagoyaki::getTimingScope("teardown"));
  return true;
}

} // namespace mlir::ematch
