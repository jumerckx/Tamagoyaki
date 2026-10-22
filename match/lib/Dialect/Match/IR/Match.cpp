//===- Match.cpp - Match dialect --------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/Match/IR/MatchTypes.h"
#include "mlir/Dialect/PDL/IR/PDLOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/TypeSwitch.h"
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/Sequence.h>
#include <llvm/Support/Casting.h>
#include <memory>
#include <mlir/Dialect/PDL/IR/PDL.h>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/Diagnostics.h>
#include <mlir/IR/OpImplementation.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/OperationSupport.h>
#include <mlir/IR/Region.h>
#include <mlir/IR/SymbolTable.h>
#include <mlir/IR/Types.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>
#include <mlir/Support/WalkResult.h>
#include <optional>
#include <string>
#include <utility>

using namespace mlir;
using namespace mlir::match;

#include "mlir/Dialect/Match/IR/MatchOpsDialect.cpp.inc"

void MatchDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/Match/IR/MatchOps.cpp.inc"
      >();
  registerTypes();
}

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/Match/IR/MatchOpsTypes.cpp.inc"

void MatchDialect::registerTypes() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "mlir/Dialect/Match/IR/MatchOpsTypes.cpp.inc"
      >();
}

LogicalResult OptionalType::verify(function_ref<InFlightDiagnostic()> emitError,
                                   Type innerType) {
  if (!llvm::isa<pdl::PDLType>(innerType)) {
    return emitError()
           << "expected inner type of match.optional to be a PDL type "
              "(one of [!pdl.attribute, !pdl.operation, !pdl.type, "
              "!pdl.value, !pdl.range<...>]), but got "
           << innerType;
  }
  return success();
}

static ParseResult parseMatcherRegion(OpAsmParser &parser, Region &region) {
  OpAsmParser::Argument arg;
  if (parser.parseLParen() || parser.parseArgument(arg, /*allowType=*/true) ||
      parser.parseRParen())
    return failure();

  return parser.parseRegion(region, {arg});
}

static void printMatcherRegion(OpAsmPrinter &p, Operation *op, Region &region) {
  p << "(";
  if (!region.empty() && region.front().getNumArguments() > 0) {
    BlockArgument arg = region.front().getArgument(0);
    p.printRegionArgument(arg);
  }
  p << ") ";
  p.printRegion(region, /*printEntryBlockArgs=*/false);
}

static bool regionContainsSuccess(Region &region) {
  WalkResult result =
      region.walk([&](SuccessOp) { return WalkResult::interrupt(); });
  return result.wasInterrupted();
}

LogicalResult MatcherOp::verifyRegions() {
  Region &body = getBodyRegion();
  if (body.empty())
    return emitOpError("expected non-empty body region");

  Block &block = body.front();

  if (block.getNumArguments() != 1)
    return emitOpError("expected body block to have exactly one argument");

  if (!llvm::isa<pdl::OperationType>(block.getArgument(0).getType()))
    return emitOpError(
        "expected body block argument to be of type !pdl.operation");

  if (!regionContainsSuccess(body))
    return emitOpError("expected matcher to contain at least one "
                       "`match.success` (directly or transitively)");

  return success();
}

StringRef MatcherOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

LogicalResult TryOp::verifyRegions() {
  if (!regionContainsSuccess(getBody()))
    return emitOpError("`match.try` region contains no "
                       "`match.success` (directly or transitively); the "
                       "region is dead");
  return success();
}

StringRef TryOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

namespace {
template <typename ParseCaseFn>
ParseResult
parseSwitchCases(OpAsmParser &parser, ArrayAttr &caseAttr,
                 SmallVectorImpl<std::unique_ptr<Region>> &caseRegions,
                 ParseCaseFn parseCase) {
  SmallVector<Attribute> caseAttrs;
  while (succeeded(parser.parseOptionalKeyword("case"))) {
    Attribute caseValue;
    if (failed(parseCase(parser, caseValue)))
      return failure();
    caseAttrs.push_back(caseValue);

    auto region = std::make_unique<Region>();
    if (parser.parseRegion(*region, /*arguments=*/{}))
      return failure();
    caseRegions.push_back(std::move(region));
  }
  caseAttr = parser.getBuilder().getArrayAttr(caseAttrs);
  return success();
}

template <typename PrintCaseFn>
void printSwitchCases(OpAsmPrinter &p, ArrayAttr caseAttr,
                      MutableArrayRef<Region> caseRegions,
                      PrintCaseFn printCase) {
  for (auto [attr, region] : llvm::zip(caseAttr, caseRegions)) {
    p.printNewline();
    p << "case ";
    printCase(p, attr);
    p << ' ';
    p.printRegion(region, /*printEntryBlockArgs=*/false);
  }
}

} // namespace

