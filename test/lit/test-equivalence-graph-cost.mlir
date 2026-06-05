// RUN: tamagoyaki-opt --test-equivalence-graph-cost %s | FileCheck %s

// This exercises a test-only pass (test/lib/TestEquivalenceUtils.cpp) which is
// only available when tamagoyaki-opt is built with TAMAGOYAKI_INCLUDE_TESTS.
// REQUIRES: tamagoyaki-tests

func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    // Leaf nodes have base cost 1 and no (in-graph) operands.
    // CHECK: arith.muli %arg0, %arg0 {test.cost = 1 : i64}
    %a = arith.muli %arg0, %arg0 : i32
    // CHECK: arith.constant {test.cost = 1 : i64} 5
    %c5 = arith.constant 5 : i32
    // The class cost is the min over its operands (both 1).
    // CHECK: equivalence.class {{.*}} {test.cost = 1 : i64}
    %k1 = equivalence.class %a, %c5 : i32
    // max-reduction: base cost 1 + max(child costs) = 1 + 1 = 2.
    // CHECK: arith.addi {{.*}} {test.cost = 2 : i64}
    %r = arith.addi %k1, %k1 : i32
    equivalence.yield %r : i32
  }
  return %0 : i32
}
