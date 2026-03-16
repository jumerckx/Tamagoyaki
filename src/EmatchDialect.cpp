//===- EmatchDialect.cpp - Ematch dialect -----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "TamagoyakiTiming.h"

#include "EquivalenceDialect.h"
#include "Utils/ClassOpUnionFind.h"
#include "Utils/HashConsPatternRewriter.h"
#include "Utils/MutableScopedHashTable.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
// IWYU pragma: no_include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Rewrite/PatternApplicator.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <chrono>
#include <string>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

#include "EmatchDialect.cpp.inc"

//===----------------------------------------------------------------------===//
// Ematch dialect.
//===----------------------------------------------------------------------===//

void EmatchDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "EmatchOps.cpp.inc"

      >();
}

Type EmatchDialect::parseType(DialectAsmParser &parser) const {
  StringRef typeName;
  if (parser.parseKeyword(&typeName))
    return Type();
  return {};
}

void EmatchDialect::printType(Type type, DialectAsmPrinter &os) const {
  os << "unknown";
}

//===----------------------------------------------------------------------===//
// Ematch ops
//===----------------------------------------------------------------------===//

#define GET_OP_CLASSES
#include "EmatchOps.cpp.inc"

//===----------------------------------------------------------------------===//
// Ematch Passes
//===----------------------------------------------------------------------===//

namespace mlir::ematch {

#define GEN_PASS_DEF_EMATCHSATURATEPASS
#define GEN_PASS_DEF_EMATCHSATURATEBENCHMARKPASS
#define GEN_PASS_DEF_CONVERTEMATCHTOPDLINTERPPASS
#define GEN_PASS_DEF_APPLYPDLINTERPPASS
#include "EmatchPasses.h.inc"

namespace {

struct PendingMatch {
  Operation *op;
  mlir::detail::PDLByteCode::MatchResult matchResult;
};

} // namespace

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

static void populateEmatchToApplyRewritePatterns(RewritePatternSet &patterns) {
  patterns.add<EmatchToApplyRewritePattern<GetClassValsOp>,
               EmatchToApplyRewritePattern<GetClassRepresentativeOp>,
               EmatchToApplyRewritePattern<GetClassResultOp>,
               EmatchToApplyRewritePattern<GetClassResultsOp>,
               EmatchToApplyRewritePattern<UnionOp>,
               EmatchToApplyRewritePattern<DedupOp>>(patterns.getContext());
}

void convertEmatchOpsToApplyRewrites(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("convertEmatchOpsToApplyRewrites");
  RewritePatternSet patterns(module.getContext());
  populateEmatchToApplyRewritePatterns(patterns);
  GreedyRewriteConfig config;
  config.enableConstantCSE(false);
  config.enableFolding(false);
  (void)applyPatternsGreedily(module, std::move(patterns), config);
}

/// Run equality saturation on the given IR module using the provided pattern
/// module. The patternsModule is consumed (removed from parent).
/// Returns true on success.
bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener) {
  TAMAGOYAKI_SCOPED_TIMER("runSaturation");
  RewritePatternSet patternList(ctx);

  ClassOpUnionFind uf{};
  HashConsPatternRewriter hashconsRewriter(ctx);
  if (listener)
    hashconsRewriter.setListener(listener);

  irModule.walk([&](equivalence::GraphOp graph) {
    Region *region = &(graph.getBody());
    auto scope = hashconsRewriter.createRootScope(region);

    graph->walk([&](Operation *op) {
      if (dyn_cast<equivalence::ClassOp>(*op)) {
        return;
      }
      scope->insert(op, op);
      hashconsRewriter.setNodeCount(hashconsRewriter.getNodeCount() + 1);
    });
  });

  pdlPattern.registerRewriteFunction("get_class_vals", getClassVals);
  pdlPattern.registerRewriteFunction("get_class_representative",
                                     getClassRepresentative);
  pdlPattern.registerRewriteFunction("get_class_result", getClassResult);
  pdlPattern.registerRewriteFunction("get_class_results", getClassResults);
  pdlPattern.registerRewriteFunction("union", [&uf](PatternRewriter &rewriter,
                                                    PDLResultList &results,
                                                    ArrayRef<PDLValue> args) {
    assert(args.size() == 2 && "union expects 2 arguments");

    PDLValue arg0 = args[0];
    PDLValue arg1 = args[1];

    if (arg0.isa<Value>() && arg1.isa<Value>()) {
      uf.classUnion(rewriter, arg0.cast<Value>(), arg1.cast<Value>());
    } else if (arg0.isa<Operation *>() && arg1.isa<ValueRange>()) {
      uf.classUnion(rewriter, arg0.cast<Operation *>(),
                    arg1.cast<ValueRange>());
    } else if (arg0.isa<ValueRange>() && arg1.isa<ValueRange>()) {
      uf.classUnion(rewriter, arg0.cast<ValueRange>(), arg1.cast<ValueRange>());
    } else {
      llvm_unreachable("union: unsupported argument types");
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
        int classes = 0;
        int nodes = 0;
        graph.walk([&](Operation *op) {
          if (dyn_cast<equivalence::ClassOp>(op)) {
            classes += 1;
          } else {
            nodes += op->getNumResults();
            for (auto result : op->getResults()) {
              if (!(result.hasOneUse() &&
                    dyn_cast<equivalence::ClassOp>(*result.user_begin()))) {
                classes += 1;
              }
            }
          }
        });
        llvm::dbgs() << "Graph has " << classes << " e-classes and " << nodes
                     << " e-nodes (iteration " << nIters << ").\n";
      });
    });

    nIters++;
    if (nIters > maxIters) {
      break;
    }
    LLVM_DEBUG(llvm::dbgs()
               << "Equality saturation: starting iteration " << nIters << "\n");

    bytecode->initializeMutableState(bytecodeState);

    {
      TAMAGOYAKI_SCOPED_TIMER("match");
      irModule.walk([&](Operation *op) {
        auto dialect = op->getDialect();
        if (dialect != nullptr &&
            isa<equivalence::EquivalenceDialect>(op->getDialect()))
          return;

        SmallVector<mlir::detail::PDLByteCode::MatchResult, 4> opMatches;

        bytecode->match(op, hashconsRewriter, opMatches, bytecodeState);

        for (auto &match : opMatches) {
          allMatches.push_back({op, std::move(match)});
        }
      });
    }
    {
      TAMAGOYAKI_SCOPED_TIMER("rewrite");
      for (const auto &pm : allMatches) {
        hashconsRewriter.setInsertionPoint(pm.op);
        (void)bytecode->rewrite(hashconsRewriter, pm.matchResult,
                                bytecodeState);
        // Check if node limit exceeded
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

    bool didRebuild = uf.rebuild(hashconsRewriter);
    if (maxNodesExceeded || !didRebuild) {
      break;
    }
  }

  return true;
}