ParseResult SwitchOpNameOp::parse(OpAsmParser &parser, OperationState &result) {
  OpAsmParser::UnresolvedOperand op;
  Type opType;
  if (parser.parseOperand(op))
    return failure();

  ArrayAttr cases;
  SmallVector<std::unique_ptr<Region>> caseRegions;
  if (parseSwitchCases(parser, cases, caseRegions,
                       [](OpAsmParser &p, Attribute &out) -> ParseResult {
                         std::string name;
                         if (p.parseString(&name))
                           return failure();
                         out = p.getBuilder().getStringAttr(name);
                         return success();
                       }))
    return failure();

  if (parser.parseOptionalAttrDict(result.attributes))
    return failure();
  result.addAttribute("caseNames", cases);

  opType = parser.getBuilder().getType<pdl::OperationType>();
  if (parser.resolveOperand(op, opType, result.operands))
    return failure();

  for (auto &region : caseRegions)
    result.addRegion(std::move(region));
  return success();
}

void SwitchOpNameOp::print(OpAsmPrinter &p) {
  p << ' ' << getOp();
  printSwitchCases(p, getCaseNames(), getCaseRegions(),
                   [](OpAsmPrinter &p, Attribute attr) {
                     p.printAttributeWithoutType(attr);
                   });
  p.printOptionalAttrDict((*this)->getAttrs(), /*elidedAttrs=*/{"caseNames"});
}

LogicalResult SwitchOpNameOp::verify() {
  if (getCaseNames().size() != getCaseRegions().size())
    return emitOpError("expected one region per case name (")
           << getCaseNames().size() << " names vs " << getCaseRegions().size()
           << " regions)";
  for (Attribute attr : getCaseNames()) {
    if (!llvm::isa<StringAttr>(attr))
      return emitOpError("case names must be string attributes");
  }
  return success();
}

StringRef SwitchOpNameOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

ParseResult SwitchTypeOp::parse(OpAsmParser &parser, OperationState &result) {
  OpAsmParser::UnresolvedOperand type;
  if (parser.parseOperand(type))
    return failure();

  ArrayAttr cases;
  SmallVector<std::unique_ptr<Region>> caseRegions;
  if (parseSwitchCases(parser, cases, caseRegions,
                       [](OpAsmParser &p, Attribute &out) -> ParseResult {
                         Type t;
                         if (p.parseType(t))
                           return failure();
                         out = TypeAttr::get(t);
                         return success();
                       }))
    return failure();

  if (parser.parseOptionalAttrDict(result.attributes))
    return failure();
  result.addAttribute("caseTypes", cases);

  Type pdlType = parser.getBuilder().getType<pdl::TypeType>();
  if (parser.resolveOperand(type, pdlType, result.operands))
    return failure();

  for (auto &region : caseRegions)
    result.addRegion(std::move(region));
  return success();
}

void SwitchTypeOp::print(OpAsmPrinter &p) {
  p << ' ' << getTypeValue();
  printSwitchCases(p, getCaseTypes(), getCaseRegions(),
                   [](OpAsmPrinter &p, Attribute attr) {
                     p.printType(llvm::cast<TypeAttr>(attr).getValue());
                   });
  p.printOptionalAttrDict((*this)->getAttrs(), /*elidedAttrs=*/{"caseTypes"});
}

LogicalResult SwitchTypeOp::verify() {
  if (getCaseTypes().size() != getCaseRegions().size())
    return emitOpError("expected one region per case type (")
           << getCaseTypes().size() << " types vs " << getCaseRegions().size()
           << " regions)";
  for (Attribute attr : getCaseTypes()) {
    if (!llvm::isa<TypeAttr>(attr))
      return emitOpError("case types must be type attributes");
  }
  return success();
}

StringRef SwitchTypeOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

static Type getGetValueTypeOpValueType(Type type) {
  Type valueTy = pdl::ValueType::get(type.getContext());
  return llvm::isa<pdl::RangeType>(type) ? pdl::RangeType::get(valueTy)
                                         : valueTy;
}

void ForEachOp::build(OpBuilder &builder, OperationState &result, Value range) {
  result.addOperands(range);
  Region *body = result.addRegion();
  Block &block = body->emplaceBlock();
  block.addArgument(
      llvm::cast<pdl::RangeType>(range.getType()).getElementType(),
      result.location);
}

