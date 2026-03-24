//===- MultiMatcherPDLByteCode.cpp - Multi-matcher bytecode ---------------===//

#include "Utils/MultiMatcherPDLByteCode.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OperationSupport.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Support/Debug.h"
#include <cassert>
#include <memory>
#include <optional>
#include <utility>

#define DEBUG_TYPE "pdl-multi-matcher"

using namespace mlir;
using namespace mlir::detail;

//===----------------------------------------------------------------------===//
// Helpers
//===----------------------------------------------------------------------===//

/// Deep-copy a StringMap<std::function<...>>.
template <typename FnT>
static llvm::StringMap<FnT> copyFnMap(const llvm::StringMap<FnT> &src) {
  llvm::StringMap<FnT> dst;
  for (const auto &entry : src)
    dst.try_emplace(entry.getKey(), entry.getValue());
  return dst;
}

//===----------------------------------------------------------------------===//
// MultiMatcherMutableState
//===----------------------------------------------------------------------===//

void MultiMatcherMutableState::cleanupAfterMatchAndRewrite() {
  for (auto &s : states)
    s.cleanupAfterMatchAndRewrite();
}

//===----------------------------------------------------------------------===//
// MultiMatcherPDLByteCode
//===----------------------------------------------------------------------===//

MultiMatcherPDLByteCode::MultiMatcherPDLByteCode(
    ModuleOp module, SmallVector<std::unique_ptr<PDLPatternConfigSet>> configs,
    const DenseMap<Operation *, PDLPatternConfigSet *> &configMap,
    const llvm::StringMap<PDLConstraintFunction> &constraintFns,
    const llvm::StringMap<PDLRewriteFunction> &rewriteFns)
    : ownedConfigs(std::move(configs)) {

  // Locate the shared rewriter module.
  ModuleOp rewriterModule = module.lookupSymbol<ModuleOp>(
      pdl_interp::PDLInterpDialect::getRewriterModuleName());
  assert(rewriterModule && "missing rewriter module");

  // Collect every top-level pdl_interp.func in the root module (these are the
  // matchers; rewriter funcs live inside the nested rewriter module).
  SmallVector<pdl_interp::FuncOp> matcherFuncs;
  for (Operation &op : module.getBody()->getOperations())
    if (auto func = dyn_cast<pdl_interp::FuncOp>(&op))
      matcherFuncs.push_back(func);
  assert(!matcherFuncs.empty() && "expected at least one matcher function");

  LLVM_DEBUG(llvm::dbgs() << "MultiMatcherPDLByteCode: building "
                          << matcherFuncs.size() << " matcher(s)\n");

  // Build a single temporary module with the rewriter module cloned once.
  // Each matcher func will be temporarily moved in and out of this module
  // to construct its PDLByteCode, avoiding N clones of the rewriter module.
  MLIRContext *ctx = module.getContext();
  OwningOpRef<ModuleOp> tempModule = ModuleOp::create(module.getLoc());
  {
    OpBuilder builder(ctx);
    builder.setInsertionPointToEnd(tempModule->getBody());
    builder.clone(*rewriterModule.getOperation());
  }

  StringRef canonicalName =
      pdl_interp::PDLInterpDialect::getMatcherFunctionName();

  // Build one PDLByteCode per matcher.
  for (auto [idx, matcherFunc] : llvm::enumerate(matcherFuncs)) {
    // Save the original name so we can restore it after.
    StringRef origName = matcherFunc.getName();

    // Rename to the canonical name and move into the temp module.
    matcherFunc.setName(canonicalName);
    matcherFunc.getOperation()->moveBefore(tempModule->getBody(),
                                           tempModule->getBody()->begin());

    // --- copy the external function tables (PDLByteCode moves from them) ---
    auto localConstraints = copyFnMap(constraintFns);
    auto localRewrites = copyFnMap(rewriteFns);

    // Config lifetime is managed by ownedConfigs; pass an empty vector.
    SmallVector<std::unique_ptr<PDLPatternConfigSet>> noConfigs;

    auto bytecode = std::make_unique<PDLByteCode>(
        *tempModule, std::move(noConfigs), configMap,
        std::move(localConstraints), std::move(localRewrites));

    // Move the matcher back to the original module and restore its name.
    matcherFunc.getOperation()->moveBefore(module.getBody(),
                                           module.getBody()->end());
    matcherFunc.setName(origName);

    // --- populate the dispatch index ---
    for (const PDLByteCodePattern &pat : bytecode->getPatterns()) {
      if (std::optional<OperationName> rootKind = pat.getRootKind())
        kindToMatchers[*rootKind].push_back(idx);
      else
        anyKindMatchers.push_back(idx);
    }

    MatcherEntry entry;
    entry.bytecode = std::move(bytecode);
    matchers.push_back(std::move(entry));
  }

  // Deduplicate dispatch lists (a matcher with N patterns of the same root
  // kind would otherwise appear N times).
  auto dedup = [](SmallVector<unsigned> &v) {
    llvm::sort(v);
    v.erase(llvm::unique(v), v.end());
  };
  for (auto &[name, indices] : kindToMatchers)
    dedup(indices);
  dedup(anyKindMatchers);
}

void MultiMatcherPDLByteCode::initializeMutableState(
    MultiMatcherMutableState &state) const {
  state.states.resize(matchers.size());
  for (auto [i, entry] : llvm::enumerate(matchers))
    entry.bytecode->initializeMutableState(state.states[i]);
}

void MultiMatcherPDLByteCode::match(Operation *op, PatternRewriter &rewriter,
                                    SmallVectorImpl<MatchResult> &matches,
                                    MultiMatcherMutableState &state) const {

  // Determine which matchers are relevant for this op.
  SmallVector<unsigned> toRun(anyKindMatchers);
  auto it = kindToMatchers.find(op->getName());
  if (it != kindToMatchers.end())
    toRun.append(it->second.begin(), it->second.end());

  // A matcher may appear in both lists; deduplicate.
  llvm::sort(toRun);
  toRun.erase(llvm::unique(toRun), toRun.end());

  // Execute each relevant matcher and collect results.
  for (unsigned idx : toRun) {
    SmallVector<PDLByteCode::MatchResult> local;
    matchers[idx].bytecode->match(op, rewriter, local, state.states[idx]);
    for (auto &m : local)
      matches.emplace_back(idx, std::move(m));
  }

  // Global sort by benefit (descending).
  llvm::stable_sort(matches,
                    [](const MatchResult &lhs, const MatchResult &rhs) {
                      return lhs.result.benefit > rhs.result.benefit;
                    });
}

LogicalResult
MultiMatcherPDLByteCode::rewrite(PatternRewriter &rewriter,
                                 const MatchResult &match,
                                 MultiMatcherMutableState &state) const {
  return matchers[match.matcherIndex].bytecode->rewrite(
      rewriter, match.result, state.states[match.matcherIndex]);
}

SmallVector<const PDLByteCodePattern *>
MultiMatcherPDLByteCode::getAllPatterns() const {
  SmallVector<const PDLByteCodePattern *> result;
  for (const auto &entry : matchers)
    for (const auto &pat : entry.bytecode->getPatterns())
      result.push_back(&pat);
  return result;
}
