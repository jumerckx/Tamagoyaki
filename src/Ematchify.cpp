//===- Ematchify.cpp - E-matching over the match dialect ---------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements `ematchifyMatchPatterns` and `convertPDLToEmatchPDLInterp`
// declared in EmatchUtils.h: the lowering of `pdl` patterns to `pdl_interp`
// that match and rewrite over the e-classes of an e-graph, going through the
// `match` dialect:
//
//   convert-pdl-to-match -> ematchify -> match-combine-matchers{defer-loops}
//     -> convert-match-to-pdl-interp
//
// The e-class helpers are emitted as `match.apply_native_rewrite` and
// `match.apply_native_constraint` ops named after the ematch ops they stand
// for (get_class_vals, get_class_result, union, dedup, ...). They lower to the
// `pdl_interp.apply_rewrite`/`apply_constraint` ops whose implementations
// runSaturation registers.
//
//===----------------------------------------------------------------------===//

#include "EmatchUtils.h"

#include "TamagoyakiTiming.h"
#include "mlir/Conversion/MatchToPDLInterp/MatchToPDLInterp.h"
#include "mlir/Conversion/PDLToMatch/PDLToMatch.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/Match/Transforms/Passes.h"
#include "mlir/Dialect/PDL/IR/PDLOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include <llvm/ADT/SmallVectorExtras.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/TypeRange.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>

using namespace mlir;

