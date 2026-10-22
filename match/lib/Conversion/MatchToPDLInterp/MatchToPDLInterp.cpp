//===- MatchToPDLInterp.cpp - Lower match to pdl_interp -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/MatchToPDLInterp/MatchToPDLInterp.h"

#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/Match/IR/MatchTypes.h"
#include "mlir/Dialect/PDL/IR/PDLOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/SetVector.h"
#include "llvm/ADT/TypeSwitch.h"
#include <cassert>
#include <cstddef>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVectorExtras.h>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/Region.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>

namespace mlir {
#define GEN_PASS_DEF_CONVERTMATCHTOPDLINTERPPASS
#include "mlir/Conversion/MatchConversionPasses.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::match;

namespace {
class Lowerer {
public:
  Lowerer(pdl_interp::FuncOp matcherFunc)
      : builder(matcherFunc.getContext()), matcherFunc(matcherFunc) {}

  LogicalResult lower(ArrayRef<MatcherOp> matchers);

private:
  class PathScope {
  public:
    explicit PathScope(Lowerer &lowerer)
        : lowerer(lowerer), savedLocSize(lowerer.locOps.size()),
          savedRootKind(lowerer.rootKind) {}
    ~PathScope() {
      while (lowerer.locOps.size() > savedLocSize)
        lowerer.locOps.pop_back();
      lowerer.rootKind = savedRootKind;
    }

  private:
    Lowerer &lowerer;
    size_t savedLocSize;
    StringAttr savedRootKind;
  };

  LogicalResult lowerRegion(Region &region);
  LogicalResult lowerOp(Operation *operation);
  LogicalResult lowerTry(TryOp op);
  LogicalResult lowerForEach(ForEachOp op);
  LogicalResult
  lowerSwitch(Operation *op, function_ref<void(unsigned)> enterCase,
              function_ref<void(Block *, ArrayRef<Block *>)> emitSwitch);
  void lowerSuccess(SuccessOp op);

  template <typename OpT, typename... Args>
  OpT emitTest(Location loc, Args &&...args) {
    Block *success = newBlock();
    builder.setInsertionPointToEnd(currentBlock);
    auto test = OpT::create(builder, loc, std::forward<Args>(args)..., success,
                            failureBlock);
    currentBlock = success;
    return test;
  }

  Block *newBlock() {
    Block *block = new Block();
    currentBlock->getParent()->push_back(block);
    return block;
  }

  Value lookup(Value v) const {
    Value mapped = valueMap.lookup(v);
    assert(mapped && "match value not mapped");
    return mapped;
  }

  SmallVector<Value> lookup(ValueRange values) const {
    return llvm::map_to_vector(values, [&](Value v) { return lookup(v); });
  }

  void setOpName(Value op, StringAttr name) {
    if (op == matcherFunc.front().getArgument(0))
      rootKind = name;
  }

  void map(Value from, Value to, bool isLoc = false) {
    valueMap.map(from, to);
    if (isLoc && isa<pdl::OperationType>(to.getType()))
      locOps.insert(to);
  }

