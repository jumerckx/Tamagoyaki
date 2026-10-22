//===- CombineMatchers.cpp - Combine match.matcher ops --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/Match/Transforms/Passes.h"

#include "mlir/Dialect/Match/IR/Match.h"
#include "mlir/Dialect/Match/IR/MatchOps.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/STLExtras.h"
#include <algorithm>
#include <cassert>
#include <iterator>
#include <llvm/ADT/DenseMapInfo.h>
#include <llvm/ADT/Hashing.h>
#include <memory>
#include <mlir/Dialect/PDL/IR/PDLTypes.h>
#include <mlir/IR/Attributes.h>
#include <mlir/IR/Block.h>
#include <mlir/IR/Builders.h>
#include <mlir/IR/BuiltinAttributes.h>
#include <mlir/IR/Location.h>
#include <mlir/IR/Operation.h>
#include <mlir/IR/Region.h>
#include <mlir/IR/Value.h>
#include <mlir/Support/LLVM.h>
#include <string>
#include <tuple>
#include <utility>
#include <vector>

namespace mlir {
namespace match {
#define GEN_PASS_DEF_MATCHCOMBINEMATCHERSPASS
#include "mlir/Dialect/Match/Transforms/Passes.h.inc"
} // namespace match
} // namespace mlir

using namespace mlir;
using namespace mlir::match;

namespace {
struct PoolKey {
  Operation *op;
  SmallVector<Value, 4> operands;
  bool ignoreAttrs = false;

  bool operator==(const PoolKey &o) const {
    if (op->getName() != o.op->getName() || operands != o.operands ||
        ignoreAttrs != o.ignoreAttrs)
      return false;
    if (ignoreAttrs || op == o.op)
      return true;
    return op->getRawDictionaryAttrs() == o.op->getRawDictionaryAttrs() &&
           op->getName().compareOpProperties(op->getPropertiesStorage(),
                                             o.op->getPropertiesStorage());
  }
};
} // namespace

namespace llvm {
template <>
struct DenseMapInfo<PoolKey> {
  static unsigned getHashValue(const PoolKey &k) {
    llvm::hash_code operands =
        llvm::hash_combine_range(k.operands.begin(), k.operands.end());
    if (k.ignoreAttrs)
      return llvm::hash_combine(k.op->getName(), operands);
    return llvm::hash_combine(k.op->getName(), k.op->getRawDictionaryAttrs(),
                              k.op->hashProperties(), operands);
  }
  static bool isEqual(const PoolKey &a, const PoolKey &b) { return a == b; }
};
} // namespace llvm

namespace {
struct MatcherInfo {
  MatcherOp matcher;
  SuccessOp success;
  DenseSet<Operation *> preds;
  DenseSet<Operation *> questions;
  SmallVector<Operation *> guards;
  SmallVector<Operation *> orderedPreds;
  IRMapping toCanonical;
};

struct TreeNode {
  enum class Kind { Test, Success };
  Kind kind;
  Operation *pred = nullptr;
  std::unique_ptr<TreeNode> successPath;
  std::unique_ptr<TreeNode> failurePath;
  SuccessOp originalSuccess;
  SmallVector<Value, 4> successInputs;
};

class Combiner {
public:
  Combiner(ModuleOp module, ArrayRef<MatcherOp> inputMatchers,
           StringRef combinedName, bool deferLoops)
      : module(module), inputMatchers(inputMatchers),
        combinedName(combinedName), deferLoops(deferLoops) {}
  LogicalResult run();

private:
  LogicalResult buildCanonicalPool();
  LogicalResult collectPredicates(Block &block, MatcherInfo &info);
  void sortCanonicalPool();
  void emitCombinedMatcher();

  Operation *getOrCreatePoolOp(Operation *modelOp,
                               ArrayRef<Value> canonicalOperands,
                               const DenseSet<Operation *> &alreadyUsed);
  void propagate(std::unique_ptr<TreeNode> &node, MatcherInfo &info,
                 unsigned predIdx);
  void emitNode(OpBuilder &builder, Location loc, TreeNode *node,
                IRMapping &mapping);

