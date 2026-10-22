//===- PDLToMatch.cpp - Lower PDL patterns to match matchers --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/PDLToMatch/PDLToMatch.h"

#include "RewriterGen.h"
#include "RootOrdering.h"
#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/Dialect/Match/IR/MatchTypes.h"
#include "mlir/Dialect/PDL/IR/PDLOps.h"
#include "mlir/Dialect/PDL/IR/PDLTypes.h"
#include "mlir/Dialect/PDLInterp/IR/PDLInterp.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/TypeSwitch.h"
#include <cassert>
#include <climits>
#include <llvm/ADT/STLExtras.h>
#include <llvm/ADT/SmallVectorExtras.h>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/MLIRContext.h>
#include <mlir/IR/Types.h>
#include <mlir/IR/Value.h>
#include <mlir/IR/ValueRange.h>
#include <mlir/Support/LLVM.h>
#include <optional>
#include <queue>

namespace mlir {
#define GEN_PASS_DEF_CONVERTPDLTOMATCHPASS
#include "mlir/Conversion/MatchConversionPasses.h.inc"
} // namespace mlir

using namespace mlir;
using namespace mlir::pdl_to_match;

namespace {
struct OpIndex {
  Value parent;
  std::optional<unsigned> index;
};
} // namespace

using ParentMaps = DenseMap<Value, DenseMap<Value, OpIndex>>;

static bool isRange(Value value) {
  return isa<pdl::RangeType>(value.getType());
}

static unsigned getNumNonRangeValues(ValueRange values) {
  return llvm::count_if(values, [](Value value) { return !isRange(value); });
}

static bool useOperandGroup(pdl::OperationOp op, unsigned index) {
  OperandRange operands = op.getOperandValues();
  return llvm::any_of(operands.take_front(index + 1), isRange);
}

static SmallVector<Value> detectRoots(pdl::PatternOp pattern) {
  DenseSet<Value> used;
  for (auto operationOp : pattern.getBodyRegion().getOps<pdl::OperationOp>()) {
    for (Value operand : operationOp.getOperandValues())
      TypeSwitch<Operation *>(operand.getDefiningOp())
          .Case<pdl::ResultOp, pdl::ResultsOp>(
              [&used](auto resultOp) { used.insert(resultOp.getParent()); });
  }
  if (Value root = pattern.getRewriter().getRoot())
    used.erase(root);

  SmallVector<Value> roots;
  for (Value operationOp : pattern.getBodyRegion().getOps<pdl::OperationOp>())
    if (!used.contains(operationOp))
      roots.push_back(operationOp);
  return roots;
}

static void buildCostGraph(ArrayRef<Value> roots, RootOrderingGraph &graph,
                           ParentMaps &parentMaps) {
  struct Entry {
    Value value;
    Value parent;
    std::optional<unsigned> index;
    unsigned depth;
  };
  struct RootDepth {
    Value root;
    unsigned depth = 0;
  };
  llvm::MapVector<Value, SmallVector<RootDepth, 1>> connectorsRootsDepths;

  for (Value root : roots) {
    std::queue<Entry> toVisit;
    toVisit.push({root, Value(), 0, 0});
    DenseMap<Value, OpIndex> &parentMap = parentMaps[root];
    while (!toVisit.empty()) {
      Entry entry = toVisit.front();
      toVisit.pop();
      if (!parentMap.insert({entry.value, {entry.parent, entry.index}}).second)
        continue;
      connectorsRootsDepths[entry.value].push_back({root, entry.depth});

      TypeSwitch<Operation *>(entry.value.getDefiningOp())
          .Case([&](pdl::OperationOp operationOp) {
            OperandRange operands = operationOp.getOperandValues();
            if (operands.size() == 1 && isRange(operands[0])) {
              toVisit.push(
                  {operands[0], entry.value, std::nullopt, entry.depth + 1});
              return;
            }
            for (auto [i, operand] : llvm::enumerate(operands))
              toVisit.push({operand, entry.value, static_cast<unsigned>(i),
                            entry.depth + 1});
          })
          .Case<pdl::ResultOp, pdl::ResultsOp>([&](auto resultOp) {
            toVisit.push({resultOp.getParent(), entry.value,
                          resultOp.getIndex(), entry.depth});
          });
    }
  }

  unsigned nextID = 0;
  for (auto &[value, rootsDepths] : connectorsRootsDepths) {
    if (rootsDepths.size() == 1)
      continue;
    for (const RootDepth &p : rootsDepths) {
      for (const RootDepth &q : rootsDepths) {
        if (&p == &q)
          continue;
        RootOrderingEntry &entry = graph[q.root][p.root];
        if (!entry.connector || entry.cost.first > q.depth) {
          if (!entry.connector)
            entry.cost.second = nextID++;
          entry.cost.first = q.depth;
          entry.connector = value;
        }
      }
    }
  }
  assert((llvm::hasSingleElement(roots) || graph.size() == roots.size()) &&
         "the pattern contains a candidate root disconnected from the others");
}

