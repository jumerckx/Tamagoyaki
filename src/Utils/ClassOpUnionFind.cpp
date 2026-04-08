//===- ClassOpUnionFind.cpp - Union-find data structure for ClassOp ---*- C++
//-*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "Utils/ClassOpUnionFind.h"
#include "EquivalenceDialect.h"
#include "TamagoyakiTiming.h"
#include "Utils/HashConsPatternRewriter.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeRange.h"
#include "mlir/IR/Value.h"
#include "mlir/IR/ValueRange.h"
#include "mlir/Support/LLVM.h"
#include "vendor/mlir/SimpleOperationInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Casting.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/LogicalResult.h"
#include <cassert>
#include <cstddef>
#include <type_traits>
#include <utility>

#define DEBUG_TYPE "ematch"

using namespace mlir;
using namespace mlir::ematch;

namespace {

bool classInputsAreUnique(equivalence::ClassOp classOp) {
  SmallPtrSet<Value, 8> seen;
  for (Value operand : classOp.getInputs()) {
    if (!seen.insert(operand).second)
      return false;
  }
  return true;
}

Value findFirstDuplicateInput(equivalence::ClassOp classOp) {
  SmallPtrSet<Value, 8> seen;
  for (Value operand : classOp.getInputs()) {
    if (!seen.insert(operand).second)
      return operand;
  }
  return {};
}

void logFirstDuplicateOnly(llvm::StringRef label, equivalence::ClassOp classOp,
                           Value duplicateOperand = {}) {
  static bool emitted = false;
  if (emitted)
    return;

  if (!duplicateOperand)
    duplicateOperand = findFirstDuplicateInput(classOp);
  if (!duplicateOperand)
    return;

  emitted = true;
  llvm::dbgs() << "FIRST duplicate ClassOp detected at " << label << "\n";
  llvm::dbgs() << "  class: ";
  classOp.dump();
  llvm::dbgs() << "  duplicate operand: ";
  duplicateOperand.dump();
  llvm::dbgs() << "  class input count: " << classOp.getInputs().size() << "\n";
}

void logDuplicateClassOpState(llvm::StringRef label,
                              equivalence::ClassOp classOp,
                              Value duplicateOperand = {}) {
  if (classInputsAreUnique(classOp))
    return;

  if (!duplicateOperand)
    duplicateOperand = findFirstDuplicateInput(classOp);

  llvm::dbgs() << label << ": ";
  classOp.dump();
  llvm::dbgs() << "    inputs[" << classOp.getInputs().size() << "]: ";

  SmallPtrSet<Value, 8> seen;
  bool first = true;
  for (Value operand : classOp.getInputs()) {
    if (!first)
      llvm::dbgs() << ", ";
    first = false;

    if (!seen.insert(operand).second)
      llvm::dbgs() << "<dup> ";
    llvm::dbgs() << operand;
  }

  llvm::dbgs() << "\n";
  if (duplicateOperand) {
    llvm::dbgs() << "    first duplicate operand: ";
    duplicateOperand.dump();
  }
  llvm::dbgs() << "    WARNING: duplicate inputs detected in this ClassOp\n";
}

void logDuplicateLookupContext(llvm::StringRef label, Value queryValue,
                               equivalence::ClassOp classOp,
                               Value duplicateOperand = {}) {
  if (!duplicateOperand)
    duplicateOperand = findFirstDuplicateInput(classOp);
  if (!duplicateOperand)
    return;

  logFirstDuplicateOnly(label, classOp, duplicateOperand);
  llvm::dbgs() << label << "\n";
  llvm::dbgs() << "  query value: ";
  queryValue.dump();
  logDuplicateClassOpState("  returned class is duplicate", classOp,
                           duplicateOperand);
}

unsigned countDistinctClassUsers(
    Value value, SmallVectorImpl<equivalence::ClassOp> *users = nullptr) {
  SmallPtrSet<Operation *, 8> seen;
  unsigned count = 0;
  for (OpOperand &use : value.getUses()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*use.getOwner())) {
      // Leader-pointer uses are expected during union/rebuild and do not mean
      // the value is a member candidate of multiple classes.
      bool isInputUse = llvm::is_contained(classOp.getInputs(), value);
      if (!isInputUse)
        continue;

      if (seen.insert(classOp.getOperation()).second) {
        ++count;
        if (users)
          users->push_back(classOp);
      }
    }
  }
  return count;
}