ParseResult ForEachOp::parse(OpAsmParser &parser, OperationState &result) {
  OpAsmParser::Argument loopVar;
  OpAsmParser::UnresolvedOperand range;
  Type rangeType;
  if (parser.parseArgument(loopVar) || parser.parseKeyword("in") ||
      parser.parseOperand(range) || parser.parseColonType(rangeType))
    return failure();

  auto pdlRangeType = llvm::dyn_cast<pdl::RangeType>(rangeType);
  if (!pdlRangeType)
    return parser.emitError(parser.getNameLoc(),
                            "expected the iterated value to be a !pdl.range "
                            "type, but got ")
           << rangeType;

  if (parser.resolveOperand(range, rangeType, result.operands))
    return failure();

  loopVar.type = pdlRangeType.getElementType();

  Region *body = result.addRegion();
  return failure(parser.parseRegion(*body, loopVar) ||
                 parser.parseOptionalAttrDict(result.attributes));
}

void ForEachOp::print(OpAsmPrinter &p) {
  Region &body = getBody();
  p << ' ';
  if (!body.empty() && body.front().getNumArguments() == 1)
    p << body.front().getArgument(0);
  else
    p << "<<invalid loop variable>>";
  p << " in " << getRange() << " : " << getRange().getType() << ' ';
  p.printRegion(body, /*printEntryBlockArgs=*/false);
  p.printOptionalAttrDict((*this)->getAttrs());
}

LogicalResult ForEachOp::verifyRegions() {
  Block &block = getBody().front();
  if (block.getNumArguments() != 1)
    return emitOpError("expected body block to have exactly one argument (the "
                       "loop variable)");

  Type elementType = getElementType();
  if (block.getArgument(0).getType() != elementType)
    return emitOpError("expected the loop variable to have the element type of "
                       "the iterated range, got ")
           << block.getArgument(0).getType() << " but expected " << elementType;

  if (!regionContainsSuccess(getBody()))
    return emitOpError("`match.foreach` body contains no "
                       "`match.success` (directly or transitively); the "
                       "region is dead");

  return success();
}

StringRef ForEachOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

LogicalResult ApplyNativeConstraintOp::verify() {
  if (getNumOperands() == 0)
    return emitOpError("expected at least one argument");
  if (llvm::any_of(getConstraintResults(), [](OpResult result) {
        return isa<pdl::OperationType>(result.getType());
      })) {
    return emitOpError(
        "returning an operation from a constraint is not supported");
  }
  return success();
}

LogicalResult ApplyNativeRewriteOp::verify() {
  if (getNumOperands() == 0 && getNumResults() == 0)
    return emitOpError("expected at least one argument or result");
  return success();
}

LogicalResult SuccessOp::verify() {
  if (!(*this)->getParentOfType<MatcherOp>())
    return emitOpError("`match.success` must be enclosed by a `match.matcher`");
  return success();
}

LogicalResult SuccessOp::verifySymbolUses(SymbolTableCollection &symbolTable) {
  if (!symbolTable.lookupNearestSymbolFrom(*this, getRewriterAttr()))
    return emitOpError("references an unknown rewriter symbol: ")
           << getRewriterAttr();
  return success();
}

void RewriterOp::build(OpBuilder &builder, OperationState &result,
                       StringRef name) {
  result.addAttribute(SymbolTable::getSymbolAttrName(),
                      builder.getStringAttr(name));
  result.addRegion()->emplaceBlock();
}

ParseResult RewriterOp::parse(OpAsmParser &parser, OperationState &result) {
  StringAttr name;
  SmallVector<OpAsmParser::Argument> args;
  StringRef visibility;
  if (succeeded(parser.parseOptionalKeyword(&visibility,
                                            {"public", "private", "nested"})))
    result.addAttribute("sym_visibility",
                        parser.getBuilder().getStringAttr(visibility));
  if (parser.parseSymbolName(name, SymbolTable::getSymbolAttrName(),
                             result.attributes) ||
      parser.parseArgumentList(args, OpAsmParser::Delimiter::Paren,
                               /*allowType=*/true) ||
      parser.parseOptionalAttrDictWithKeyword(result.attributes))
    return failure();
  return parser.parseRegion(*result.addRegion(), args);
}

void RewriterOp::print(OpAsmPrinter &p) {
  p << ' ';
  if (std::optional<StringRef> visibility = getSymVisibility())
    p << *visibility << ' ';
  p.printSymbolName(getSymName());
  p << '(';
  llvm::interleaveComma(getBody().getArguments(), p,
                        [&](BlockArgument arg) { p.printRegionArgument(arg); });
  p << ')';
  p.printOptionalAttrDictWithKeyword(
      (*this)->getAttrs(),
      {SymbolTable::getSymbolAttrName(), "sym_visibility"});
  p << ' ';
  p.printRegion(getBody(), /*printEntryBlockArgs=*/false);
}