  ModuleOp module;
  SmallVector<MatcherOp> inputMatchers;
  std::string combinedName;
  bool deferLoops;
  std::unique_ptr<Block> poolBody;
  Value poolRoot;
  DenseMap<PoolKey, Operation *> poolDedup;
  DenseMap<PoolKey, Operation *> questionDedup;
  DenseMap<Operation *, Operation *> questionOf;
  DenseMap<Operation *, unsigned> numAnswers;
  DenseMap<Operation *, unsigned> primary;
  DenseMap<Operation *, unsigned> secondary;
  DenseMap<Operation *, unsigned> insertionIndex;
  unsigned nextInsertionIndex = 0;
  std::vector<Operation *> sortedPoolOps;
  DenseSet<std::pair<Operation *, Operation *>> guardEdges;
  std::vector<MatcherInfo> matcherInfos;
  std::unique_ptr<TreeNode> treeRoot;
};
} // namespace

Operation *
Combiner::getOrCreatePoolOp(Operation *modelOp,
                            ArrayRef<Value> canonicalOperands,
                            const DenseSet<Operation *> &alreadyUsed) {
  PoolKey key{modelOp, SmallVector<Value, 4>(canonicalOperands)};
  if (auto it = poolDedup.find(key); it != poolDedup.end()) {
    if (!isa<ForEachOp>(modelOp) || !alreadyUsed.contains(it->second))
      return it->second;
  }

  IRMapping mapping;
  for (auto [orig, canonical] :
       llvm::zip(modelOp->getOperands(), canonicalOperands))
    mapping.map(orig, canonical);
  Operation *poolOp = modelOp->cloneWithoutRegions(mapping);
  poolBody->push_back(poolOp);

  if (auto forEach = dyn_cast<ForEachOp>(poolOp)) {
    Block &block = forEach.getBody().emplaceBlock();
    block.addArgument(forEach.getElementType(), forEach.getLoc());
  }

  insertionIndex[poolOp] = nextInsertionIndex++;
  key.op = poolOp;
  poolDedup[key] = poolOp;

  Operation *question = poolOp;
  if (poolOp->hasTrait<Question>()) {
    PoolKey questionKey{poolOp, key.operands, /*ignoreAttrs=*/true};
    question = questionDedup.try_emplace(std::move(questionKey), poolOp)
                   .first->second;
  }
  questionOf[poolOp] = question;
  ++numAnswers[question];
  return poolOp;
}

LogicalResult Combiner::collectPredicates(Block &block, MatcherInfo &info) {
  for (Operation &op : block) {
    if (auto succ = dyn_cast<SuccessOp>(&op)) {
      if (info.success)
        return op.emitOpError("combine-matchers expects exactly one "
                              "`match.success` per input matcher");
      info.success = succ;
      continue;
    }

    if (isa<TryOp, SwitchOpNameOp, SwitchTypeOp>(&op))
      return op.emitOpError(
          "combine-matchers does not support nested `try`/`switch_*` in "
          "input matchers");

    if (isa<ForEachOp>(&op) && op.getNextNode())
      return op.emitOpError(
          "combine-matchers requires `match.foreach` to be the last op in its "
          "block; ops following the loop would be absorbed into its body");

    SmallVector<Value, 4> canonicalOperands;
    canonicalOperands.reserve(op.getNumOperands());
    for (Value operand : op.getOperands())
      canonicalOperands.push_back(info.toCanonical.lookup(operand));

    Operation *poolOp = getOrCreatePoolOp(&op, canonicalOperands, info.preds);

    for (auto [origRes, poolRes] :
         llvm::zip(op.getResults(), poolOp->getResults()))
      info.toCanonical.map(origRes, poolRes);

    info.preds.insert(poolOp);
    if (info.questions.insert(questionOf[poolOp]).second)
      ++primary[questionOf[poolOp]];

    if (isa<ApplyNativeConstraintOp>(poolOp)) {
      for (Operation *guard : info.guards)
        guardEdges.insert({guard, poolOp});
    } else {
      info.guards.push_back(poolOp);
    }

    if (auto forEach = dyn_cast<ForEachOp>(&op)) {
      info.toCanonical.map(forEach.getLoopVariable(),
                           cast<ForEachOp>(poolOp).getLoopVariable());
      if (failed(collectPredicates(forEach.getBody().front(), info)))
        return failure();
    }
  }
  return success();
}