unsigned countDistinctCanonicalClassLeaders(Value value) {
  SmallPtrSet<Operation *, 8> seen;
  for (OpOperand &use : value.getUses()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*use.getOwner())) {
      bool isInputUse = llvm::is_contained(classOp.getInputs(), value);
      if (!isInputUse || !classOp->getBlock())
        continue;

      equivalence::ClassOp leader = getCanonicalLeader(classOp);
      if (!leader || !leader->getBlock())
        continue;
      seen.insert(leader.getOperation());
    }
  }
  return seen.size();
}

void logFirstClassUserFanoutTransition(llvm::StringRef label, Value value,
                                       unsigned beforeCount) {
  SmallVector<equivalence::ClassOp, 4> users;
  unsigned afterCount = countDistinctClassUsers(value, &users);
  if (!(beforeCount <= 1 && afterCount > 1))
    return;

  // During repair/rebuild, a value can briefly appear in multiple classes that
  // are already in the same union-find component. Only report persistent
  // fanout across different canonical leaders.
  unsigned canonicalLeaderCount = countDistinctCanonicalClassLeaders(value);
  if (canonicalLeaderCount <= 1)
    return;

  static bool emitted = false;
  if (emitted)
    return;
  emitted = true;

  llvm::dbgs() << "FIRST value fanout to multiple ClassOps at " << label
               << " (before=" << beforeCount << ", after=" << afterCount
               << ", canonical_leaders=" << canonicalLeaderCount << ")\n";
  llvm::dbgs() << "  value: ";
  value.dump();
  for (equivalence::ClassOp classUser : users) {
    llvm::dbgs() << "  class user: ";
    classUser.dump();
  }
}

} // namespace

SmallVector<Value> mlir::ematch::getClassVals(PatternRewriter &rewriter,
                                              Value val) {
  Operation *defOp = val.getDefiningOp();
  if (defOp == nullptr) {
    return {val};
  } else if (auto classOp = dyn_cast<equivalence::ClassOp>(defOp)) {
    LLVM_DEBUG({
      Value dupOperand = findFirstDuplicateInput(classOp);
      if (dupOperand) {
        logFirstDuplicateOnly("getClassVals: class operand has duplicates",
                              classOp, dupOperand);
        logDuplicateClassOpState("getClassVals: class operand has duplicates",
                                 classOp, dupOperand);
      }
    });
    return llvm::to_vector(classOp->getOperands());
  }
  return {val};
}

Value mlir::ematch::getClassRepresentative(PatternRewriter &rewriter,
                                           Value val) {
  if (auto *defOp = val.getDefiningOp()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*defOp)) {
      LLVM_DEBUG({
        Value dupOperand = findFirstDuplicateInput(classOp);
        if (dupOperand) {
          logFirstDuplicateOnly(
              "getClassRepresentative: source class has duplicates", classOp,
              dupOperand);
          logDuplicateClassOpState(
              "getClassRepresentative: source class has duplicates", classOp,
              dupOperand);
        }
      });
    }
  }
  return getClassVals(rewriter, val)[0];
}

equivalence::ClassOp
mlir::ematch::getCanonicalLeader(equivalence::ClassOp classOp) {
  assert(classOp->getBlock());
  Value leaderVal = classOp.getLeader();
  if (!leaderVal)
    return classOp; // I am the leader.

  auto parentOp = cast<equivalence::ClassOp>(leaderVal.getDefiningOp());
  assert(parentOp->getBlock());
  if (!parentOp.getLeader())
    return parentOp; // My parent is the leader.

  // Path compression: find root leader and update my pointer.
  equivalence::ClassOp root = getCanonicalLeader(parentOp);
  classOp.getLeaderMutable().assign(root.getResult());
  return root;
}

