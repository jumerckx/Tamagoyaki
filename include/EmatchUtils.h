#ifndef EMATCH_UTILS_H
#define EMATCH_UTILS_H

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/PatternMatch.h"

namespace mlir::ematch {

/// Convert all ematch operations in the given module to their corresponding
/// pdl_interp.apply_rewrite operations. Each ematch op (get_class_vals,
/// get_class_representative, get_class_result, get_class_results, union, dedup)
/// is replaced by a pdl_interp.apply_rewrite with the same name and signature.
void convertEmatchOpsToApplyRewrites(ModuleOp module);

/// Convert the matcher-side ematch operations in the given module to their
/// corresponding match.apply_native_rewrite operations. The e-class
/// navigation helpers (get_class_vals, get_class_representative,
/// get_class_result, get_class_results) are replaced by a
/// match.apply_native_rewrite with the same name and signature, so a
/// `match.matcher` that navigates equivalence classes can be lowered by
/// MatchToPDLInterp. The rewriter-side ops (union, dedup) are left untouched;
/// use convertEmatchOpsToApplyRewrites for those.
void convertEmatchOpsToMatchRewrites(ModuleOp module);

/// Run equality saturation on the given IR module using the provided PDL
/// pattern module. Returns true on success.
bool runSaturation(MLIRContext *ctx, PDLPatternModule pdlPattern,
                   ModuleOp irModule, int maxIters, int maxNodes,
                   RewriterBase::Listener *listener = nullptr,
                   bool eagerRewrite = true);

} // namespace mlir::ematch

#endif // EMATCH_UTILS_H
