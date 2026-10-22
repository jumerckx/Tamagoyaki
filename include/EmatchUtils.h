#ifndef EMATCH_UTILS_H
#define EMATCH_UTILS_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/PatternMatch.h"
#include <mlir/Support/LLVM.h>

namespace mlir::ematch {

/// Convert all ematch operations in the given module to their corresponding
/// pdl_interp.apply_rewrite operations. Each ematch op (get_class_vals,
/// get_class_representative, get_class_result, get_class_results, union, dedup)
/// is replaced by a pdl_interp.apply_rewrite with the same name and signature.
void convertEmatchOpsToApplyRewrites(ModuleOp module);

/// Rewrite the `match.matcher` and `match.rewriter` ops in the given module, as
/// produced by convert-pdl-to-match, so that they match and rewrite over the
/// e-classes of an e-graph. Expects one matcher per pattern, i.e. it runs
/// before the matchers are combined.
void ematchifyMatchPatterns(ModuleOp module);

/// Lower the `pdl.pattern` ops in the given module to e-matching `pdl_interp`
/// by going through the match dialect: convert-pdl-to-match, ematchify,
/// match-combine-matchers (with deferred loops), convert-match-to-pdl-interp.
LogicalResult convertPDLToEmatchPDLInterp(ModuleOp module);

/// Run equality saturation on the given IR module using the provided PDL
/// pattern module. Returns true on success.
bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener = nullptr,
                   bool eagerRewrite = true);

} // namespace mlir::ematch

#endif // EMATCH_UTILS_H
