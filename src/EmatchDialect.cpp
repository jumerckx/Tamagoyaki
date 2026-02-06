//===- EmatchDialect.cpp - Ematch dialect -----*- C++ -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "EmatchDialect.h"
#include "EmatchUtils.h"

#include "EquivalenceDialect.h"
#include "Utils/ClassOpUnionFind.h"
#include "Utils/HashConsPatternRewriter.h"
#include "Utils/MutableScopedHashTable.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/Operation.h"
// IWYU pragma: no_include "mlir/IR/PDLPatternMatch.h.inc"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Rewrite/FrozenRewritePatternSet.h"
#include "mlir/Rewrite/PatternApplicator.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <chrono>
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
#include "EmatchPasses.h.inc"

namespace {

struct PendingMatch {
  Operation *op;
  mlir::detail::PDLByteCode::MatchResult matchResult;
};

} // namespace

/// Run equality saturation on the given IR module using the provided pattern
/// module. The patternModule is consumed (removed from parent).
/// Returns true on success.
bool runSaturation(MLIRContext *ctx, ModuleOp patternModule, ModuleOp irModule,
                   int maxIters) {
  RewritePatternSet patternList(ctx);

  patternModule.getOperation()->remove();
  PDLPatternModule pdlPattern(patternModule);

  ClassOpUnionFind uf{};
  HashConsPatternRewriter hashconsRewriter(ctx);

  irModule.walk([&](Operation *e) {
    equivalence::GraphOp graph = llvm::dyn_cast<equivalence::GraphOp>(*e);
    if (!graph) {
      return;
    }
    Region *region = &(graph.getBody());
    auto scope = hashconsRewriter.createRootScope(region);

    graph->walk([&scope](Operation *op) {
      if (dyn_cast<equivalence::ClassOp>(*op)) {
        return;
      }
      scope->insert(op, op);
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
          LLVM_DEBUG(llvm::dbgs()
                     << "deduplicating operation: " << *op << "\n");
          assert(existing != op);
          rewriter.eraseOp(op);
          return existing;
        }
        LLVM_DEBUG(llvm::dbgs()
                   << "no duplicate, inserting into hashcons: " << *op << "\n");
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

  do {
    nIters++;
    if (nIters > maxIters) {
      break;
    }
    LLVM_DEBUG(llvm::dbgs()
               << "Equality saturation: starting iteration " << nIters << "\n");

    bytecode->initializeMutableState(bytecodeState);

    int i = 0;
    irModule.walk([&](Operation *op) {
      auto dialect = op->getDialect();
      if (dialect != nullptr &&
          isa<equivalence::EquivalenceDialect>(op->getDialect()))
        return;

      SmallVector<mlir::detail::PDLByteCode::MatchResult, 4> opMatches;

      bytecode->match(op, hashconsRewriter, opMatches, bytecodeState);

      for (auto &match : opMatches) {
        allMatches.push_back({op, std::move(match)});

        i += 1;
        LLVM_DEBUG({
          llvm::dbgs() << "Recording rewrite " << i << " at root " << *op
                       << "\n";
        });
      }
    });

    i = 0;
    for (const auto &pm : allMatches) {
      hashconsRewriter.setInsertionPoint(pm.op);
      i += 1;
      LLVM_DEBUG({ llvm::dbgs() << "Applying rewrite " << i << "\n"; });

      (void)bytecode->rewrite(hashconsRewriter, pm.matchResult, bytecodeState);
    }
    allMatches.clear();
    bytecodeState.cleanupAfterMatchAndRewrite();
  } while (uf.rebuild(hashconsRewriter));

  return true;
}

namespace {

struct EmatchSaturatePass
    : public impl::EmatchSaturatePassBase<EmatchSaturatePass> {
  using impl::EmatchSaturatePassBase<
      EmatchSaturatePass>::EmatchSaturatePassBase;

  EmatchSaturatePass() = default;
  EmatchSaturatePass(const EmatchSaturatePass &pass)
      : EmatchSaturatePassBase(pass) {}

  Option<int> maxIters{
      *this, "max-iters",
      llvm::cl::desc("Maximum number of iterations before equality saturation "
                     "times out."),
      llvm::cl::init(4)};

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    auto startTime = std::chrono::high_resolution_clock::now();

    ModuleOp module = getOperation();

    ModuleOp patternModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternModule || !irModule)
      return;

    runSaturation(module.getContext(), patternModule, irModule, maxIters);

    auto endTime = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
        endTime - startTime);
    LLVM_DEBUG(llvm::dbgs()
               << "EmatchSaturatePass took " << duration.count() << " µs\n");
  }
};

struct EmatchSaturateBenchmarkPass
    : public impl::EmatchSaturateBenchmarkPassBase<
          EmatchSaturateBenchmarkPass> {
  using impl::EmatchSaturateBenchmarkPassBase<
      EmatchSaturateBenchmarkPass>::EmatchSaturateBenchmarkPassBase;

  EmatchSaturateBenchmarkPass() = default;
  EmatchSaturateBenchmarkPass(const EmatchSaturateBenchmarkPass &pass)
      : EmatchSaturateBenchmarkPassBase(pass) {}

  Option<int> numRuns{
      *this, "num-runs",
      llvm::cl::desc("Number of times to run equality saturation."),
      llvm::cl::init(10)};

  Option<int> maxIters{
      *this, "max-iters",
      llvm::cl::desc("Maximum number of iterations before equality saturation "
                     "times out."),
      llvm::cl::init(4)};

  void getDependentDialects(DialectRegistry &registry) const override {
    registry.insert<mlir::pdl_interp::PDLInterpDialect>();
  }

  void runOnOperation() final {
    ModuleOp module = getOperation();

    ModuleOp patternModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "patterns"));
    ModuleOp irModule = module.lookupSymbol<ModuleOp>(
        StringAttr::get(module->getContext(), "ir"));

    if (!patternModule || !irModule)
      return;

    auto totalStartTime = std::chrono::high_resolution_clock::now();

    for (int run = 0; run < numRuns; ++run) {
      LLVM_DEBUG(llvm::dbgs()
                 << "Benchmark run " << (run + 1) << "/" << numRuns << "\n");

      auto startTime = std::chrono::high_resolution_clock::now();

      OwningOpRef<ModuleOp> irClone = irModule.clone();
      OwningOpRef<ModuleOp> patternClone = patternModule.clone();

      runSaturation(module.getContext(), patternClone.release(), irClone.get(),
                    maxIters);

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
} // namespace
} // namespace mlir::ematch
