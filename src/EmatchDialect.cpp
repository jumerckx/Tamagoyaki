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
#include "EquivalenceUtils.h"
#include "Utils/ClassOpUnionFind.h"
#include "Utils/HashConsPatternRewriter.h"
#include "Utils/MutableScopedHashTable.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Diagnostics.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Parser/Parser.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Rewrite/PatternApplicator.h"
#include "mlir/Support/LLVM.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
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

void mlir::ematch::EmatchDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "EmatchOps.cpp.inc"

      >();
}

mlir::Type
mlir::ematch::EmatchDialect::parseType(mlir::DialectAsmParser &parser) const {
  StringRef typeName;
  if (parser.parseKeyword(&typeName))
    return Type();
  return {};
}

void mlir::ematch::EmatchDialect::printType(mlir::Type type,
                                            mlir::DialectAsmPrinter &os) const {
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
#define GEN_PASS_DEF_EQUIVALENCEGRAPHCONTAINSPASS
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

/// Resolve the patterns and IR modules for a pass. When `patternsFile` is
/// non-empty, the patterns are parsed from that file and the input `module`
/// itself is used as the IR module; otherwise the `@patterns` and `@ir`
/// submodules of `module` are used. `parsedPatternsModule` retains ownership of
/// a module parsed from file until it is handed off to a PDLPatternModule.
///
/// Returns failure if parsing fails, or if the submodules are missing. When the
/// submodules are missing and `emitErrorIfMissing` is false, failure is
/// returned without emitting a diagnostic (silent skip).
static LogicalResult
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

/// Register the e-class traversal helpers used by the matcher bytecode to walk
/// the e-graph (get_class_vals, get_class_representative, ...).
static void registerEmatchRewrites(PDLPatternModule &pdlPattern) {
  pdlPattern.registerRewriteFunction("get_class_vals", getClassVals);
  pdlPattern.registerRewriteFunction("get_class_representative",
                                     getClassRepresentative);
  pdlPattern.registerRewriteFunction("get_class_result", getClassResult);
  pdlPattern.registerRewriteFunction("get_class_results", getClassResults);
}

/// Operations in the equivalence dialect are skipped when walking the IR for
/// matching: they form the e-graph scaffolding, not user payload.
static bool isEquivalenceDialectOp(Operation *op) {
  Dialect *dialect = op->getDialect();
  return dialect != nullptr && isa<equivalence::EquivalenceDialect>(dialect);
}

/// Run equality saturation on the given IR module using the provided pattern
/// module. The patternsModule is consumed (removed from parent).
/// Returns true on success.
bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener, bool eagerRewrite) {
  TAMAGOYAKI_SCOPED_TIMER("runSaturation");
  RewritePatternSet patternList(ctx);

  ClassOpUnionFind uf{};
  HashConsPatternRewriter hashconsRewriter(ctx);
  hashconsRewriter.setUnionFind(&uf);
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

//===----------------------------------------------------------------------===//
// equivalence-graph-contains support
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
  ReplaceRecordMatchPattern(MLIRContext *context,
                            llvm::StringSet<> &patterns)
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
static void lowerIsArgOps(ModuleOp module,
                          llvm::DenseSet<uint32_t> &indices) {
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
static llvm::StringSet<> replaceRecordMatches(ModuleOp module) {
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

namespace {

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
          name, [index](PatternRewriter &rw, PDLResultList &,
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
          [&results, &yieldClasses, pattern](
              PatternRewriter &rw, PDLResultList &,
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
