//===- Ematchify.cpp - E-matching over the match dialect ---------*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements `ematchifyMatchPatterns`, `convertEmatchOpsToMatch` and
// `convertPDLToEmatchPDLInterp` declared in EmatchUtils.h: the lowering of
// `pdl` patterns to `pdl_interp` that match and rewrite over the e-classes of
// an e-graph, going through the `match` dialect:
//
//   convert-pdl-to-match -> ematchify -> match-combine-matchers{defer-loops}
//     -> convert-ematch-to-match -> convert-match-to-pdl-interp
//
//
//===----------------------------------------------------------------------===//

#include "EmatchUtils.h"

#include "EmatchDialect.h"
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

/// Create the e-class result(s) of `v`, a value or a range of values.
Value createClassResult(OpBuilder &builder, Value v) {
  Location loc = v.getLoc();
  if (isValue(v))
    return GetClassResultOp::create(builder, loc, v.getType(), v);
  return GetClassResultsOp::create(builder, loc, v.getType(), v);
}

/// Map `v` to its e-class result(s) right after `after`, and redirect the uses
/// of `v` to the e-class result(s).
void replaceWithClassResult(OpBuilder &builder, Value v, Operation *after) {
  builder.setInsertionPointAfter(after);
  Value classResult = createClassResult(builder, v);
  v.replaceAllUsesExcept(classResult, classResult.getDefiningOp());
}

/// Return the value an e-class result was computed from, or null if `v` is not
/// produced by ematch.get_class_result(s).
Value getClassResultInput(Value v) {
  if (auto op = v.getDefiningOp<GetClassResultOp>())
    return op.getValue();
  if (auto op = v.getDefiningOp<GetClassResultsOp>())
    return op.getValues();
  return nullptr;
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
    Value members = GetClassValsOp::create(builder, op.getLoc(), valueRangeTy,
                                           op.getValue());
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
    EquivalentOp::create(builder, op.getLoc(), op.getLhs(), op.getRhs());
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
        representative = GetClassRepresentativeOp::create(
            builder, op.getLoc(), value.getType(), value);
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
    Value classResult = createClassResult(builder, arg);
    arg.replaceAllUsesExcept(classResult, classResult.getDefiningOp());
  }

  // An operation is only added to the e-graph if no equivalent e-node exists.
  auto dedup = [&](Value createdOp) {
    builder.setInsertionPointAfterValue(createdOp);
    auto deduped = DedupOp::create(builder, createdOp.getLoc(),
                                   createdOp.getType(), createdOp);
    createdOp.replaceAllUsesExcept(deduped, deduped);
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
      UnionOp::create(builder, replace.getLoc(), replace.getInputOp(),
                      replacement);
      replace.erase();
    } else if (isa<match::EraseOp, match::ReplaceOp>(op)) {
      // Nothing is ever removed from an e-graph.
      op->erase();
    }
  }
}

/// Return the ancestor of `op` in `block`.
Operation *getAncestorInBlock(Operation *op, Block *block) {
  while (op->getBlock() != block)
    op = op->getParentOp();
  return op;
}

/// match-combine-matchers only moves its own navigation ops to their first
/// use, so the e-class helpers end up computed early in their scope, even when
/// a later check fails. Move each of them right before its first use, into the
/// `try`/switch case that holds all of its uses. They never move into a loop,
/// which would recompute them on every iteration.
void sinkClassHelpers(match::MatcherOp matcher) {
  SmallVector<Operation *> helpers;
  matcher.walk([&](Operation *op) {
    if (isa<GetClassValsOp, GetClassResultOp, GetClassResultsOp,
            GetClassRepresentativeOp>(op))
      helpers.push_back(op);
  });
  // Later helpers first, so that a helper used by another one follows it.
  for (Operation *helper : llvm::reverse(helpers)) {
    Block *block = helper->getBlock();
    while (true) {
      Operation *earliest = nullptr;
      for (Operation *user : helper->getUsers()) {
        Operation *anchor = getAncestorInBlock(user, block);
        if (!earliest || anchor->isBeforeInBlock(earliest))
          earliest = anchor;
      }
      if (!earliest)
        break;
      Block *nested = nullptr;
      if (!isa<match::ForEachOp>(earliest) &&
          !llvm::is_contained(helper->getUsers(), earliest)) {
        for (Region &region : earliest->getRegions()) {
          Block *candidate = &region.front();
          if (llvm::all_of(helper->getUsers(), [&](Operation *user) {
                return candidate->findAncestorOpInBlock(*user);
              }))
            nested = candidate;
        }
      }
      if (!nested) {
        helper->moveBefore(earliest);
        break;
      }
      block = nested;
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

void convertEmatchOpsToMatch(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("convertEmatchOpsToMatch");
  SmallVector<Operation *> ops;
  module.walk([&](Operation *op) {
    if (isa<GetClassValsOp, GetClassResultOp, GetClassResultsOp,
            GetClassRepresentativeOp, EquivalentOp, UnionOp, DedupOp>(op) &&
        (op->getParentOfType<match::MatcherOp>() ||
         op->getParentOfType<match::RewriterOp>()))
      ops.push_back(op);
  });
  OpBuilder builder(module.getContext());
  for (Operation *op : ops) {
    builder.setInsertionPoint(op);
    Operation *native;
    if (isa<EquivalentOp>(op))
      native = match::ApplyNativeConstraintOp::create(
          builder, op->getLoc(), /*results=*/TypeRange(),
          builder.getStringAttr("are_equivalent"), op->getOperands(),
          /*isNegated=*/builder.getBoolAttr(false));
    else
      native = createNativeRewrite(builder, op->getLoc(),
                                   op->getName().stripDialect(),
                                   op->getResultTypes(), op->getOperands());
    op->replaceAllUsesWith(native);
    op->erase();
  }
}

LogicalResult convertPDLToEmatchPDLInterp(ModuleOp module) {
  TAMAGOYAKI_SCOPED_TIMER("convertPDLToEmatchPDLInterp");
  if (failed(convertPDLToMatch(module)))
    return failure();
  ematchifyMatchPatterns(module);
  if (failed(match::combineMatchers(module, /*groupByRoot=*/false,
                                    /*deferLoops=*/true)))
    return failure();
  for (auto matcher : module.getOps<match::MatcherOp>())
    sinkClassHelpers(matcher);
  convertEmatchOpsToMatch(module);
  return convertMatchToPDLInterp(module);
}

} // namespace mlir::ematch