namespace {

struct EmatchSaturatePass
    : public impl::EmatchSaturatePassBase<EmatchSaturatePass> {
  using impl::EmatchSaturatePassBase<
      EmatchSaturatePass>::EmatchSaturatePassBase;

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule;
    ModuleOp irModule;
    OwningOpRef<ModuleOp> parsedPatternsModule;

    if (!patternsFile.empty()) {
      // Parse patterns from external file; the input module is the IR module.
      irModule = module;
      parsedPatternsModule =
          parseSourceFile<ModuleOp>(patternsFile, module.getContext());
      if (!parsedPatternsModule) {
        emitError(module.getLoc())
            << "failed to parse patterns file: " << patternsFile;
        return signalPassFailure();
      }
      patternsModule = parsedPatternsModule.release();
    } else {
      patternsModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "patterns"));
      irModule = module.lookupSymbol<ModuleOp>(
          StringAttr::get(module->getContext(), "ir"));

      if (!patternsModule || !irModule)
        return;
    }

    convertEmatchOpsToApplyRewrites(patternsModule);

    patternsModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternsModule);

    runSaturation(module.getContext(), std::move(pdlPattern), irModule,
                  maxIters, maxNodes);
  }
};

struct EmatchSaturateBenchmarkPass
    : public impl::EmatchSaturateBenchmarkPassBase<
          EmatchSaturateBenchmarkPass> {
  using impl::EmatchSaturateBenchmarkPassBase<
      EmatchSaturateBenchmarkPass>::EmatchSaturateBenchmarkPassBase;

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternsModule || !irModule)
      return;

    convertEmatchOpsToApplyRewrites(patternsModule);

    auto totalStartTime = std::chrono::high_resolution_clock::now();

    for (int run = 0; run < numRuns; ++run) {
      LLVM_DEBUG(llvm::dbgs()
                 << "Benchmark run " << (run + 1) << "/" << numRuns << "\n");

      auto startTime = std::chrono::high_resolution_clock::now();

      OwningOpRef<ModuleOp> irClone = irModule.clone();
      OwningOpRef<ModuleOp> patternClone = patternsModule.clone();

      patternClone.get().getOperation()->remove();
      PDLPatternModule pdlPattern(patternClone.release());

      runSaturation(module.getContext(), std::move(pdlPattern), irClone.get(),
                    maxIters, 0);

      auto endTime = std::chrono::high_resolution_clock::now();
      auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
          endTime - startTime);
      LLVM_DEBUG(llvm::dbgs() << "Run " << (run + 1) << " took "
                              << duration.count() << " µs\n");
    }

    auto totalEndTime = std::chrono::high_resolution_clock::now();
    auto totalDuration = std::chrono::duration_cast<std::chrono::microseconds>(
        totalEndTime - totalStartTime);
    LLVM_DEBUG(llvm::dbgs()
               << "EmatchSaturateBenchmarkPass total: " << totalDuration.count()
               << " µs for " << numRuns << " runs\n");
  }
};

struct ApplyPDLInterpPass
    : public impl::ApplyPDLInterpPassBase<ApplyPDLInterpPass> {
  using impl::ApplyPDLInterpPassBase<
      ApplyPDLInterpPass>::ApplyPDLInterpPassBase;

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternsModule || !irModule)
      return;

    patternsModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternsModule);

    RewritePatternSet patternList(module->getContext());
    patternList.add(std::move(pdlPattern));

    if (failed(applyPatternsGreedily(irModule.getBodyRegion(),
                                     std::move(patternList))))
      signalPassFailure();
  }
};

struct ConvertEmatchToPDLInterpPass
    : public impl::ConvertEmatchToPDLInterpPassBase<
          ConvertEmatchToPDLInterpPass> {
  using impl::ConvertEmatchToPDLInterpPassBase<
      ConvertEmatchToPDLInterpPass>::ConvertEmatchToPDLInterpPassBase;

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));

    if (!patternsModule)
      return;

    convertEmatchOpsToApplyRewrites(patternsModule);
  }
};
} // namespace
} // namespace mlir::ematch