LogicalResult RewriterOp::verifyRegions() {
  for (BlockArgument arg : getBody().getArguments())
    if (!isa<pdl::PDLType>(arg.getType()))
      return emitOpError("expected rewriter arguments to have PDL types, but "
                         "got ")
             << arg.getType();
  for (Operation &op : getBody().front()) {
    if (!isa_and_present<MatchDialect, pdl::PDLDialect>(op.getDialect()))
      continue;
    if (!isa<ApplyNativeRewriteOp, ConstantAttributeOp, ConstantTypeOp,
             ConstantTypesOp, CreateOperationOp, CreateRangeOp, EraseOp,
             GetValueTypeOp, ReplaceOp, pdl::ResultOp, pdl::ResultsOp>(op))
      return op.emitOpError("is not allowed in a `match.rewriter`");
  }
  return success();
}

StringRef RewriterOp::getDefaultDialect() {
  return MatchDialect::getDialectNamespace();
}

LogicalResult CreateOperationOp::verify() {
  if (getInferredResultTypes() && !getInputResultTypes().empty())
    return emitOpError("with inferred results cannot also have "
                       "explicit result types");
  return success();
}

static ParseResult parseCreateOperationOpAttributes(
    OpAsmParser &p,
    SmallVectorImpl<OpAsmParser::UnresolvedOperand> &attrOperands,
    ArrayAttr &attrNamesAttr) {
  SmallVector<Attribute, 4> attrNames;
  if (succeeded(p.parseOptionalLBrace())) {
    auto parseOperands = [&]() {
      StringAttr nameAttr;
      OpAsmParser::UnresolvedOperand operand;
      if (p.parseAttribute(nameAttr) || p.parseEqual() ||
          p.parseOperand(operand))
        return failure();
      attrNames.push_back(nameAttr);
      attrOperands.push_back(operand);
      return success();
    };
    if (p.parseCommaSeparatedList(parseOperands) || p.parseRBrace())
      return failure();
  }
  attrNamesAttr = p.getBuilder().getArrayAttr(attrNames);
  return success();
}

static void printCreateOperationOpAttributes(OpAsmPrinter &p,
                                             CreateOperationOp op,
                                             OperandRange attrArgs,
                                             ArrayAttr attrNames) {
  if (attrNames.empty())
    return;
  p << " {";
  interleaveComma(llvm::seq<int>(0, attrNames.size()), p,
                  [&](int i) { p << attrNames[i] << " = " << attrArgs[i]; });
  p << '}';
}

static ParseResult parseCreateOperationOpResults(
    OpAsmParser &p,
    SmallVectorImpl<OpAsmParser::UnresolvedOperand> &resultOperands,
    SmallVectorImpl<Type> &resultTypes, UnitAttr &inferredResultTypes) {
  if (failed(p.parseOptionalArrow()))
    return success();
  if (succeeded(p.parseOptionalLess())) {
    if (p.parseKeyword("inferred") || p.parseGreater())
      return failure();
    inferredResultTypes = p.getBuilder().getUnitAttr();
    return success();
  }
  return failure(p.parseLParen() || p.parseOperandList(resultOperands) ||
                 p.parseColonTypeList(resultTypes) || p.parseRParen());
}

static void printCreateOperationOpResults(OpAsmPrinter &p, CreateOperationOp op,
                                          OperandRange resultOperands,
                                          TypeRange resultTypes,
                                          UnitAttr inferredResultTypes) {
  if (inferredResultTypes) {
    p << " -> <inferred>";
    return;
  }
  if (!resultTypes.empty())
    p << " -> (" << resultOperands << " : " << resultTypes << ")";
}

static ParseResult parseRangeType(OpAsmParser &p, TypeRange argumentTypes,
                                  Type &resultType) {
  if (!argumentTypes.empty()) {
    resultType =
        pdl::RangeType::get(pdl::getRangeElementTypeOrSelf(argumentTypes[0]));
    return success();
  }
  return p.parseColonType(resultType);
}

static void printRangeType(OpAsmPrinter &p, CreateRangeOp op,
                           TypeRange argumentTypes, Type resultType) {
  if (argumentTypes.empty())
    p << ": " << resultType;
}

LogicalResult CreateRangeOp::verify() {
  Type elementType = getType().getElementType();
  for (Type operandType : getOperandTypes()) {
    Type operandElementType = pdl::getRangeElementTypeOrSelf(operandType);
    if (operandElementType != elementType)
      return emitOpError("expected operand to have element type ")
             << elementType << ", but got " << operandElementType;
  }
  return success();
}

#define GET_OP_CLASSES
#include "mlir/Dialect/Match/IR/MatchOps.cpp.inc"