LogicalResult Combiner::buildCanonicalPool() {
  poolBody = std::make_unique<Block>();
  poolRoot = poolBody->addArgument(pdl::OperationType::get(module.getContext()),
                                   module.getLoc());

  matcherInfos.reserve(inputMatchers.size());
  for (MatcherOp matcher : inputMatchers) {
    MatcherInfo info;
    info.matcher = matcher;

    Block &body = matcher.getBodyRegion().front();
    info.toCanonical.map(body.getArgument(0), poolRoot);

    if (failed(collectPredicates(body, info)))
      return failure();

    if (!info.success)
      return matcher.emitOpError(
          "combine-matchers expects a `match.success` in every input "
          "matcher");

    matcherInfos.push_back(std::move(info));
  }

  for (MatcherInfo &info : matcherInfos) {
    unsigned total = 0;
    for (Operation *q : info.questions)
      total += primary[q] * primary[q];
    for (Operation *q : info.questions)
      secondary[q] += total;
  }

  return success();
}

static unsigned
computeLayer(Operation *op, DenseMap<Operation *, unsigned> &layers,
             const DenseMap<Operation *, SmallVector<Operation *, 2>> &guards) {
  if (auto it = layers.find(op); it != layers.end())
    return it->second;
  unsigned layer = 0;
  auto visit = [&](Operation *pred) {
    if (pred)
      layer = std::max(layer, computeLayer(pred, layers, guards) + 1);
  };
  for (Value operand : op->getOperands()) {
    if (auto arg = dyn_cast<BlockArgument>(operand))
      visit(arg.getOwner()->getParentOp());
    else
      visit(operand.getDefiningOp());
  }
  if (auto it = guards.find(op); it != guards.end())
    for (Operation *guard : it->second)
      visit(guard);
  layers[op] = layer;
  return layer;
}

/// Reorder the (dependency-respecting) `ops` so that the ops depending on no
/// loop come first, followed by each loop together with the ops whose latest
/// loop dependency is that loop. A loop is thus only entered after everything
/// that can be decided without it, and a later independent loop ends up nested
/// under the checks of an earlier one instead of hoisted above them.
static void deferLoopsInOrder(
    std::vector<Operation *> &ops,
    const DenseMap<Operation *, unsigned> &layers,
    const DenseMap<Operation *, SmallVector<Operation *, 2>> &guards) {
  // `ops` is topologically sorted, so a single forward pass sees every
  // dependency before its users, and loops are numbered in dependency order.
  DenseMap<Operation *, int> loopKey;
  int numLoops = 0;
  for (Operation *op : ops) {
    int key = -1;
    auto visit = [&](Operation *dep) {
      if (auto it = loopKey.find(dep); it != loopKey.end())
        key = std::max(key, it->second);
    };
    for (Value operand : op->getOperands()) {
      if (auto arg = dyn_cast<BlockArgument>(operand))
        visit(arg.getOwner()->getParentOp());
      else
        visit(operand.getDefiningOp());
    }
    if (auto it = guards.find(op); it != guards.end())
      for (Operation *guard : it->second)
        visit(guard);
    if (isa<ForEachOp>(op))
      key = numLoops++;
    loopKey[op] = key;
  }
  llvm::stable_sort(ops, [&](Operation *a, Operation *b) {
    return std::make_pair(loopKey.lookup(a), layers.lookup(a)) <
           std::make_pair(loopKey.lookup(b), layers.lookup(b));
  });
}

