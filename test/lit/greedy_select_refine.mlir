// RUN: tamagoyaki-opt "--equivalence-select-greedy=default-cost=1" %s | FileCheck %s
// RUN: tamagoyaki-opt "--equivalence-select-greedy=default-cost=1" --equivalence-extract=remove-graphs %s | FileCheck %s -check-prefix=EXTRACT

// An e-class may be replaced by the e-classes it refines into. The refinement
// target's index follows the inputs: here index 1 selects %x.
// CHECK-LABEL: func.func @cheaper
// CHECK:         equivalence.class %{{.*}} refines %{{.*}} (min_cost_index = 1) : i32
// EXTRACT-LABEL: func.func @cheaper
// EXTRACT-NOT:     arith.addi
// EXTRACT:         %[[M:.*]] = arith.muli %arg0, %arg1 : i32
// EXTRACT-NEXT:    return %[[M]] : i32
func.func @cheaper(%arg0: i32, %arg1: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %x = equivalence.class %arg0 : i32
    %c1 = arith.constant 1 : i32
    %s = arith.subi %x, %c1 : i32
    %add = arith.addi %s, %c1 overflow<nsw> : i32
    %a = equivalence.class %add refines %x : i32
    // The user's cost accounts for the refinement: 1 + 0 + 0.
    %m = arith.muli %a, %arg1 : i32
    %r = equivalence.class %m, %big : i32
    %big = arith.addi %arg0, %arg1 {equivalence.cost = #equivalence.cost<5>} : i32
    equivalence.yield %r : i32
  }
  return %0 : i32
}

// A refinement that costs as much as the cheapest input is not selected.
// CHECK-LABEL: func.func @tie
// CHECK:         equivalence.class %{{.*}} refines %{{.*}} (min_cost_index = 0) : i32
// EXTRACT-LABEL: func.func @tie
// EXTRACT-NEXT:    %[[A:.*]] = arith.addi %arg0, %arg1 : i32
// EXTRACT-NEXT:    return %[[A]] : i32
func.func @tie(%arg0: i32, %arg1: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %add = arith.addi %arg0, %arg1 : i32
    %a = equivalence.class %add refines %y : i32
    %sub = arith.subi %arg0, %arg1 : i32
    %y = equivalence.class %sub : i32
    equivalence.yield %a : i32
  }
  return %0 : i32
}

// %a and %b refine into each other and both cost as much as %c. %a selects
// %c rather than %b, so the selected refinements form no cycle: %a and %b are
// both extracted as %c.
// CHECK-LABEL: func.func @no_cycle
// CHECK:         %[[A:.*]] = equivalence.class %{{.*}} refines %[[B:.*]], %[[C:.*]] (min_cost_index = 2) : i32
// CHECK:         %[[B]] = equivalence.class %{{.*}} refines %[[A]] (min_cost_index = 1) : i32
// CHECK:         %[[C]] = equivalence.class %{{.*}} (min_cost_index = 0) : i32
// EXTRACT-LABEL: func.func @no_cycle
// EXTRACT-NEXT:    %[[R:.*]] = arith.xori %arg0, %arg1 : i32
// EXTRACT-NEXT:    return %[[R]], %[[R]] : i32, i32
func.func @no_cycle(%arg0: i32, %arg1: i32) -> (i32, i32) {
  %0:2 = equivalence.graph -> (i32, i32) {
    %p = arith.addi %arg0, %arg1 {equivalence.cost = #equivalence.cost<10>} : i32
    %a = equivalence.class %p refines %b, %c : i32
    %q = arith.subi %arg0, %arg1 {equivalence.cost = #equivalence.cost<10>} : i32
    %b = equivalence.class %q refines %a : i32
    %r = arith.xori %arg0, %arg1 : i32
    %c = equivalence.class %r : i32
    equivalence.yield %a, %b : i32, i32
  }
  return %0#0, %0#1 : i32, i32
}