namespace {
struct EmitterCache {
  explicit EmitterCache(MLIRContext *ctx) {
    Type value = pdl::ValueType::get(ctx), type = pdl::TypeType::get(ctx);
    valueTypes[0] = value;
    valueTypes[1] = pdl::RangeType::get(value);
    typeTypes[0] = type;
    typeTypes[1] = pdl::RangeType::get(type);
  }

  Type valueTypes[2];
  Type typeTypes[2];
  DenseMap<Type, Type> optionalTypes;
  SmallVector<IntegerAttr> indexAttrs;
};

class MatchEmitter {
public:
  MatchEmitter(OpBuilder &builder, pdl::PatternOp pattern,
               SymbolTable &rewriterSymbolTable,
               function_ref<bool(StringRef)> canInferResultTypes,
               EmitterCache &cache)
      : builder(builder), pattern(pattern), loc(pattern.getLoc()),
        rewriterSymbolTable(rewriterSymbolTable),
        canInferResultTypes(canInferResultTypes), cache(cache) {}

  FailureOr<match::RewriterOp> emit();

private:
  void emitOperationConstraints(pdl::OperationOp op, Value opVal,
                                std::optional<unsigned> ignoreOperand = {});
  void emitOperandConstraints(Value pdlVal, Value val);
  void emitAttributeConstraints(pdl::AttributeOp attrOp, Value val);
  void emitTypeConstraints(Value pdlVal, Value val);
  void emitUpwardTraversal(OpIndex opIndex, Value &pos);
  LogicalResult emitNonTreePredicates();
  bool registerValue(Value pdlVal, Value val);
  Value getOrMaterialize(Value pdlVal);

  Type valueType(bool range) { return cache.valueTypes[range]; }

  Type typeType(bool range) { return cache.typeTypes[range]; }

  IntegerAttr indexAttr(std::optional<unsigned> index) {
    if (!index)
      return IntegerAttr();
    SmallVector<IntegerAttr> &attrs = cache.indexAttrs;
    while (attrs.size() <= *index)
      attrs.push_back(builder.getI32IntegerAttr(attrs.size()));
    return attrs[*index];
  }

  template <typename OpT, typename... Args>
  Value navigate(Type type, Args &&...args) {
    Type &optionalType = cache.optionalTypes[type];
    if (!optionalType)
      optionalType = match::OptionalType::get(type);
    Value optional = OpT::create(builder, loc, optionalType,
                                 std::forward<Args>(args)...);
    return match::IsNotNullOp::create(builder, loc, type, optional)
        .getUnwrapped();
  }

  Value getOperand(Value op, unsigned index) {
    return navigate<match::GetOperandOp>(valueType(false), op,
                                         indexAttr(index));
  }

  Value getOperands(Value op, std::optional<unsigned> index, bool range) {
    return navigate<match::GetOperandsOp>(valueType(range), op,
                                          indexAttr(index));
  }

  Value getResult(Value op, unsigned index) {
    return navigate<match::GetResultOp>(valueType(false), op, indexAttr(index));
  }

  Value getResults(Value op, std::optional<unsigned> index, bool range) {
    return navigate<match::GetResultsOp>(valueType(range), op,
                                         indexAttr(index));
  }

  template <typename CountOp>
  void emitCount(Value opVal, ValueRange values) {
    unsigned min = getNumNonRangeValues(values);
    bool atLeast = min != values.size();
    if (!atLeast || min)
      CountOp::create(builder, loc, opVal, builder.getI32IntegerAttr(min),
                      atLeast ? builder.getUnitAttr() : UnitAttr());
  }

  Value getValueType(Value value) {
    return match::GetValueTypeOp::create(builder, loc, typeType(isRange(value)),
                                         value);
  }

  OpBuilder &builder;
  pdl::PatternOp pattern;
  Location loc;
  SymbolTable &rewriterSymbolTable;
  function_ref<bool(StringRef)> canInferResultTypes;
  EmitterCache &cache;
  DenseMap<Value, Value> valueMap;
};
} // namespace