void Combiner::sortCanonicalPool() {
  for (Operation &op : *poolBody)
    sortedPoolOps.push_back(&op);
  llvm::sort(sortedPoolOps, [&](Operation *a, Operation *b) {
    Operation *qa = questionOf[a], *qb = questionOf[b];
    return std::make_tuple(primary[qa], secondary[qa], numAnswers[qa],
                           insertionIndex[qb], insertionIndex[b]) >
           std::make_tuple(primary[qb], secondary[qb], numAnswers[qb],
                           insertionIndex[qa], insertionIndex[a]);
  });

  DenseMap<Operation *, SmallVector<Operation *, 2>> guards;
  for (auto [guard, constraint] : guardEdges)
    guards[constraint].push_back(guard);
  DenseMap<Operation *, unsigned> layers;
  for (Operation *op : sortedPoolOps)
    computeLayer(op, layers, guards);
  llvm::stable_sort(sortedPoolOps, [&](Operation *a, Operation *b) {
    return layers.lookup(a) < layers.lookup(b);
  });
  if (deferLoops)
    deferLoopsInOrder(sortedPoolOps, layers, guards);
  DenseMap<Operation *, unsigned> position;
  for (auto [i, op] : llvm::enumerate(sortedPoolOps)) {
    op->moveBefore(poolBody.get(), poolBody->end());
    position[op] = i;
  }
  for (MatcherInfo &info : matcherInfos) {
    info.orderedPreds.assign(info.preds.begin(), info.preds.end());
    llvm::sort(info.orderedPreds, [&](Operation *a, Operation *b) {
      return position.lookup(a) < position.lookup(b);
    });
  }
}

void Combiner::propagate(std::unique_ptr<TreeNode> &node, MatcherInfo &info,
                         unsigned predIdx) {
  if (predIdx == info.orderedPreds.size()) {
    auto leaf = std::make_unique<TreeNode>();
    leaf->kind = TreeNode::Kind::Success;
    leaf->originalSuccess = info.success;
    leaf->successInputs.reserve(info.success.getInputs().size());
    for (Value input : info.success.getInputs())
      leaf->successInputs.push_back(info.toCanonical.lookup(input));
    leaf->failurePath = std::move(node);
    node = std::move(leaf);
    return;
  }

  Operation *current = info.orderedPreds[predIdx];
  if (!node) {
    auto fresh = std::make_unique<TreeNode>();
    fresh->kind = TreeNode::Kind::Test;
    fresh->pred = current;
    node = std::move(fresh);
    propagate(node->successPath, info, predIdx + 1);
    return;
  }

  if (node->kind == TreeNode::Kind::Test && node->pred == current) {
    propagate(node->successPath, info, predIdx + 1);
    return;
  }

  propagate(node->failurePath, info, predIdx);
}

void Combiner::emitNode(OpBuilder &builder, Location loc, TreeNode *node,
                        IRMapping &mapping) {
  bool hadTestSibling = false;
  while (node) {
    if (node->kind == TreeNode::Kind::Success) {
      SmallVector<Value, 4> inputs;
      inputs.reserve(node->successInputs.size());
      for (Value canonical : node->successInputs)
        inputs.push_back(mapping.lookup(canonical));
      SuccessOp orig = node->originalSuccess;
      SuccessOp::create(builder, loc, orig.getRewriterAttr(),
                        orig.getBenefitAttr(), inputs);
      node = node->failurePath.get();
      continue;
    }

    if (auto poolLoop = dyn_cast<ForEachOp>(node->pred)) {
      auto loop =
          ForEachOp::create(builder, loc, mapping.lookup(poolLoop.getRange()));
      {
        OpBuilder::InsertionGuard guard(builder);
        builder.setInsertionPointToStart(&loop.getBody().front());
        IRMapping bodyMapping = mapping;
        bodyMapping.map(poolLoop.getLoopVariable(), loop.getLoopVariable());
        emitNode(builder, loc, node->successPath.get(), bodyMapping);
      }
      node = node->failurePath.get();
      continue;
    }

    if (node->failurePath || hadTestSibling) {
      TryOp tryOp = TryOp::create(builder, loc);
      Block &tryBlock = tryOp.getBody().emplaceBlock();
      {
        OpBuilder::InsertionGuard guard(builder);
        builder.setInsertionPointToStart(&tryBlock);
        IRMapping tryMapping = mapping;
        builder.clone(*node->pred, tryMapping);
        emitNode(builder, loc, node->successPath.get(), tryMapping);
      }
      hadTestSibling = true;
      node = node->failurePath.get();
    } else {
      builder.clone(*node->pred, mapping);
      node = node->successPath.get();
    }
  }
}

