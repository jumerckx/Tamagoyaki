//===- EmatchPasses.cpp - Ematch pass drivers --------------------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The ematch dialect's pass drivers: equality-saturation passes, the
// ematch->pdl_interp conversion passes, and the equivalence-graph-contains
// pass. The heavy lifting (lowering, saturation) lives in EmatchTransforms.cpp;
// this file wires those into passes and additionally holds the
// graph-contains-specific lowering patterns, which are used only here.
//
//===----------------------------------------------------------------------===//

#include "EmatchDetail.h"
#include "EmatchDialect.h"
#include "EmatchUtils.h"
#include "EquivalenceDialect.h"
#include "EquivalenceUtils.h"
#include "TamagoyakiTiming.h"
#include "Utils/ClassOpUtils.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
#include <chrono>
#include <cstdint>
#include <llvm/ADT/STLExtras.h>
#include <map>
#include <mlir/IR/TypeRange.h>
#include <string>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

namespace mlir::ematch {

#define GEN_PASS_DEF_EMATCHSATURATEPASS
#define GEN_PASS_DEF_EMATCHSATURATEBENCHMARKPASS
#define GEN_PASS_DEF_CONVERTEMATCHTOPDLINTERPPASS
#define GEN_PASS_DEF_APPLYPDLINTERPPASS
#define GEN_PASS_DEF_EQUIVALENCEGRAPHCONTAINSPASS
#include "EmatchPasses.h.inc"

namespace {

/// Resolve the patterns and IR modules for a pass. When `patternsFile` is
/// non-empty, the patterns are parsed from that file and the input `module`
/// itself is used as the IR module; otherwise the `@patterns` and `@ir`
/// submodules of `module` are used. `parsedPatternsModule` retains ownership of
/// a module parsed from file until it is handed off to a PDLPatternModule.
///
/// Returns failure if parsing fails, or if the submodules are missing. When the
/// submodules are missing and `emitErrorIfMissing` is false, failure is
/// returned without emitting a diagnostic (silent skip).
LogicalResult
resolvePatternAndIrModules(ModuleOp module, StringRef patternsFile,
                           bool emitErrorIfMissing,
                           OwningOpRef<ModuleOp> &parsedPatternsModule,
                           ModuleOp &patternsModule, ModuleOp &irModule) {
  MLIRContext *ctx = module.getContext();
  if (!patternsFile.empty()) {
    // Parse patterns from external file; the input module is the IR module.
    irModule = module;
    parsedPatternsModule = parseSourceFile<ModuleOp>(patternsFile, ctx);
    if (!parsedPatternsModule) {
      emitError(module.getLoc())
          << "failed to parse patterns file: " << patternsFile;
      return failure();
    }
    patternsModule = parsedPatternsModule.release();
    return success();
  }

  patternsModule =
      module.lookupSymbol<ModuleOp>(StringAttr::get(ctx, "patterns"));
  irModule = module.lookupSymbol<ModuleOp>(StringAttr::get(ctx, "ir"));
  if (!patternsModule || !irModule) {
    if (emitErrorIfMissing)
      emitError(module.getLoc())
          << "expected @patterns and @ir submodules, or a patterns-file";
    return failure();
  }
  return success();
}

//===----------------------------------------------------------------------===//
// equivalence-graph-contains lowering patterns
//===----------------------------------------------------------------------===//

/// Lower an `ematch.is_arg` to a `pdl_interp.apply_constraint` invoking a
/// constraint named "is_arg_<index>". Each index that appears is recorded in
/// `indices` so the pass can register one constraint per index.
struct LowerIsArgPattern : public OpRewritePattern<IsArgOp> {
  LowerIsArgPattern(MLIRContext *context, llvm::DenseSet<uint32_t> &indices)
      : OpRewritePattern<IsArgOp>(context), indices(indices) {}