bool MatchEmitter::registerValue(Value pdlVal, Value val) {
  auto [it, inserted] = valueMap.try_emplace(pdlVal, val);
  if (inserted)
    return true;
  if (isa_and_nonnull<pdl::ApplyNativeConstraintOp, pdl::AttributeOp,
                      pdl::OperandOp, pdl::OperandsOp, pdl::OperationOp,
                      pdl::TypeOp, pdl::TypesOp>(pdlVal.getDefiningOp()))
    match::EqualOp::create(builder, loc, val, it->second);
  return false;
}

Value MatchEmitter::getOrMaterialize(Value pdlVal) {
  if (Value mapped = valueMap.lookup(pdlVal))
    return mapped;

  Value materialized;
  if (auto attrOp = pdlVal.getDefiningOp<pdl::AttributeOp>()) {
    if (Attribute value = attrOp.getValueAttr())
      materialized = match::ConstantAttributeOp::create(builder, loc, value);
  } else if (auto typeOp = pdlVal.getDefiningOp<pdl::TypeOp>()) {
    if (TypeAttr value = typeOp.getConstantTypeAttr())
      materialized = match::ConstantTypeOp::create(builder, loc, value);
  } else if (auto typesOp = pdlVal.getDefiningOp<pdl::TypesOp>()) {
    if (ArrayAttr value = typesOp.getConstantTypesAttr())
      materialized = match::ConstantTypesOp::create(builder, loc, value);
  }
  if (materialized)
    valueMap[pdlVal] = materialized;
  return materialized;
}

void MatchEmitter::emitTypeConstraints(Value pdlVal, Value val) {
  if (auto typeOp = pdlVal.getDefiningOp<pdl::TypeOp>()) {
    if (TypeAttr type = typeOp.getConstantTypeAttr())
      match::HasTypeOp::create(builder, loc, val, type);
  } else if (auto typesOp = pdlVal.getDefiningOp<pdl::TypesOp>()) {
    if (ArrayAttr types = typesOp.getConstantTypesAttr())
      match::HasTypesOp::create(builder, loc, val, types);
  }
}

void MatchEmitter::emitAttributeConstraints(pdl::AttributeOp attrOp,
                                            Value val) {
  if (Value type = attrOp.getValueType()) {
    Value typeVal = match::GetAttributeTypeOp::create(
        builder, loc, builder.getType<pdl::TypeType>(), val);
    if (registerValue(type, typeVal))
      emitTypeConstraints(type, typeVal);
  } else if (Attribute value = attrOp.getValueAttr()) {
    match::HasAttrValueOp::create(builder, loc, val, value);
  }
}

void MatchEmitter::emitOperandConstraints(Value pdlVal, Value val) {
  TypeSwitch<Operation *>(pdlVal.getDefiningOp())
      .Case<pdl::OperandOp, pdl::OperandsOp>([&](auto op) {
        if (Value type = op.getValueType()) {
          Value typeVal = getValueType(val);
          if (registerValue(type, typeVal))
            emitTypeConstraints(type, typeVal);
        }
      })
      .Case([&](pdl::ResultOp op) {
        Value defOp = navigate<match::GetDefiningOpOp>(
            builder.getType<pdl::OperationType>(), val);
        Value result = getResult(defOp, op.getIndex());
        match::EqualOp::create(builder, loc, result, val);
        if (registerValue(op.getParent(), defOp))
          emitOperationConstraints(
              op.getParent().getDefiningOp<pdl::OperationOp>(), defOp);
      })
      .Case([&](pdl::ResultsOp op) {
        Value defOp = navigate<match::GetDefiningOpOp>(
            builder.getType<pdl::OperationType>(), val);
        Value result = getResults(defOp, op.getIndex(), isRange(pdlVal));
        match::EqualOp::create(builder, loc, result, val);
        if (registerValue(op.getParent(), defOp))
          emitOperationConstraints(
              op.getParent().getDefiningOp<pdl::OperationOp>(), defOp);
      });
}