Value mlir::ematch::getClassResult(PatternRewriter &rewriter, Value val) {
  if (val == nullptr) {
    return val;
  }
  if (auto classOp = val.hasOneUse()
                         ? dyn_cast<equivalence::ClassOp>(*val.user_begin())
                         : nullptr) {
    LLVM_DEBUG({
      Value dupOperand = findFirstDuplicateInput(classOp);
      if (dupOperand) {
        logFirstDuplicateOnly("getClassResult: returned class has duplicates",
                              classOp, dupOperand);
        logDuplicateClassOpState(
            "getClassResult: returned class has duplicates", classOp,
            dupOperand);
      }
    });
    return classOp.getResult();
  }
  return val;
}

SmallVector<Value> mlir::ematch::getClassResults(PatternRewriter &rewriter,
                                                 ValueRange vals) {
  SmallVector<Value> results;
  results.reserve(vals.size());

  for (Value val : vals) {
    results.push_back(getClassResult(rewriter, val));
  }

  return results;
}

equivalence::ClassOp getClassOpIfExists(Value val) {
  if (auto *defOp = val.getDefiningOp()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*defOp)) {
      LLVM_DEBUG({
        Value dupOperand = findFirstDuplicateInput(classOp);
        if (dupOperand) {
          logDuplicateLookupContext("getClassOpIfExists(defOp): duplicate", val,
                                    classOp, dupOperand);
        }
      });
      return classOp;
    }
  }

  unsigned classUserCount = 0;
  equivalence::ClassOp firstClassUser = nullptr;
  for (Operation *user : val.getUsers()) {
    if (auto classOp = dyn_cast<equivalence::ClassOp>(*user)) {
      if (!firstClassUser)
        firstClassUser = classOp;
      ++classUserCount;
    }
  }

  if (firstClassUser) {
    LLVM_DEBUG({
      if (classUserCount > 1) {
        llvm::dbgs() << "getClassOpIfExists(user): value has " << classUserCount
                     << " ClassOp users\n";
        llvm::dbgs() << "  query value: ";
        val.dump();
      }

      Value dupOperand = findFirstDuplicateInput(firstClassUser);
      if (dupOperand) {
        logDuplicateLookupContext("getClassOpIfExists(user): duplicate", val,
                                  firstClassUser, dupOperand);
      }
    });
    return firstClassUser;
  }
  return nullptr;
}

equivalence::ClassOp mlir::ematch::getClassOp(PatternRewriter &rewriter,
                                              Value val) {

  if (auto classOp = getClassOpIfExists(val)) {
    return classOp;
  }
  // If the value is not part of an eclass yet, create one
  OpBuilder builder(val.getContext());
  assert(!val.getDefiningOp() ||
         !dyn_cast<equivalence::ClassOp>(val.getDefiningOp()));
  builder.setInsertionPointAfterValue(val);
  auto classOp = equivalence::ClassOp::create(
      builder, val.getLoc(), TypeRange{val.getType()}, ValueRange{val},
      /*leader=*/Value{}, /*min_cost_index=*/nullptr);
  unsigned beforeClassUsers = countDistinctClassUsers(classOp.getResult());
  rewriter.replaceUsesWithIf(
      val, classOp.getResult(),
      [&classOp](OpOperand &operand) { return operand.getOwner() != classOp; });
  LLVM_DEBUG({
    logFirstClassUserFanoutTransition("getClassOp: replaceUsesWithIf",
                                      classOp.getResult(), beforeClassUsers);
  });
  return classOp;
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, Value a, Value b) {
  if (a == b) {
    return;
  }

  equivalence::ClassOp classA = getClassOp(rewriter, a);
  equivalence::ClassOp classB = getClassOp(rewriter, b);

  if (classA == classB)
    return;

  equivalence::ClassOp leader = getCanonicalLeader(classA);
  equivalence::ClassOp other = getCanonicalLeader(classB);

  LLVM_DEBUG({
    Value classADup = findFirstDuplicateInput(classA);
    if (classADup) {
      logFirstDuplicateOnly("classUnion: classA already has duplicates", classA,
                            classADup);
      llvm::dbgs() << "classUnion duplicate context (classA)\n";
      llvm::dbgs() << "  union lhs arg: ";
      a.dump();
      llvm::dbgs() << "  union rhs arg: ";
      b.dump();
      logDuplicateClassOpState("classUnion: classA already has duplicates",
                               classA, classADup);
    }

    Value classBDup = findFirstDuplicateInput(classB);
    if (classBDup) {
      logFirstDuplicateOnly("classUnion: classB already has duplicates", classB,
                            classBDup);
      llvm::dbgs() << "classUnion duplicate context (classB)\n";
      llvm::dbgs() << "  union lhs arg: ";
      a.dump();
      llvm::dbgs() << "  union rhs arg: ";
      b.dump();
      logDuplicateClassOpState("classUnion: classB already has duplicates",
                               classB, classBDup);
    }

    Value leaderDup = findFirstDuplicateInput(leader);
    if (leaderDup) {
      logFirstDuplicateOnly("classUnion: leader already has duplicates", leader,
                            leaderDup);
      logDuplicateClassOpState("classUnion: leader already has duplicates",
                               leader, leaderDup);
    }

    Value otherDup = findFirstDuplicateInput(other);
    if (otherDup) {
      logFirstDuplicateOnly("classUnion: other already has duplicates", other,
                            otherDup);
      logDuplicateClassOpState("classUnion: other already has duplicates",
                               other, otherDup);
    }
  });

  if (leader == other)
    return;

  // Lazy union: just point `other` at `leader` via the leader operand.
  unsigned beforeLeaderUsers = countDistinctClassUsers(leader.getResult());
  other.getLeaderMutable().assign(leader.getResult());
  LLVM_DEBUG({
    logFirstClassUserFanoutTransition("classUnion: assign leader",
                                      leader.getResult(), beforeLeaderUsers);
  });

  // We push `other` such that at the start of `rebuild`,
  worklist.push_back(other);
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, Operation *op,
                                  ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    classUnion(rewriter, result, val);
}