  LogicalResult matchAndRewrite(IsArgOp op,
                                PatternRewriter &rewriter) const final {
    uint32_t index = op.getIndex();
    indices.insert(index);
    std::string name = ("is_arg_" + Twine(index)).str();
    rewriter.replaceOpWithNewOp<pdl_interp::ApplyConstraintOp>(
        op, /*results=*/TypeRange{}, name, ValueRange{op.getValue()},
        /*isNegated=*/false, op.getTrueDest(), op.getFalseDest());
    return success();
  }

  llvm::DenseSet<uint32_t> &indices;
};

/// Replace a `pdl_interp.record_match` with a `pdl_interp.apply_constraint`
/// that records the match for the equivalence-graph-contains pass. The
/// constraint is named "record_match_<pattern>" and receives the matcher root
/// operation followed by the original record_match inputs. Both successors
/// branch to the original destination so matching keeps discovering further
/// matches. Each pattern (leaf rewriter symbol) that appears is collected in
/// `patterns`.
struct ReplaceRecordMatchPattern
    : public OpRewritePattern<pdl_interp::RecordMatchOp> {
  ReplaceRecordMatchPattern(MLIRContext *context, llvm::StringSet<> &patterns)
      : OpRewritePattern<pdl_interp::RecordMatchOp>(context),
        patterns(patterns) {}

  LogicalResult matchAndRewrite(pdl_interp::RecordMatchOp op,
                                PatternRewriter &rewriter) const final {
    std::string pattern = op.getRewriter().getLeafReference().getValue().str();
    std::string name = "record_match_" + pattern;
    patterns.insert(pattern);

    auto matcher = op->getParentOfType<pdl_interp::FuncOp>();
    assert(matcher && matcher.getBody().front().getNumArguments() >= 1 &&
           "record_match must be inside a matcher with a root operation arg");
    Value root = matcher.getBody().front().getArgument(0);

    SmallVector<Value> args;
    args.push_back(root);
    llvm::append_range(args, op.getInputs());

    rewriter.replaceOpWithNewOp<pdl_interp::ApplyConstraintOp>(
        op, /*results=*/TypeRange{}, name, args,
        /*isNegated=*/false, op.getDest(), op.getDest());
    return success();
  }

  llvm::StringSet<> &patterns;
};

/// Lower every `ematch.is_arg` in the module to a `pdl_interp.apply_constraint`
/// invoking a constraint named "is_arg_<index>". The set of indices that appear
/// is collected so the pass can register one constraint per index.
void lowerIsArgOps(ModuleOp module, llvm::DenseSet<uint32_t> &indices) {
  TAMAGOYAKI_SCOPED_TIMER("lowerIsArgOps");
  RewritePatternSet patterns(module.getContext());
  patterns.add<LowerIsArgPattern>(module.getContext(), indices);
  GreedyRewriteConfig config;
  config.enableConstantCSE(false);
  config.enableFolding(false);
  (void)applyPatternsGreedily(module, std::move(patterns), config);
}

/// Replace every `pdl_interp.record_match` in the module with a
/// `pdl_interp.apply_constraint` that records the match for the
/// equivalence-graph-contains pass.
/// Returns the set of patterns (leaf rewriter symbols) that were recorded.
llvm::StringSet<> replaceRecordMatches(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("replaceRecordMatches");
  llvm::StringSet<> recordedPatterns;
  RewritePatternSet patterns(module.getContext());
  patterns.add<ReplaceRecordMatchPattern>(module.getContext(),
                                          recordedPatterns);
  GreedyRewriteConfig config;
  config.enableConstantCSE(false);
  config.enableFolding(false);
  (void)applyPatternsGreedily(module, std::move(patterns), config);
  return recordedPatterns;
}

//===----------------------------------------------------------------------===//
// Passes
//===----------------------------------------------------------------------===//

struct EmatchSaturatePass
    : public impl::EmatchSaturatePassBase<EmatchSaturatePass> {
  using impl::EmatchSaturatePassBase<
      EmatchSaturatePass>::EmatchSaturatePassBase;

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule;
    ModuleOp irModule;
    OwningOpRef<ModuleOp> parsedPatternsModule;

    if (failed(resolvePatternAndIrModules(
            module, patternsFile, /*emitErrorIfMissing=*/false,
            parsedPatternsModule, patternsModule, irModule))) {
      // A parse failure already emitted a diagnostic; missing submodules are a
      // silent skip.
      if (!patternsFile.empty())
        signalPassFailure();
      return;
    }

    convertEmatchOpsToApplyRewrites(patternsModule);

    patternsModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternsModule);