void MatchEmitter::emitOperationConstraints(
    pdl::OperationOp op, Value opVal, std::optional<unsigned> ignoreOperand) {
  if (std::optional<StringRef> name = op.getOpName())
    match::HasNameOp::create(builder, loc, opVal, builder.getStringAttr(*name));

  OperandRange operands = op.getOperandValues();
  OperandRange types = op.getTypeValues();
  emitCount<match::CheckOperandCountOp>(opVal, operands);
  emitCount<match::CheckResultCountOp>(opVal, types);

  for (auto [name, attr] :
       llvm::zip(op.getAttributeValueNames(), op.getAttributeValues())) {
    Value attrVal = navigate<match::GetAttributeOp>(
        builder.getType<pdl::AttributeType>(), opVal, cast<StringAttr>(name));
    if (registerValue(attr, attrVal))
      if (auto attrOp = attr.getDefiningOp<pdl::AttributeOp>())
        emitAttributeConstraints(attrOp, attrVal);
  }

  if (operands.size() == 1 && isRange(operands[0])) {
    Value val = getOperands(opVal, std::nullopt, /*range=*/true);
    if (registerValue(operands[0], val))
      emitOperandConstraints(operands[0], val);
  } else {
    bool foundVariadic = false;
    for (auto [i, operand] : llvm::enumerate(operands)) {
      foundVariadic |= isRange(operand);
      if (ignoreOperand == i)
        continue;
      Value val = foundVariadic ? getOperands(opVal, i, isRange(operand))
                                : getOperand(opVal, i);
      if (registerValue(operand, val))
        emitOperandConstraints(operand, val);
    }
  }

  if (types.size() == 1 && isRange(types[0])) {
    Value typeVal =
        getValueType(getResults(opVal, std::nullopt, /*range=*/true));
    if (registerValue(types[0], typeVal))
      emitTypeConstraints(types[0], typeVal);
    return;
  }
  bool foundVariadic = false;
  for (auto [i, type] : llvm::enumerate(types)) {
    foundVariadic |= isRange(type);
    Value result = foundVariadic ? getResults(opVal, i, isRange(type))
                                 : getResult(opVal, i);
    Value typeVal = getValueType(result);
    if (registerValue(type, typeVal))
      emitTypeConstraints(type, typeVal);
  }
}

void MatchEmitter::emitUpwardTraversal(OpIndex opIndex, Value &pos) {
  Value value = opIndex.parent;
  TypeSwitch<Operation *>(value.getDefiningOp())
      .Case([&](pdl::OperationOp operationOp) {
        Value userPos = pos;
        if (isRange(pos))
          userPos = match::ExtractOp::create(builder, loc, pos, 0);
        Value users = match::GetUsersOp::create(
            builder, loc,
            pdl::RangeType::get(builder.getType<pdl::OperationType>()),
            userPos);
        auto loop = match::ForEachOp::create(builder, loc, users);
        builder.setInsertionPointToStart(&loop.getBody().front());
        Value opVal = loop.getLoopVariable();

        Value operandVal;
        if (!opIndex.index)
          operandVal = getOperands(opVal, std::nullopt, /*range=*/true);
        else if (useOperandGroup(operationOp, *opIndex.index))
          operandVal = getOperands(
              opVal, opIndex.index,
              isRange(operationOp.getOperandValues()[*opIndex.index]));
        else
          operandVal = getOperand(opVal, *opIndex.index);
        match::EqualOp::create(builder, loc, operandVal, pos);

        valueMap.try_emplace(value, opVal);
        emitOperationConstraints(operationOp, opVal, opIndex.index);
        pos = opVal;
      })
      .Case([&](pdl::ResultOp) {
        pos = getResult(pos, *opIndex.index);
        valueMap.try_emplace(value, pos);
      })
      .Case([&](pdl::ResultsOp) {
        pos = getResults(pos, opIndex.index, isRange(value));
        valueMap.try_emplace(value, pos);
      });
}

LogicalResult MatchEmitter::emitNonTreePredicates() {
  for (Operation &op : pattern.getBodyRegion().getOps()) {
    if (auto constraintOp = dyn_cast<pdl::ApplyNativeConstraintOp>(op)) {
      SmallVector<Value> args;
      for (Value arg : constraintOp.getArgs()) {
        Value mapped = getOrMaterialize(arg);
        if (!mapped)
          return constraintOp.emitError(
              "constraint argument is not reachable from the pattern root and "
              "is not a constant");
        args.push_back(mapped);
      }
      auto newOp = match::ApplyNativeConstraintOp::create(
          builder, loc, constraintOp.getResultTypes(),
          constraintOp.getNameAttr(), args, constraintOp.getIsNegatedAttr());
      for (auto [from, to] :
           llvm::zip(constraintOp.getResults(), newOp.getResults()))
        registerValue(from, to);
    } else if (auto resultOp = dyn_cast<pdl::ResultOp>(op)) {
      Value parent = valueMap.lookup(resultOp.getParent());
      if (parent && !valueMap.contains(resultOp))
        valueMap[resultOp] = getResult(parent, resultOp.getIndex());
    } else if (auto resultsOp = dyn_cast<pdl::ResultsOp>(op)) {
      Value parent = valueMap.lookup(resultsOp.getParent());
      if (parent && !valueMap.contains(resultsOp))
        valueMap[resultsOp] =
            getResults(parent, resultsOp.getIndex(), isRange(resultsOp));
    }
  }
  return success();
}