  OpBuilder builder;
  pdl_interp::FuncOp matcherFunc;
  SymbolTableCollection symbolTables;
  IRMapping valueMap;
  Block *currentBlock = nullptr;
  Block *failureBlock = nullptr;
  llvm::SmallSetVector<Value, 4> locOps;
  StringAttr rootKind;
};
} // namespace

LogicalResult Lowerer::lower(ArrayRef<MatcherOp> matchers) {
  Block *finalize = new Block();
  matcherFunc.getBody().push_back(finalize);
  builder.setInsertionPointToEnd(finalize);
  pdl_interp::FinalizeOp::create(builder, matcherFunc.getLoc());

  Value root = matcherFunc.front().getArgument(0);
  Block *entry = &matcherFunc.front();
  for (size_t i = 0, e = matchers.size(); i < e; ++i) {
    MatcherOp matcher = matchers[i];
    Block *next = finalize;
    if (i + 1 != e) {
      next = new Block();
      matcherFunc.getBody().push_back(next);
    }
    PathScope scope(*this);
    map(matcher.getBodyRegion().front().getArgument(0), root, /*isLoc=*/true);
    currentBlock = entry;
    failureBlock = next;
    if (failed(lowerRegion(matcher.getBodyRegion())))
      return failure();
    entry = next;
  }

  if (matchers.empty()) {
    builder.setInsertionPointToEnd(entry);
    pdl_interp::BranchOp::create(builder, matcherFunc.getLoc(), finalize);
  }
  return success();
}

LogicalResult Lowerer::lowerRegion(Region &region) {
  for (Operation &op : region.front()) {
    if (!currentBlock)
      break;
    if (failed(lowerOp(&op)))
      return failure();
  }
  if (currentBlock) {
    builder.setInsertionPointToEnd(currentBlock);
    pdl_interp::BranchOp::create(builder, region.getLoc(), failureBlock);
    currentBlock = nullptr;
  }
  return success();
}

LogicalResult Lowerer::lowerTry(TryOp op) {
  Block *afterTry = newBlock();
  Block *savedFailure = failureBlock;
  failureBlock = afterTry;
  {
    PathScope scope(*this);
    if (failed(lowerRegion(op.getBody())))
      return failure();
  }
  failureBlock = savedFailure;
  currentBlock = afterTry;
  return success();
}

LogicalResult Lowerer::lowerForEach(ForEachOp op) {
  Block *afterLoop = op->getNextNode() ? newBlock() : failureBlock;
  builder.setInsertionPointToEnd(currentBlock);
  auto foreach = pdl_interp::ForEachOp::create(builder, op.getLoc(),
                                               lookup(op.getRange()), afterLoop,
                                               /*initLoop=*/true);

  Block *continueBlock = new Block();
  foreach
    .getRegion().push_back(continueBlock);
  builder.setInsertionPointToEnd(continueBlock);
  pdl_interp::ContinueOp::create(builder, op.getLoc());

  Block *savedFailure = failureBlock;
  {
    PathScope scope(*this);
    currentBlock = &foreach.getRegion().front();
    failureBlock = continueBlock;
    map(op.getLoopVariable(), foreach.getLoopVariable(), /*isLoc=*/true);
    if (failed(lowerRegion(op.getBody())))
      return failure();
  }
  failureBlock = savedFailure;
  currentBlock = op->getNextNode() ? afterLoop : nullptr;
  return success();
}

LogicalResult Lowerer::lowerSwitch(
    Operation *op, function_ref<void(unsigned)> enterCase,
    function_ref<void(Block *, ArrayRef<Block *>)> emitSwitch) {
  Block *outerCurrent = currentBlock;
  Block *outerFailure = failureBlock;
  Block *fallthrough = op->getNextNode() ? newBlock() : outerFailure;
  SmallVector<Block *> caseBlocks;
  for (unsigned i = 0, e = op->getNumRegions(); i < e; ++i)
    caseBlocks.push_back(newBlock());

  for (auto [i, region] : llvm::enumerate(op->getRegions())) {
    PathScope scope(*this);
    currentBlock = caseBlocks[i];
    failureBlock = fallthrough;
    enterCase(i);
    if (failed(lowerRegion(region)))
      return failure();
  }

  currentBlock = outerCurrent;
  failureBlock = outerFailure;
  builder.setInsertionPointToEnd(currentBlock);
  emitSwitch(fallthrough, caseBlocks);
  currentBlock = op->getNextNode() ? fallthrough : nullptr;
  return success();
}

void Lowerer::lowerSuccess(SuccessOp op) {
  ArrayAttr generatedOps;
  if (auto rewriter = dyn_cast_or_null<pdl_interp::FuncOp>(
          symbolTables.lookupNearestSymbolFrom(matcherFunc,
                                               op.getRewriterAttr()))) {
    SmallVector<Attribute> names;
    for (auto createOp :
         rewriter.getBody().getOps<pdl_interp::CreateOperationOp>())
      names.push_back(createOp.getNameAttr());
    if (!names.empty())
      generatedOps = builder.getArrayAttr(names);
  }

  builder.setInsertionPointToEnd(currentBlock);
  Block *continuation = newBlock();
  pdl_interp::RecordMatchOp::create(
      builder, op.getLoc(), lookup(op.getInputs()), locOps.getArrayRef(),
      op.getRewriterAttr(), rootKind, generatedOps, op.getBenefitAttr(),
      continuation);
  currentBlock = continuation;
}

LogicalResult Lowerer::lowerOp(Operation *operation) {
  builder.setInsertionPointToEnd(currentBlock);
  Location loc = operation->getLoc();
  auto innerType = [](Value v) {
    return cast<OptionalType>(v.getType()).getInnerType();
  };
  return TypeSwitch<Operation *, LogicalResult>(operation)
      .Case([&](TryOp op) { return lowerTry(op); })
      .Case([&](ForEachOp op) { return lowerForEach(op); })
      .Case([&](SwitchOpNameOp op) {
        Value mapped = lookup(op.getOp());
        return lowerSwitch(
            op,
            [&](unsigned i) {
              setOpName(mapped, cast<StringAttr>(op.getCaseNames()[i]));
            },
            [&](Block *defaultDest, ArrayRef<Block *> dests) {
              pdl_interp::SwitchOperationNameOp::create(
                  builder, loc, mapped, op.getCaseNames(), defaultDest, dests);
            });
      })
      .Case([&](SwitchTypeOp op) {
        Value mapped = lookup(op.getTypeValue());
        return lowerSwitch(
            op, [](unsigned) {},
            [&](Block *defaultDest, ArrayRef<Block *> dests) {
              pdl_interp::SwitchTypeOp::create(
                  builder, loc, mapped, op.getCaseTypes(), defaultDest, dests);
            });
      })
      .Case([&](SuccessOp op) {
        lowerSuccess(op);
        return success();
      })
      .Case([&](ConstantAttributeOp op) {
        map(op,
            pdl_interp::CreateAttributeOp::create(builder, loc, op.getValue()));
        return success();
      })
      .Case([&](ConstantTypeOp op) {
        map(op,
            pdl_interp::CreateTypeOp::create(builder, loc, op.getValueAttr()));
        return success();
      })
      .Case([&](ConstantTypesOp op) {
        map(op,
            pdl_interp::CreateTypesOp::create(builder, loc, op.getValueAttr()));
        return success();
      })
      .Case([&](GetOperandOp op) {
        map(op, pdl_interp::GetOperandOp::create(builder, loc, innerType(op),
                                                 lookup(op.getOp()),
                                                 op.getIndexAttr()));
        return success();
      })
      .Case([&](GetOperandsOp op) {
        map(op, pdl_interp::GetOperandsOp::create(builder, loc, innerType(op),
                                                  lookup(op.getOp()),
                                                  op.getIndexAttr()));
        return success();
      })
      .Case([&](GetResultOp op) {
        map(op, pdl_interp::GetResultOp::create(builder, loc, innerType(op),
                                                lookup(op.getOp()),
                                                op.getIndexAttr()));
        return success();
      })
      .Case([&](GetResultsOp op) {
        map(op, pdl_interp::GetResultsOp::create(builder, loc, innerType(op),
                                                 lookup(op.getOp()),
                                                 op.getIndexAttr()));
        return success();
      })
      .Case([&](GetAttributeOp op) {
        map(op, pdl_interp::GetAttributeOp::create(
                    builder, loc, builder.getType<pdl::AttributeType>(),
                    lookup(op.getOp()), op.getNameAttr()));
        return success();
      })
      .Case([&](GetDefiningOpOp op) {
        map(op,
            pdl_interp::GetDefiningOpOp::create(
                builder, loc, builder.getType<pdl::OperationType>(),
                lookup(op.getValue())),
            /*isLoc=*/true);
        return success();
      })
      .Case([&](GetValueTypeOp op) {
        map(op, pdl_interp::GetValueTypeOp::create(builder, loc, op.getType(),
                                                   lookup(op.getValue())));
        return success();
      })
      .Case([&](GetAttributeTypeOp op) {
        map(op, pdl_interp::GetAttributeTypeOp::create(
                    builder, loc, lookup(op.getAttribute())));
        return success();
      })
      .Case([&](GetUsersOp op) {
        map(op, pdl_interp::GetUsersOp::create(builder, loc,
                                               lookup(op.getValue())));
        return success();
      })
      .Case([&](ExtractOp op) {
        map(op, pdl_interp::ExtractOp::create(
                    builder, loc, lookup(op.getRange()), op.getIndex()));
        return success();
      })
      .Case([&](ApplyNativeRewriteOp op) {
        auto rewrite = pdl_interp::ApplyRewriteOp::create(
            builder, loc, op.getResultTypes(), op.getNameAttr(),
            lookup(op.getArgs()));
        for (auto [from, to] : llvm::zip(op.getResults(), rewrite.getResults()))
          map(from, to, /*isLoc=*/true);
        return success();
      })
      .Case([&](IsNotNullOp op) {
        Value mapped = lookup(op.getOptionalValue());
        emitTest<pdl_interp::IsNotNullOp>(loc, mapped);
        map(op, mapped);
        return success();
      })
      .Case([&](HasNameOp op) {
        Value mapped = lookup(op.getOp());
        emitTest<pdl_interp::CheckOperationNameOp>(loc, mapped,
                                                   op.getNameAttr());
        setOpName(mapped, op.getNameAttr());
        return success();
      })
      .Case([&](EqualOp op) {
        emitTest<pdl_interp::AreEqualOp>(loc, lookup(op.getLhs()),
                                         lookup(op.getRhs()));
        return success();
      })
      .Case([&](HasTypeOp op) {
        emitTest<pdl_interp::CheckTypeOp>(loc, lookup(op.getTypeValue()),
                                          op.getConstantTypeAttr());
        return success();
      })
      .Case([&](HasTypesOp op) {
        emitTest<pdl_interp::CheckTypesOp>(loc, lookup(op.getTypes()),
                                           op.getConstantTypesAttr());
        return success();
      })
      .Case([&](HasAttrValueOp op) {
        emitTest<pdl_interp::CheckAttributeOp>(loc, lookup(op.getAttribute()),
                                               op.getValueAttr());
        return success();
      })
      .Case([&](CheckOperandCountOp op) {
        emitTest<pdl_interp::CheckOperandCountOp>(
            loc, lookup(op.getOp()), op.getCount(), op.getAtLeast());
        return success();
      })
      .Case([&](CheckResultCountOp op) {
        emitTest<pdl_interp::CheckResultCountOp>(
            loc, lookup(op.getOp()), op.getCount(), op.getAtLeast());
        return success();
      })
      .Case([&](ApplyNativeConstraintOp op) {
        auto constraint = emitTest<pdl_interp::ApplyConstraintOp>(
            loc, op.getResultTypes(), op.getNameAttr(), lookup(op.getArgs()),
            op.getIsNegatedAttr());
        for (auto [from, to] :
             llvm::zip(op.getResults(), constraint.getResults()))
          map(from, to, /*isLoc=*/true);
        return success();
      })
      .Default([](Operation *op) {
        return op->emitOpError("unsupported match op in lowering");
      });
}

static LogicalResult lowerRewriterOp(OpBuilder &builder, IRMapping &mapping,
                                     Operation *operation) {
  Location loc = operation->getLoc();
  auto lookup = [&](ValueRange values) {
    return llvm::map_to_vector(values,
                               [&](Value v) { return mapping.lookup(v); });
  };
  Operation *newOp =
      TypeSwitch<Operation *, Operation *>(operation)
          .Case([&](ConstantAttributeOp op) {
            return pdl_interp::CreateAttributeOp::create(builder, loc,
                                                         op.getValue());
          })
          .Case([&](ConstantTypeOp op) {
            return pdl_interp::CreateTypeOp::create(builder, loc,
                                                    op.getValueAttr());
          })
          .Case([&](ConstantTypesOp op) {
            return pdl_interp::CreateTypesOp::create(builder, loc,
                                                     op.getValueAttr());
          })
          .Case([&](ApplyNativeRewriteOp op) {
            return pdl_interp::ApplyRewriteOp::create(
                builder, loc, op.getResultTypes(), op.getNameAttr(),
                lookup(op.getArgs()));
          })
          .Case([&](CreateOperationOp op) {
            return pdl_interp::CreateOperationOp::create(
                builder, loc, op.getName(), lookup(op.getInputResultTypes()),
                op.getInferredResultTypes(), lookup(op.getInputOperands()),
                lookup(op.getInputAttributes()), op.getInputAttributeNames());
          })
          .Case([&](CreateRangeOp op) {
            return pdl_interp::CreateRangeOp::create(builder, loc, op.getType(),
                                                     lookup(op.getArguments()));
          })
          .Case([&](GetValueTypeOp op) {
            return pdl_interp::GetValueTypeOp::create(
                builder, loc, op.getType(), mapping.lookup(op.getValue()));
          })
          .Case([&](pdl::ResultOp op) {
            return pdl_interp::GetResultOp::create(
                builder, loc, op.getType(), mapping.lookup(op.getParent()),
                op.getIndexAttr());
          })
          .Case([&](pdl::ResultsOp op) {
            return pdl_interp::GetResultsOp::create(
                builder, loc, op.getType(), mapping.lookup(op.getParent()),
                op.getIndexAttr());
          })
          .Case([&](ReplaceOp op) {
            return pdl_interp::ReplaceOp::create(
                builder, loc, mapping.lookup(op.getInputOp()),
                lookup(op.getReplValues()));
          })
          .Case([&](EraseOp op) {
            return pdl_interp::EraseOp::create(builder, loc,
                                               mapping.lookup(op.getInputOp()));
          })
          .Default([](Operation *) { return nullptr; });
  if (!newOp)
    return operation->emitOpError("unsupported op in rewriter lowering");
  mapping.map(operation->getResults(), newOp->getResults());
  return success();
}

static FailureOr<pdl_interp::FuncOp> lowerRewriter(RewriterOp rewriter) {
  OpBuilder builder(rewriter);
  Block &body = rewriter.getBody().front();
  auto func = pdl_interp::FuncOp::create(
      builder, rewriter.getLoc(), rewriter.getSymName(),
      builder.getFunctionType(body.getArgumentTypes(), {}),
      ArrayRef<NamedAttribute>());
  Block *entry = &func.front();
  IRMapping mapping;
  mapping.map(body.getArguments(), entry->getArguments());
  builder.setInsertionPointToEnd(entry);
  for (Operation &op : body)
    if (failed(lowerRewriterOp(builder, mapping, &op)))
      return failure();
  pdl_interp::FinalizeOp::create(builder, rewriter.getLoc());
  return func;
}

LogicalResult mlir::convertMatchToPDLInterp(
    ModuleOp module, DenseMap<Operation *, PDLPatternConfigSet *> *configMap) {
  SmallVector<RewriterOp> rewriters;
  module.walk([&](RewriterOp rewriter) { rewriters.push_back(rewriter); });
  for (RewriterOp rewriter : rewriters) {
    FailureOr<pdl_interp::FuncOp> func = lowerRewriter(rewriter);
    if (failed(func))
      return failure();
    if (configMap) {
      if (PDLPatternConfigSet *config = configMap->lookup(rewriter))
        (*configMap)[*func] = config;
      configMap->erase(rewriter);
    }
    rewriter.erase();
  }

  SmallVector<MatcherOp> matchers(module.getOps<MatcherOp>());
  OpBuilder builder = OpBuilder::atBlockBegin(module.getBody());
  auto matcherFunc = pdl_interp::FuncOp::create(
      builder, module.getLoc(),
      pdl_interp::PDLInterpDialect::getMatcherFunctionName(),
      builder.getFunctionType(builder.getType<pdl::OperationType>(), {}),
      ArrayRef<NamedAttribute>());
  if (failed(Lowerer(matcherFunc).lower(matchers)))
    return failure();
  for (MatcherOp matcher : matchers)
    matcher.erase();
  return success();
}

namespace {
struct MatchToPDLInterpPass
    : public impl::ConvertMatchToPDLInterpPassBase<MatchToPDLInterpPass> {
  void runOnOperation() final {
    if (failed(convertMatchToPDLInterp(getOperation())))
      signalPassFailure();
  }
};
} // namespace