template <typename SwitchOpT, typename TestOpT, typename GetTestedFn,
          typename GetCaseFn>
static bool foldSwitchAt(Block &block, Block::iterator &it,
                         GetTestedFn getTested, GetCaseFn getCase) {
  SmallVector<TryOp> cases;
  SmallVector<Attribute> caseAttrs;
  Value operand;
  for (auto cur = it; cur != block.end(); ++cur) {
    auto tryOp = dyn_cast<TryOp>(*cur);
    if (!tryOp)
      break;
    Block &body = tryOp.getBody().front();
    auto testOp = body.empty() ? TestOpT() : dyn_cast<TestOpT>(&body.front());
    if (!testOp)
      break;
    Value tested = getTested(testOp);
    if (tested.getParentBlock() == &body || (operand && operand != tested))
      break;
    operand = tested;
    cases.push_back(tryOp);
    caseAttrs.push_back(getCase(testOp));
  }
  if (cases.size() < 2)
    return false;

  OpBuilder builder(cases.front());
  auto switchOp =
      SwitchOpT::create(builder, cases.front().getLoc(), operand,
                        builder.getArrayAttr(caseAttrs), cases.size());
  for (auto [region, caseTry] : llvm::zip(switchOp.getCaseRegions(), cases)) {
    Block &newBlock = region.emplaceBlock();
    Block &oldBlock = caseTry.getBody().front();
    oldBlock.front().erase();
    newBlock.getOperations().splice(newBlock.end(), oldBlock.getOperations());
    caseTry.erase();
  }
  it = std::next(Block::iterator(switchOp));
  return true;
}

static void foldSwitches(Region &region) {
  for (Block &block : region) {
    for (auto it = block.begin(); it != block.end();) {
      if (foldSwitchAt<SwitchOpNameOp, HasNameOp>(
              block, it, [](HasNameOp op) { return op.getOp(); },
              [](HasNameOp op) -> Attribute { return op.getNameAttr(); }))
        continue;
      if (foldSwitchAt<SwitchTypeOp, HasTypeOp>(
              block, it, [](HasTypeOp op) { return op.getTypeValue(); },
              [](HasTypeOp op) -> Attribute {
                return op.getConstantTypeAttr();
              }))
        continue;
      ++it;
    }
  }
  for (Block &block : region)
    for (Operation &op : block)
      for (Region &nested : op.getRegions())
        foldSwitches(nested);
}

static bool isPureNavigationOp(Operation *op) {
  return isa<ConstantAttributeOp, ConstantTypeOp, ConstantTypesOp, GetOperandOp,
             GetOperandsOp, GetResultOp, GetResultsOp, GetAttributeOp,
             GetDefiningOpOp, GetValueTypeOp, GetAttributeTypeOp, GetUsersOp,
             ExtractOp>(op);
}

static Operation *ancestorInBlock(Operation *u, Block *block) {
  Operation *cur = u;
  while (cur->getBlock() != block) {
    cur = cur->getBlock()->getParentOp();
    assert(cur && "expected block to be an ancestor of the use");
  }
  return cur;
}

static Region *childRegionContaining(Operation *anchor, Operation *u) {
  Operation *cur = u;
  while (cur->getParentOp() != anchor)
    cur = cur->getParentOp();
  return cur->getParentRegion();
}

static std::pair<Block *, Operation *> computeSinkTarget(Operation *n) {
  Value v = n->getResult(0);
  if (v.use_empty())
    return {nullptr, nullptr};

  SmallVector<Operation *, 4> users(v.getUsers());
  Block *block = n->getBlock();
  while (true) {
    Operation *earliest = nullptr;
    Operation *commonAnchor = nullptr;
    bool allSameAnchor = true;
    for (Operation *u : users) {
      Operation *anchor = ancestorInBlock(u, block);
      if (!earliest || anchor->isBeforeInBlock(earliest))
        earliest = anchor;
      if (!commonAnchor)
        commonAnchor = anchor;
      else if (commonAnchor != anchor)
        allSameAnchor = false;
    }

    if (allSameAnchor && commonAnchor->getNumRegions() > 0 &&
        !llvm::is_contained(users, commonAnchor)) {
      Region *target = nullptr;
      bool single = true;
      for (Operation *u : users) {
        Region *r = childRegionContaining(commonAnchor, u);
        if (!target)
          target = r;
        else if (target != r) {
          single = false;
          break;
        }
      }
      if (single && target && target->hasOneBlock()) {
        block = &target->front();
        continue;
      }
    }

    return {block, earliest};
  }
}