FailureOr<match::RewriterOp> MatchEmitter::emit() {
  SmallVector<Value> roots = detectRoots(pattern);
  RootOrderingGraph graph;
  ParentMaps parentMaps;
  buildCostGraph(roots, graph, parentMaps);

  Value bestRoot = pattern.getRewriter().getRoot();
  OptimalBranching::EdgeList bestEdges;
  if (!bestRoot) {
    unsigned bestCost = UINT_MAX;
    for (Value root : roots) {
      OptimalBranching solver(graph, root);
      unsigned cost = solver.solve();
      if (!bestRoot || cost < bestCost) {
        bestCost = cost;
        bestRoot = root;
        bestEdges = solver.preOrderTraversal(roots);
      }
    }
  } else {
    OptimalBranching solver(graph, bestRoot);
    solver.solve();
    bestEdges = solver.preOrderTraversal(roots);
  }

  auto matcher =
      match::MatcherOp::create(builder, loc, pattern.getSymNameAttr());
  Block *body = &matcher.getBodyRegion().emplaceBlock();
  Value rootArg = body->addArgument(builder.getType<pdl::OperationType>(), loc);
  OpBuilder::InsertionGuard guard(builder);
  builder.setInsertionPointToStart(body);

  valueMap[bestRoot] = rootArg;
  emitOperationConstraints(bestRoot.getDefiningOp<pdl::OperationOp>(), rootArg);

  for (auto [target, source] : bestEdges) {
    if (valueMap.contains(target))
      continue;
    Value connector = graph[target][source].connector;
    Value pos = valueMap.lookup(connector);
    const DenseMap<Value, OpIndex> &parentMap = parentMaps[target];
    for (Value value = connector; value != target;) {
      OpIndex opIndex = parentMap.lookup(value);
      emitUpwardTraversal(opIndex, pos);
      value = opIndex.parent;
    }
  }

  if (failed(emitNonTreePredicates())) {
    matcher.erase();
    return failure();
  }

  SmallVector<Value> usedMatchValues;
  match::RewriterOp rewriter = generateRewriter(
      pattern, rewriterSymbolTable, usedMatchValues, canInferResultTypes);
  SmallVector<Value> inputs = llvm::map_to_vector(
      usedMatchValues, [&](Value value) { return valueMap.lookup(value); });
  auto rewriterRef =
      SymbolRefAttr::get(builder.getContext(),
                         pdl_interp::PDLInterpDialect::getRewriterModuleName(),
                         SymbolRefAttr::get(rewriter));
  match::SuccessOp::create(builder, loc, rewriterRef,
                           builder.getI16IntegerAttr(pattern.getBenefit()),
                           inputs);
  return rewriter;
}

LogicalResult
mlir::convertPDLToMatch(ModuleOp module,
                        DenseMap<Operation *, PDLPatternConfigSet *> *configMap,
                        function_ref<bool(StringRef)> canInferResultTypes) {
  OpBuilder builder = OpBuilder::atBlockBegin(module.getBody());
  auto rewriterModule =
      ModuleOp::create(builder, module.getLoc(),
                       pdl_interp::PDLInterpDialect::getRewriterModuleName());
  SymbolTable rewriterSymbolTable(rewriterModule);
  EmitterCache cache(module.getContext());

  LogicalResult result = success();
  for (pdl::PatternOp pattern :
       llvm::make_early_inc_range(module.getOps<pdl::PatternOp>())) {
    builder.setInsertionPoint(pattern);
    FailureOr<match::RewriterOp> rewriter =
        MatchEmitter(builder, pattern, rewriterSymbolTable, canInferResultTypes,
                     cache)
            .emit();
    if (failed(rewriter)) {
      result = failure();
      continue;
    }
    if (configMap) {
      if (PDLPatternConfigSet *config = configMap->lookup(pattern))
        (*configMap)[*rewriter] = config;
      configMap->erase(pattern);
    }
    pattern.erase();
  }
  return result;
}

namespace {
struct PDLToMatchPass : public impl::ConvertPDLToMatchPassBase<PDLToMatchPass> {
  void runOnOperation() final {
    if (failed(convertPDLToMatch(getOperation())))
      signalPassFailure();
  }
};
} // namespace
