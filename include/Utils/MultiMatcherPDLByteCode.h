//===- MultiMatcherPDLByteCode.h - Multi-matcher bytecode -------*- C++ -*-===//
//
// Wraps PDLByteCode to support multiple top-level pdl_interp.func matchers
// sharing a common rewriter module, without modifying the original ByteCode
// implementation.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_REWRITE_MULTIMATCHERBYTECODE_H_
#define MLIR_REWRITE_MULTIMATCHERBYTECODE_H_

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/OperationSupport.h"
#include "mlir/IR/OwningOpRef.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/Bytecode.h"
#include "llvm/ADT/StringMap.h"
#include <memory>

namespace mlir {
namespace detail {

//===----------------------------------------------------------------------===//
// MultiMatcherMutableState
//===----------------------------------------------------------------------===//

/// Mutable state for a multi-matcher bytecode instance.  Holds one
/// PDLByteCodeMutableState per individual matcher.
class MultiMatcherMutableState {
public:
  void cleanupAfterMatchAndRewrite();

private:
  friend class MultiMatcherPDLByteCode;
  SmallVector<PDLByteCodeMutableState> states;
};

//===----------------------------------------------------------------------===//
// MultiMatcherPDLByteCode
//===----------------------------------------------------------------------===//

class MultiMatcherPDLByteCode {
public:
  /// A match result that also tracks which internal matcher produced it.
  struct MatchResult {
    MatchResult(unsigned matcherIndex, PDLByteCode::MatchResult result)
        : matcherIndex(matcherIndex), result(std::move(result)) {}
    MatchResult(MatchResult &&) = default;
    MatchResult &operator=(MatchResult &&) = default;

    /// Index of the matcher that produced this result.
    unsigned matcherIndex;
    /// The underlying single-matcher result (move-only).
    PDLByteCode::MatchResult result;
  };

  /// Construct from a module containing one or more top-level
  /// `pdl_interp::FuncOp` matchers and a nested rewriter module with the
  /// standard name.  The interface mirrors `PDLByteCode` exactly.
  MultiMatcherPDLByteCode(
      ModuleOp module,
      SmallVector<std::unique_ptr<PDLPatternConfigSet>> configs,
      const DenseMap<Operation *, PDLPatternConfigSet *> &configMap,
      llvm::StringMap<PDLConstraintFunction> constraintFns,
      llvm::StringMap<PDLRewriteFunction> rewriteFns);

  /// Initialise the mutable state so that it can be used with this instance.
  void initializeMutableState(MultiMatcherMutableState &state) const;

  /// Run every relevant matcher against `op` and collect results in
  /// `matches`, sorted by benefit (descending).
  void match(Operation *op, PatternRewriter &rewriter,
             SmallVectorImpl<MatchResult> &matches,
             MultiMatcherMutableState &state) const;

  /// Execute the rewrite for a previously matched result.
  LogicalResult rewrite(PatternRewriter &rewriter, const MatchResult &match,
                        MultiMatcherMutableState &state) const;

  /// Return every pattern across all matchers.
  SmallVector<const PDLByteCodePattern *> getAllPatterns() const;

  /// Return the number of individual matchers.
  unsigned getNumMatchers() const { return matchers.size(); }

  /// Access the patterns of a single matcher.
  ArrayRef<PDLByteCodePattern> getPatterns(unsigned matcherIndex) const {
    return matchers[matcherIndex].bytecode->getPatterns();
  }

private:
  /// Owned config sets – lifetime must cover all individual PDLByteCodes.
  SmallVector<std::unique_ptr<PDLPatternConfigSet>> ownedConfigs;

  struct MatcherEntry {
    /// The bytecode for this single matcher.
    std::unique_ptr<PDLByteCode> bytecode;
    /// Keeps the cloned module alive (context-interned data is safe without
    /// it, but this is a low-cost safety net).
    OwningOpRef<ModuleOp> clonedModule;
  };
  SmallVector<MatcherEntry> matchers;

  /// Quick dispatch: OperationName → indices into `matchers`.
  DenseMap<OperationName, SmallVector<unsigned>> kindToMatchers;
  /// Matchers that use MatchAnyOpTypeTag (must run for every op).
  SmallVector<unsigned> anyKindMatchers;
};

} // namespace detail
} // namespace mlir

#endif // MLIR_REWRITE_MULTIMATCHERBYTECODE_H_