    // Normalize the input e-graph before saturating. The IR may arrive with the
    // class normal form broken (e.g. a prior canonicalization left a class
    // result floating into a class operand); saturation assumes the invariants
    // hold, so restore them to a fixpoint first.
    if (failed(equivalence::restoreClassInvariants(irModule))) {
      signalPassFailure();
      return;
    }

    runSaturation(module.getContext(), std::move(pdlPattern), irModule,
                  maxIters, maxNodes, /*listener=*/nullptr, eagerRewrite);
  }
};

struct EmatchSaturateBenchmarkPass
    : public impl::EmatchSaturateBenchmarkPassBase<
          EmatchSaturateBenchmarkPass> {
  using impl::EmatchSaturateBenchmarkPassBase<
      EmatchSaturateBenchmarkPass>::EmatchSaturateBenchmarkPassBase;

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
      [[maybe_unused]] auto duration =
          std::chrono::duration_cast<std::chrono::microseconds>(endTime -
                                                                startTime);
      LLVM_DEBUG(llvm::dbgs() << "Run " << (run + 1) << " took "
                              << duration.count() << " µs\n");
    }

    auto totalEndTime = std::chrono::high_resolution_clock::now();
    [[maybe_unused]] auto totalDuration =
        std::chrono::duration_cast<std::chrono::microseconds>(totalEndTime -
                                                              totalStartTime);
    LLVM_DEBUG(llvm::dbgs()
               << "EmatchSaturateBenchmarkPass total: " << totalDuration.count()
               << " µs for " << numRuns << " runs\n");
  }
};

struct ApplyPDLInterpPass
    : public impl::ApplyPDLInterpPassBase<ApplyPDLInterpPass> {
  using impl::ApplyPDLInterpPassBase<
      ApplyPDLInterpPass>::ApplyPDLInterpPassBase;

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

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternsModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));

    if (!patternsModule)
      return;

    convertEmatchOpsToApplyRewrites(patternsModule);
  }
};