void ClassOpUnionFind::classUnion(PatternRewriter &rewriter, ValueRange a,
                                  ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    classUnion(rewriter, va, vb);
}

void ClassOpUnionFind::queueClassUnion(Value a, Value b) {
  pendingClassUnions.emplace_back(a, b);
}

void ClassOpUnionFind::queueClassUnion(Operation *op, ValueRange vals) {
  assert(op->getNumResults() == vals.size() &&
         "Operation result count must match value range size");
  for (auto [result, val] : llvm::zip(op->getResults(), vals))
    queueClassUnion(result, val);
}

void ClassOpUnionFind::queueClassUnion(ValueRange a, ValueRange b) {
  assert(a.size() == b.size() && "Value ranges must have equal size");
  for (auto [va, vb] : llvm::zip(a, b))
    queueClassUnion(va, vb);
}

void ClassOpUnionFind::processPendingClassUnions(PatternRewriter &rewriter) {
  for (auto [a, b] : pendingClassUnions) {
    // LLVM_DEBUG({
    //   llvm::dbgs() << "Unioning:\n\t";
    //   a.dump();
    //   llvm::dbgs() << "\t";
    //   b.dump();
    // });
    classUnion(rewriter, a, b);
  }
  pendingClassUnions.clear();
}

bool ClassOpUnionFind::rebuild(HashConsPatternRewriter &rewriter) {
  TAMAGOYAKI_SCOPED_TIMER("rebuild");
  // LLVM_DEBUG({
  //   llvm::dbgs() << "Starting rebuild. Worklist contains " << worklist.size()
  //                << " classes\n";
  //   llvm::dbgs() << "Worklist: ";
  //   for (auto rep : worklist) {
  //     llvm::dbgs() << "\t";
  //     rep.dump();
  //   }
  // });

  if (worklist.empty())
    return false;

  while (!worklist.empty()) {
    llvm::SetVector<equivalence::ClassOp> todo;
    for (equivalence::ClassOp c : worklist) {
      if (!c->getBlock()) {
        continue; // c has already been removed
      }

      auto leader = getCanonicalLeader(c);
      if (c != leader) { // c needs to be canonicalized
        bool leaderWasUnique = classInputsAreUnique(leader);

        // add operands to leader (deduplicated)
        SmallPtrSet<Value, 8> existing(leader.getInputs().begin(),
                                       leader.getInputs().end());
        SmallVector<Value, 8> newOperands;
        SmallVector<std::pair<Value, unsigned>, 8> beforeCounts;
        for (Value operand : c.getInputs()) {
          assert(
              !operand.getDefiningOp() ||
              !llvm::dyn_cast<equivalence::ClassOp>(operand.getDefiningOp()));
          if (existing.insert(operand).second) {
            newOperands.push_back(operand);
            beforeCounts.emplace_back(operand,
                                      countDistinctClassUsers(operand));
          }
        }
        auto mutableInputs = leader.getInputsMutable();
        mutableInputs.append(newOperands);

        LLVM_DEBUG({
          Value dupOperand = findFirstDuplicateInput(leader);
          if (dupOperand) {
            if (leaderWasUnique) {
              logFirstDuplicateOnly("rebuild: became-duplicate-after-append",
                                    leader, dupOperand);
              logDuplicateClassOpState("rebuild: became-duplicate-after-append",
                                       leader, dupOperand);
            } else {
              logFirstDuplicateOnly("rebuild: already-duplicate-before-append",
                                    leader, dupOperand);
              logDuplicateClassOpState(
                  "rebuild: already-duplicate-before-append", leader,
                  dupOperand);
            }
          }
        });

        // update all users of c
        rewriter.replaceAllUsesWith(c.getResult(), leader.getResult());

        // remove c from IR and queue for erasure
        c.getInputsMutable().clear();
        c.getLeaderMutable().clear();
        c->remove();
        pendingErase.push_back(c);

        LLVM_DEBUG({
          for (auto [operand, before] : beforeCounts) {
            logFirstClassUserFanoutTransition(
                "rebuild: post-canonicalization cleanup", operand, before);
          }
        });
      }
      todo.insert(leader);
    }
    worklist.clear();

    for (equivalence::ClassOp c : todo) {
      if (c.getInputs().empty())
        continue;
      repair(rewriter, c);
    }
  }

  // Now that the worklist is fully drained, erase all dead eclasses that
  // were deferred during classUnion.
  // LLVM_DEBUG({
  //   llvm::dbgs() << "Pending erases:\n";
  //   for (equivalence::ClassOp dead : pendingErase) {
  //     llvm::dbgs() << "\t";
  //     dead.dump();
  //   }
  // });
  SmallPtrSet<Operation *, 8> erased;
  for (equivalence::ClassOp dead : pendingErase) {
    if (erased.insert(dead.getOperation()).second)
      rewriter.eraseOp(dead);
  }
  pendingErase.clear();

  return true;
}

