//===- RewriterGen.cpp - PDL rewriter generation --------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "RewriterGen.h"

#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/BuiltinOps.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/TypeSwitch.h"
#include <llvm/ADT/STLExtras.h>
#include <llvm/Support/ErrorHandling.h>
#include <mlir/Dialect/PDL/IR/PDLOps.h>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/SymbolTable.h>
#include <mlir/IR/TypeRange.h>
#include <mlir/IR/Types.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>
#include <optional>

using namespace mlir;

namespace {
class RewriterGen {
public:
  RewriterGen(OpBuilder &builder, SmallVectorImpl<Value> &usedMatchValues,
              function_ref<bool(StringRef)> canInferResultTypes)
      : builder(builder), usedMatchValues(usedMatchValues),
        canInferResultTypes(canInferResultTypes) {}

  void generate(pdl::PatternOp pattern, match::RewriterOp rewriterOp);

private:
  void generateRewriter(pdl::ApplyNativeRewriteOp rewriteOp);
  void generateRewriter(pdl::AttributeOp attrOp);
  void generateRewriter(pdl::EraseOp eraseOp);
  void generateRewriter(pdl::OperationOp operationOp);
  void generateRewriter(pdl::RangeOp rangeOp);
  void generateRewriter(pdl::ReplaceOp replaceOp);
  void generateRewriter(pdl::ResultOp resultOp);
  void generateRewriter(pdl::ResultsOp resultOp);
  void generateRewriter(pdl::TypeOp typeOp);
  void generateRewriter(pdl::TypesOp typeOp);

  void generateOperationResultTypeRewriter(pdl::OperationOp op,
                                           SmallVectorImpl<Value> &types,
                                           bool &hasInferredResultTypes);

  Value mapRewriteValue(Value oldValue);
  bool hasTypeInference(pdl::OperationOp op);
  Value getValueType(Location loc, Value value);
  Value getAllResults(Location loc, Value op);

  OpBuilder &builder;
  SmallVectorImpl<Value> &usedMatchValues;
  function_ref<bool(StringRef)> canInferResultTypes;
  match::RewriterOp rewriterOp;
  DenseMap<Value, Value> rewriteValues;
};
} // namespace

Value RewriterGen::mapRewriteValue(Value oldValue) {
  Value &newValue = rewriteValues[oldValue];
  if (newValue)
    return newValue;

  Operation *oldOp = oldValue.getDefiningOp();
  if (pdl::AttributeOp attrOp = dyn_cast<pdl::AttributeOp>(oldOp)) {
    if (Attribute value = attrOp.getValueAttr()) {
      return newValue = match::ConstantAttributeOp::create(
                 builder, attrOp.getLoc(), value);
    }
  } else if (pdl::TypeOp typeOp = dyn_cast<pdl::TypeOp>(oldOp)) {
    if (TypeAttr type = typeOp.getConstantTypeAttr()) {
      return newValue =
                 match::ConstantTypeOp::create(builder, typeOp.getLoc(), type);
    }
  } else if (pdl::TypesOp typeOp = dyn_cast<pdl::TypesOp>(oldOp)) {
    if (ArrayAttr type = typeOp.getConstantTypesAttr()) {
      return newValue =
                 match::ConstantTypesOp::create(builder, typeOp.getLoc(), type);
    }
  }

  usedMatchValues.push_back(oldValue);
  return newValue = rewriterOp.getBody().addArgument(oldValue.getType(),
                                                     oldValue.getLoc());
}

bool RewriterGen::hasTypeInference(pdl::OperationOp op) {
  if (op.hasTypeInference())
    return true;
  std::optional<StringRef> name = op.getOpName();
  return name && canInferResultTypes && canInferResultTypes(*name);
}

Value RewriterGen::getValueType(Location loc, Value value) {
  Type type = builder.getType<pdl::TypeType>();
  if (isa<pdl::RangeType>(value.getType()))
    type = pdl::RangeType::get(type);
  return match::GetValueTypeOp::create(builder, loc, type, value);
}

Value RewriterGen::getAllResults(Location loc, Value op) {
  return pdl::ResultsOp::create(
      builder, loc, pdl::RangeType::get(builder.getType<pdl::ValueType>()), op,
      IntegerAttr());
}