namespace mlir::ematch {

namespace {

bool isValue(Value v) { return isa<pdl::ValueType>(v.getType()); }

bool isValueRange(Value v) {
  auto range = dyn_cast<pdl::RangeType>(v.getType());
  return range && isa<pdl::ValueType>(range.getElementType());
}

/// Create a `match.apply_native_rewrite` calling `name` on `args`.
match::ApplyNativeRewriteOp createNativeRewrite(OpBuilder &builder,
                                                Location loc, StringRef name,
                                                TypeRange resultTypes,
                                                ValueRange args) {
  return match::ApplyNativeRewriteOp::create(builder, loc, resultTypes,
                                             builder.getStringAttr(name), args);
}

/// Map `v` (a value or a range of values) to its e-class result(s) right after
/// `after`, and redirect the uses of `v` to the e-class result(s).
void replaceWithClassResult(OpBuilder &builder, Value v, Operation *after) {
  builder.setInsertionPointAfter(after);
  auto classResult = createNativeRewrite(
      builder, v.getLoc(),
      isValue(v) ? "get_class_result" : "get_class_results", v.getType(), v);
  v.replaceAllUsesExcept(classResult.getResult(0), classResult);
}

/// Return the value an e-class result was computed from, or null if `v` is not
/// produced by get_class_result(s).
Value getClassResultInput(Value v) {
  auto rewrite = v.getDefiningOp<match::ApplyNativeRewriteOp>();
  if (!rewrite || !llvm::is_contained({StringRef("get_class_result"),
                                       StringRef("get_class_results")},
                                      rewrite.getName()))
    return nullptr;
  return rewrite.getArgs().front();
}

void ematchifyMatcher(match::MatcherOp matcher) {
  OpBuilder builder(matcher.getContext());
  Type valueRangeTy =
      pdl::RangeType::get(pdl::ValueType::get(matcher.getContext()));

  // A matched result is mapped to its e-class result, which is what the
  // operands of the e-nodes in the e-graph refer to.
  SmallVector<match::IsNotNullOp> resultUnwraps;
  matcher.walk([&](match::IsNotNullOp op) {
    Value unwrapped = op.getUnwrapped();
    if ((isValue(unwrapped) || isValueRange(unwrapped)) &&
        isa_and_present<match::GetResultOp, match::GetResultsOp>(
            op.getOptionalValue().getDefiningOp()))
      resultUnwraps.push_back(op);
  });
  for (match::IsNotNullOp op : resultUnwraps)
    replaceWithClassResult(builder, op.getUnwrapped(), op);

  // A value is defined by any e-node of its e-class: navigate to the defining
  // op from every member of the class. The navigation and everything after it
  // in its block move into a loop over the class members. The rest of a block
  // only runs once the navigation succeeded, so this existentially quantifies
  // exactly that part of the matcher over the members.
  //
  // The defining op of a value range is still taken from the range itself.
  SmallVector<match::GetDefiningOpOp> definingOps;
  matcher.walk([&](match::GetDefiningOpOp op) {
    if (isValue(op.getValue()))
      definingOps.push_back(op);
  });
  for (match::GetDefiningOpOp op : definingOps) {
    builder.setInsertionPoint(op);
    Value members = createNativeRewrite(builder, op.getLoc(), "get_class_vals",
                                        valueRangeTy, op.getValue())
                        .getResult(0);
    auto loop = match::ForEachOp::create(builder, op.getLoc(), members);
    Block &body = loop.getBody().front();
    Block *block = op->getBlock();
    body.getOperations().splice(body.end(), block->getOperations(),
                                op->getIterator(), block->end());
    op.getValueMutable().assign(loop.getLoopVariable());
  }

  // Two values match if they are in the same e-class.
  SmallVector<match::EqualOp> equalities;
  matcher.walk([&](match::EqualOp op) {
    if (isValue(op.getLhs()))
      equalities.push_back(op);
  });
  for (match::EqualOp op : equalities) {
    builder.setInsertionPoint(op);
    match::ApplyNativeConstraintOp::create(
        builder, op.getLoc(), /*results=*/TypeRange(),
        builder.getStringAttr("are_equivalent"),
        ValueRange{op.getLhs(), op.getRhs()},
        /*isNegated=*/builder.getBoolAttr(false));
    op.erase();
  }

  // The rewriter maps its value arguments back to their e-class result(s)
  // (see ematchifyRewriter): pass the e-class representative of a matched
  // operand, and the matched value itself for an e-class result.
  matcher.walk([&](match::SuccessOp op) {
    builder.setInsertionPoint(op);
    llvm::SmallDenseMap<Value, Value> representatives;
    for (OpOperand &input : op.getInputsMutable()) {
      Value value = input.get();
      if (Value classInput = getClassResultInput(value)) {
        input.set(classInput);
        continue;
      }
      auto unwrap = value.getDefiningOp<match::IsNotNullOp>();
      if (!isValue(value) || !unwrap ||
          !isa_and_present<match::GetOperandOp, match::GetOperandsOp>(
              unwrap.getOptionalValue().getDefiningOp()))
        continue;
      Value &representative = representatives[value];
      if (!representative)
        representative = createNativeRewrite(builder, op.getLoc(),
                                             "get_class_representative",
                                             value.getType(), value)
                             .getResult(0);
      input.set(representative);
    }
  });
}

void ematchifyRewriter(match::RewriterOp rewriter) {
  Block &body = rewriter.getBody().front();
  OpBuilder builder(rewriter.getContext());
  Type valueRangeTy =
      pdl::RangeType::get(pdl::ValueType::get(rewriter.getContext()));
  SmallVector<Operation *> ops =
      llvm::map_to_vector(body, [](Operation &op) { return &op; });

  // The matcher passes e-class representatives (or matched values): use their
  // e-class results so that the created operations refer to e-classes.
  builder.setInsertionPointToStart(&body);
  for (BlockArgument arg : body.getArguments()) {
    if (!isValue(arg) && !isValueRange(arg))
      continue;
    auto classResult = createNativeRewrite(builder, arg.getLoc(),
                                           isValue(arg) ? "get_class_result"
                                                        : "get_class_results",
                                           arg.getType(), arg);
    arg.replaceAllUsesExcept(classResult.getResult(0), classResult);
  }

  // An operation is only added to the e-graph if no equivalent e-node exists.
  auto dedup = [&](Value createdOp) {
    builder.setInsertionPointAfterValue(createdOp);
    auto deduped = createNativeRewrite(builder, createdOp.getLoc(), "dedup",
                                       createdOp.getType(), createdOp);
    createdOp.replaceAllUsesExcept(deduped.getResult(0), deduped);
  };

  for (Operation *op : ops) {
    if (auto create = dyn_cast<match::CreateOperationOp>(op)) {
      dedup(create.getResultOp());
    } else if (auto rewrite = dyn_cast<match::ApplyNativeRewriteOp>(op)) {
      // A native rewrite that creates operations has to return them so that
      // they can be deduplicated.
      for (Value result : rewrite.getResults())
        if (isa<pdl::OperationType>(result.getType()))
          dedup(result);
    } else if (isa<pdl::ResultOp, pdl::ResultsOp>(op)) {
      replaceWithClassResult(builder, op->getResult(0), op);
    } else if (auto replace = dyn_cast<match::ReplaceOp>(op);
               replace && !replace.getReplValues().empty()) {
      // Replacing merges the e-classes instead of mutating the e-graph.
      builder.setInsertionPoint(replace);
      ValueRange replValues = replace.getReplValues();
      Value replacement = replValues.front();
      if (replValues.size() != 1 || !isValueRange(replacement))
        replacement = match::CreateRangeOp::create(builder, replace.getLoc(),
                                                   valueRangeTy, replValues);
      createNativeRewrite(builder, replace.getLoc(), "union",
                          /*resultTypes=*/TypeRange(),
                          {replace.getInputOp(), replacement});
      replace.erase();
    } else if (isa<match::EraseOp, match::ReplaceOp>(op)) {
      // Nothing is ever removed from an e-graph.
      op->erase();
    }
  }
}

} // namespace

void ematchifyMatchPatterns(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("ematchifyMatchPatterns");
  SmallVector<match::MatcherOp> matchers;
  SmallVector<match::RewriterOp> rewriters;
  module.walk([&](Operation *op) {
    if (auto matcher = dyn_cast<match::MatcherOp>(op))
      matchers.push_back(matcher);
    else if (auto rewriter = dyn_cast<match::RewriterOp>(op))
      rewriters.push_back(rewriter);
  });
  for (match::MatcherOp matcher : matchers)
    ematchifyMatcher(matcher);
  for (match::RewriterOp rewriter : rewriters)
    ematchifyRewriter(rewriter);
}

LogicalResult convertPDLToEmatchPDLInterp(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("convertPDLToEmatchPDLInterp");
  if (failed(convertPDLToMatch(module)))
    return failure();
  ematchifyMatchPatterns(module);
  if (failed(match::combineMatchers(module, /*groupByRoot=*/false,
                                    /*deferLoops=*/true)))
    return failure();
  return convertMatchToPDLInterp(module);
}

} // namespace mlir::ematch