static void sinkNavigationOps(Region &region) {
  SmallVector<Operation *> navOps;
  region.walk([&](Operation *op) {
    if (isPureNavigationOp(op))
      navOps.push_back(op);
  });

  bool erased = true;
  while (erased) {
    erased = false;
    for (Operation *&op : navOps) {
      if (op && op->use_empty()) {
        op->erase();
        op = nullptr;
        erased = true;
      }
    }
  }
  llvm::erase(navOps, nullptr);

  bool changed = true;
  while (changed) {
    changed = false;
    for (Operation *op : navOps) {
      auto [block, before] = computeSinkTarget(op);
      if (!before)
        continue;
      if (op->getBlock() == block) {
        bool needMove = false;
        for (Operation *cur = op->getNextNode(); cur != before;
             cur = cur->getNextNode()) {
          assert(cur && "first use must come after the navigation op");
          if (!isPureNavigationOp(cur)) {
            needMove = true;
            break;
          }
        }
        if (!needMove)
          continue;
      }
      op->moveBefore(before);
      changed = true;
    }
  }
}

void Combiner::emitCombinedMatcher() {
  if (matcherInfos.empty())
    return;

  OpBuilder builder = OpBuilder::atBlockBegin(module.getBody());
  Location loc = module.getLoc();
  StringAttr symName = matcherInfos.size() == 1
                           ? matcherInfos.front().matcher.getSymNameAttr()
                           : builder.getStringAttr(combinedName);
  auto combined = MatcherOp::create(builder, loc, symName);
  Block *body = &combined.getBodyRegion().emplaceBlock();
  IRMapping mapping;
  mapping.map(poolRoot,
              body->addArgument(builder.getType<pdl::OperationType>(), loc));

  builder.setInsertionPointToStart(body);
  emitNode(builder, loc, treeRoot.get(), mapping);
  foldSwitches(combined.getBodyRegion());
  sinkNavigationOps(combined.getBodyRegion());

  for (MatcherInfo &info : matcherInfos)
    info.matcher.erase();
}

LogicalResult Combiner::run() {
  if (failed(buildCanonicalPool()))
    return failure();
  sortCanonicalPool();
  for (MatcherInfo &info : matcherInfos)
    propagate(treeRoot, info, /*predIdx=*/0);
  emitCombinedMatcher();
  return success();
}

static StringRef getRootName(MatcherOp matcher) {
  Block &body = matcher.getBodyRegion().front();
  for (auto hasName : body.getOps<HasNameOp>())
    if (hasName.getOp() == body.getArgument(0))
      return hasName.getName();
  return StringRef();
}

LogicalResult mlir::match::combineMatchers(ModuleOp module, bool groupByRoot,
                                          bool deferLoops) {
  SmallVector<MatcherOp> matchers(module.getOps<MatcherOp>());
  if (!groupByRoot)
    return Combiner(module, matchers, "combined", deferLoops).run();

  llvm::MapVector<StringRef, SmallVector<MatcherOp>> groups;
  for (MatcherOp matcher : matchers)
    groups[getRootName(matcher)].push_back(matcher);
  for (auto &[rootName, group] : llvm::reverse(groups)) {
    std::string name =
        rootName.empty() ? "combined" : ("combined_" + rootName).str();
    if (failed(Combiner(module, group, name, deferLoops).run()))
      return failure();
  }
  return success();
}

namespace {
struct CombineMatchersPass
    : public match::impl::MatchCombineMatchersPassBase<CombineMatchersPass> {
  using MatchCombineMatchersPassBase::MatchCombineMatchersPassBase;

  void runOnOperation() final {
    if (failed(combineMatchers(getOperation(), groupByRoot, deferLoops)))
      signalPassFailure();
  }
};
} // namespace