void RewriterGen::generate(pdl::PatternOp pattern,
                           match::RewriterOp rewriterOp) {
  this->rewriterOp = rewriterOp;

  builder.setInsertionPointToEnd(&rewriterOp.getBody().front());

  pdl::RewriteOp rewriter = pattern.getRewriter();
  if (StringAttr rewriteName = rewriter.getNameAttr()) {
    SmallVector<Value> args;
    if (rewriter.getRoot())
      args.push_back(mapRewriteValue(rewriter.getRoot()));
    auto mappedArgs = llvm::map_range(rewriter.getExternalArgs(), [&](Value v) {
      return mapRewriteValue(v);
    });
    args.append(mappedArgs.begin(), mappedArgs.end());
    match::ApplyNativeRewriteOp::create(builder, rewriter.getLoc(),
                                        /*results=*/TypeRange(), rewriteName,
                                        args);
  } else {
    for (Operation &rewriteOp : *rewriter.getBody()) {
      llvm::TypeSwitch<Operation *>(&rewriteOp)
          .Case<pdl::ApplyNativeRewriteOp, pdl::AttributeOp, pdl::EraseOp,
                pdl::OperationOp, pdl::RangeOp, pdl::ReplaceOp, pdl::ResultOp,
                pdl::ResultsOp, pdl::TypeOp, pdl::TypesOp>(
              [&](auto op) { this->generateRewriter(op); });
    }
  }
}

void RewriterGen::generateRewriter(pdl::ApplyNativeRewriteOp rewriteOp) {
  SmallVector<Value, 2> arguments;
  for (Value argument : rewriteOp.getArgs())
    arguments.push_back(mapRewriteValue(argument));
  auto newOp = match::ApplyNativeRewriteOp::create(
      builder, rewriteOp.getLoc(), rewriteOp.getResultTypes(),
      rewriteOp.getNameAttr(), arguments);
  for (auto it : llvm::zip(rewriteOp.getResults(), newOp.getResults()))
    rewriteValues[std::get<0>(it)] = std::get<1>(it);
}

void RewriterGen::generateRewriter(pdl::AttributeOp attrOp) {
  Value newAttr = match::ConstantAttributeOp::create(builder, attrOp.getLoc(),
                                                     attrOp.getValueAttr());
  rewriteValues[attrOp] = newAttr;
}

void RewriterGen::generateRewriter(pdl::EraseOp eraseOp) {
  match::EraseOp::create(builder, eraseOp.getLoc(),
                         mapRewriteValue(eraseOp.getOpValue()));
}

void RewriterGen::generateRewriter(pdl::OperationOp operationOp) {
  SmallVector<Value, 4> operands;
  for (Value operand : operationOp.getOperandValues())
    operands.push_back(mapRewriteValue(operand));

  SmallVector<Value, 4> attributes;
  for (Value attr : operationOp.getAttributeValues())
    attributes.push_back(mapRewriteValue(attr));

  bool hasInferredResultTypes = false;
  SmallVector<Value, 2> types;
  generateOperationResultTypeRewriter(operationOp, types,
                                      hasInferredResultTypes);

  Location loc = operationOp.getLoc();
  Value createdOp = match::CreateOperationOp::create(
      builder, loc, *operationOp.getOpName(), types, hasInferredResultTypes,
      operands, attributes, operationOp.getAttributeValueNames());
  rewriteValues[operationOp.getOp()] = createdOp;

  OperandRange resultTys = operationOp.getTypeValues();
  if (resultTys.size() == 1 && isa<pdl::RangeType>(resultTys[0].getType())) {
    Value &type = rewriteValues[resultTys[0]];
    if (!type)
      type = getValueType(loc, getAllResults(loc, createdOp));
    return;
  }

  bool seenVariableLength = false;
  Type valueTy = builder.getType<pdl::ValueType>();
  Type valueRangeTy = pdl::RangeType::get(valueTy);
  for (const auto &it : llvm::enumerate(resultTys)) {
    Value &type = rewriteValues[it.value()];
    if (type)
      continue;
    bool isVariadic = isa<pdl::RangeType>(it.value().getType());
    seenVariableLength |= isVariadic;

    Value resultVal;
    IntegerAttr index = builder.getI32IntegerAttr(it.index());
    if (seenVariableLength)
      resultVal = pdl::ResultsOp::create(
          builder, loc, isVariadic ? valueRangeTy : valueTy, createdOp, index);
    else
      resultVal =
          pdl::ResultOp::create(builder, loc, valueTy, createdOp, index);
    type = getValueType(loc, resultVal);
  }
}

void RewriterGen::generateRewriter(pdl::RangeOp rangeOp) {
  SmallVector<Value, 4> replOperands;
  for (Value operand : rangeOp.getArguments())
    replOperands.push_back(mapRewriteValue(operand));
  rewriteValues[rangeOp] = match::CreateRangeOp::create(
      builder, rangeOp.getLoc(), rangeOp.getType(), replOperands);
}