struct EquivalenceGraphContainsPass
    : public impl::EquivalenceGraphContainsPassBase<
          EquivalenceGraphContainsPass> {
  using impl::EquivalenceGraphContainsPassBase<
      EquivalenceGraphContainsPass>::EquivalenceGraphContainsPassBase;

  /// Per-pattern containment result.
  struct PatternResult {
    bool matchedYield = false;
    unsigned totalMatches = 0;
  };

  void runOnOperation() final {
    ModuleOp module = getOperation();
    MLIRContext *ctx = module.getContext();

    ModuleOp patternsModule;
    ModuleOp irModule;
    OwningOpRef<ModuleOp> parsedPatternsModule;

    if (failed(resolvePatternAndIrModules(
            module, patternsFile, /*emitErrorIfMissing=*/true,
            parsedPatternsModule, patternsModule, irModule)))
      return signalPassFailure();

    // Lower the e-class helper ops used by the matcher (get_class_*, ...) to
    // pdl_interp.apply_rewrite.
    convertEmatchOpsToApplyRewrites(patternsModule);

    // Lower ematch.is_arg to recording constraints, and replace record_match
    // with constraints that register matches against the e-graph.
    llvm::DenseSet<uint32_t> argIndices;
    lowerIsArgOps(patternsModule, argIndices);
    llvm::StringSet<> recordedPatterns = replaceRecordMatches(patternsModule);

    // We only match, never rewrite. The PDL bytecode generator still requires a
    // @rewriters module to be present, so keep it but drop its contents (the
    // rewriter functions) so they are not compiled into the bytecode and need
    // not be registered.
    if (auto rewriters = patternsModule.lookupSymbol<ModuleOp>(
            StringAttr::get(ctx, "rewriters"))) {
      for (Operation &op :
           llvm::make_early_inc_range(rewriters.getBodyRegion().front()))
        op.erase();
    }

    // A rewriter is required to drive the bytecode interpreter and the e-class
    // helper functions. None of the helpers mutate the IR here.
    HashConsPatternRewriter rewriter(ctx);

    // Collect the e-class identity of every value returned by an
    // equivalence.yield.
    llvm::DenseSet<Value> yieldClasses;
    irModule.walk([&](equivalence::YieldOp yieldOp) {
      for (Value v : yieldOp.getValues())
        yieldClasses.insert(getClassResult(rewriter, v));
    });

    // Containment results, keyed by pattern. Pre-populate so patterns that are
    // never matched are still reported.
    std::map<std::string, PatternResult> results;
    for (const auto &entry : recordedPatterns)
      results[entry.getKey().str()];

    patternsModule.getOperation()->remove();
    PDLPatternModule pdlPattern(patternsModule);

    // Helper rewrites used by the matcher to traverse e-classes.
    registerEmatchRewrites(pdlPattern);

    // is_arg_<index>: succeed iff the value is (equivalent to) block argument
    // `index` of the enclosing function.
    for (uint32_t index : argIndices) {
      std::string name = ("is_arg_" + Twine(index)).str();
      pdlPattern.registerConstraintFunction(
          name,
          [index](PatternRewriter &rw, PDLResultList &,
                  ArrayRef<PDLValue> args) -> LogicalResult {
            if (args.empty() || !args[0].isa<Value>())
              return failure();
            for (Value cv : getClassVals(rw, args[0].cast<Value>())) {
              if (auto ba = dyn_cast<BlockArgument>(cv))
                if (ba.getArgNumber() == index)
                  return success();
            }
            return failure();
          });
    }

    // record_match_<pattern>: register the match and check whether its root is
    // equivalent to a yielded value.
    for (const auto &entry : recordedPatterns) {
      std::string pattern = entry.getKey().str();
      std::string name = "record_match_" + pattern;
      pdlPattern.registerConstraintFunction(
          name,
          [&results, &yieldClasses,
           pattern](PatternRewriter &rw, PDLResultList &,
                    ArrayRef<PDLValue> args) -> LogicalResult {
            PatternResult &r = results[pattern];
            r.totalMatches++;
            if (!args.empty() && args[0].isa<Operation *>()) {
              Operation *root = args[0].cast<Operation *>();
              for (Value res : root->getResults()) {
                if (yieldClasses.count(getClassResult(rw, res))) {
                  r.matchedYield = true;
                  break;
                }
              }
            }
            return success();
          });
    }

    RewritePatternSet patternList(ctx);
    patternList.add(std::move(pdlPattern));
    FrozenRewritePatternSet frozen(std::move(patternList));

    const auto *bytecode = frozen.getPDLByteCode();
    if (!bytecode) {
      emitError(module.getLoc())
          << "failed to build PDL bytecode from the patterns";
      return signalPassFailure();
    }

    mlir::detail::PDLByteCodeMutableState state;
    bytecode->initializeMutableState(state);

    irModule.walk([&](Operation *op) {
      if (isEquivalenceDialectOp(op))
        return;
      SmallVector<mlir::detail::PDLByteCode::MatchResult> opMatches;
      bytecode->match(op, rewriter, opMatches, state);
    });
    state.cleanupAfterMatchAndRewrite();

    llvm::outs() << "Pattern containment results:\n";
    for (auto &entry : results) {
      const PatternResult &r = entry.second;
      llvm::outs() << "  @" << entry.first << ": "
                   << (r.matchedYield ? "contained" : "not contained") << " ("
                   << r.totalMatches << " match"
                   << (r.totalMatches == 1 ? "" : "es") << ")\n";
    }
  }
};

} // namespace
} // namespace mlir::ematch