void ClassOpUnionFind::repair(HashConsPatternRewriter &rewriter,
                              equivalence::ClassOp classOp) {
  if (classOp->getBlock() == nullptr) {
    return;
  }

  LLVM_DEBUG({
    Value dupOperand = findFirstDuplicateInput(classOp);
    if (dupOperand) {
      logFirstDuplicateOnly("repair: entry", classOp, dupOperand);
      logDuplicateClassOpState("repair: entry already violates uniqueness",
                               classOp, dupOperand);
    }
  });

  llvm::DenseMap<Operation *, Operation *, SimpleOperationInfo> uniqueParents;
  // Collect pairs of duplicate operations to merge AFTER the loop
  SmallVector<std::pair<Operation *, Operation *>> toMerge;

  SmallPtrSet<Operation *, 8> scheduledForMerge;
  for (Operation *op1 : classOp.getResult().getUsers()) {
    // Skip ClassOps that use this result as their leader pointer.
    if (auto op1class = llvm::dyn_cast<equivalence::ClassOp>(op1)) {
      assert(op1class.getLeader() == classOp.getResult());
      continue;
    }
    Operation *op2 = uniqueParents.lookup(op1);

    if (op2) {
      assert(op2->getBlock());
      if (scheduledForMerge.insert(op1).second)
        toMerge.emplace_back(op1, op2);
    } else {
      uniqueParents[op1] = op1;
    }
  }
  // Now perform all merges after we're done with the hash map
  for (auto [other, keep] : toMerge) {
    if (keep == other)
      continue;

    bool erased = rewriter.erase(keep).succeeded();
    assert(erased);
    bool inserted = rewriter.insert(keep).succeeded();
    assert(inserted);

    for (auto [resOther, resKeep] :
         llvm::zip_equal(other->getResults(), keep->getResults())) {
      // Collect eclass pairs before replacement
      equivalence::ClassOp classKeep = getClassOpIfExists(resKeep);
      equivalence::ClassOp classOther = getClassOpIfExists(resOther);

      if (classKeep && classOther) {
        // Case 1: both values have a class — replace other's results with
        // keep's results, then union the two classes.
        unsigned beforeResKeepUsers = countDistinctClassUsers(resKeep);
        rewriter.replaceAllUsesWith(resOther, resKeep);
        LLVM_DEBUG({
          logFirstClassUserFanoutTransition("repair/case1: replaceAllUsesWith",
                                            resKeep, beforeResKeepUsers);
        });
        // The replaceAllUsesWith above rewrote resOther -> resKeep inside
        // classOther's input list.  That means resKeep is now an input of
        // *both* classKeep and classOther, breaking the single-class-
        // membership invariant.  Remove the stale occurrence from
        // classOther so that resKeep only belongs to classKeep.
        if (classKeep != classOther) {
          auto otherInputs = classOther.getInputsMutable();
          SmallVector<Value> filtered;
          for (Value v : classOther.getInputs()) {
            if (v != resKeep)
              filtered.push_back(v);
          }
          if (filtered.size() != otherInputs.size())
            otherInputs.assign(filtered);

          classUnion(rewriter, classKeep.getResult(), classOther.getResult());
        } else {
          SmallPtrSet<Value, 8> seen;
          SmallVector<Value> uniqueOperands;
          for (Value operand : classKeep.getInputs()) {
            if (seen.insert(operand).second)
              uniqueOperands.push_back(operand);
          }
          classKeep.getInputsMutable().assign(uniqueOperands);
          LLVM_DEBUG({
            logDuplicateClassOpState("repair: duplicate remains after dedupe",
                                     classKeep);
          });
        }
      } else if (classKeep) {
        // Case 2: only keep has a class — redirect other's results to the
        // class representative rather than the raw result.
        unsigned beforeClassKeepUsers =
            countDistinctClassUsers(classKeep.getResult());
        rewriter.replaceAllUsesWith(resOther, classKeep.getResult());
        LLVM_DEBUG({
          logFirstClassUserFanoutTransition("repair/case2: replaceAllUsesWith",
                                            classKeep.getResult(),
                                            beforeClassKeepUsers);
        });
      } else if (classOther) {
        // Case 3: only other has a class — redirect keep's non-ClassOp users
        // through classOther first, then retarget classOther from resOther to
        // resKeep.
        unsigned beforeClassOtherUsers =
            countDistinctClassUsers(classOther.getResult());
        rewriter.replaceUsesWithIf(resKeep, classOther.getResult(),
                                   [&](OpOperand &operand) {
                                     return operand.getOwner() != classOther;
                                   });
        LLVM_DEBUG({
          logFirstClassUserFanoutTransition("repair/case3: replaceUsesWithIf",
                                            classOther.getResult(),
                                            beforeClassOtherUsers);
        });
        unsigned beforeResKeepUsers = countDistinctClassUsers(resKeep);
        rewriter.replaceAllUsesWith(resOther, resKeep);
        LLVM_DEBUG({
          logFirstClassUserFanoutTransition(
              "repair/case3: replaceAllUsesWith(resOther,resKeep)", resKeep,
              beforeResKeepUsers);
        });
      } else {
        // Case 4: neither has a class — simple replacement.
        unsigned beforeResKeepUsers = countDistinctClassUsers(resKeep);
        rewriter.replaceAllUsesWith(resOther, resKeep);
        LLVM_DEBUG({
          logFirstClassUserFanoutTransition("repair/case4: replaceAllUsesWith",
                                            resKeep, beforeResKeepUsers);
        });
      }
    }
    rewriter.eraseOp(other);
  }
}