void RewriterGen::generateRewriter(pdl::ReplaceOp replaceOp) {
  SmallVector<Value, 4> replOperands;

  if (Value replOp = replaceOp.getReplOperation()) {
    auto opOp = replaceOp.getOpValue().getDefiningOp<pdl::OperationOp>();
    if (!opOp || !opOp.getTypeValues().empty()) {
      replOperands.push_back(
          getAllResults(replOp.getLoc(), mapRewriteValue(replOp)));
    }
  } else {
    for (Value operand : replaceOp.getReplValues())
      replOperands.push_back(mapRewriteValue(operand));
  }

  if (replOperands.empty()) {
    match::EraseOp::create(builder, replaceOp.getLoc(),
                           mapRewriteValue(replaceOp.getOpValue()));
    return;
  }

  match::ReplaceOp::create(builder, replaceOp.getLoc(),
                           mapRewriteValue(replaceOp.getOpValue()),
                           replOperands);
}

void RewriterGen::generateRewriter(pdl::ResultOp resultOp) {
  rewriteValues[resultOp] = pdl::ResultOp::create(
      builder, resultOp.getLoc(), builder.getType<pdl::ValueType>(),
      mapRewriteValue(resultOp.getParent()), resultOp.getIndexAttr());
}

void RewriterGen::generateRewriter(pdl::ResultsOp resultOp) {
  rewriteValues[resultOp] = pdl::ResultsOp::create(
      builder, resultOp.getLoc(), resultOp.getType(),
      mapRewriteValue(resultOp.getParent()), resultOp.getIndexAttr());
}

void RewriterGen::generateRewriter(pdl::TypeOp typeOp) {
  if (TypeAttr typeAttr = typeOp.getConstantTypeAttr()) {
    rewriteValues[typeOp] =
        match::ConstantTypeOp::create(builder, typeOp.getLoc(), typeAttr);
  }
}

void RewriterGen::generateRewriter(pdl::TypesOp typeOp) {
  if (ArrayAttr typeAttr = typeOp.getConstantTypesAttr()) {
    rewriteValues[typeOp] =
        match::ConstantTypesOp::create(builder, typeOp.getLoc(), typeAttr);
  }
}

void RewriterGen::generateOperationResultTypeRewriter(
    pdl::OperationOp op, SmallVectorImpl<Value> &types,
    bool &hasInferredResultTypes) {
  Block *rewriterBlock = op->getBlock();

  OperandRange resultTypeValues = op.getTypeValues();
  auto tryResolveResultTypes = [&] {
    types.reserve(resultTypeValues.size());
    for (const auto &it : llvm::enumerate(resultTypeValues)) {
      Value resultType = it.value();

      if (Value existingRewriteValue = rewriteValues.lookup(resultType)) {
        types.push_back(existingRewriteValue);
        continue;
      }

      if (resultType.getDefiningOp()->getBlock() != rewriterBlock) {
        types.push_back(mapRewriteValue(resultType));
        continue;
      }

      types.clear();
      return failure();
    }
    return success();
  };
  if (!resultTypeValues.empty() && succeeded(tryResolveResultTypes()))
    return;

  if (hasTypeInference(op)) {
    hasInferredResultTypes = true;
    return;
  }

  for (OpOperand &use : op.getOp().getUses()) {
    pdl::ReplaceOp replOpUser = dyn_cast<pdl::ReplaceOp>(use.getOwner());
    if (!replOpUser || use.getOperandNumber() == 0)
      continue;
    Value replOpVal = replOpUser.getOpValue();
    Operation *replacedOp = replOpVal.getDefiningOp();
    if (replacedOp->getBlock() == rewriterBlock &&
        !replacedOp->isBeforeInBlock(op))
      continue;

    Value replacedOpResults =
        getAllResults(replacedOp->getLoc(), mapRewriteValue(replOpVal));
    types.push_back(getValueType(replacedOp->getLoc(), replacedOpResults));
    return;
  }

  if (resultTypeValues.empty())
    return;

  op->emitOpError() << "unable to infer result type for operation";
  llvm_unreachable("unable to infer result type for operation");
}

match::RewriterOp mlir::pdl_to_match::generateRewriter(
    pdl::PatternOp pattern, SymbolTable &rewriterSymbolTable,
    SmallVectorImpl<Value> &usedMatchValues,
    function_ref<bool(StringRef)> canInferResultTypes) {
  auto rewriterModule = cast<ModuleOp>(rewriterSymbolTable.getOp());
  OpBuilder builder = OpBuilder::atBlockEnd(rewriterModule.getBody());
  auto rewriterOp = match::RewriterOp::create(
      builder, pattern.getLoc(),
      pattern.getSymName().value_or("pdl_generated_rewriter"));
  rewriterSymbolTable.insert(rewriterOp);
  RewriterGen(builder, usedMatchValues, canInferResultTypes)
      .generate(pattern, rewriterOp);
  return rewriterOp;
}
