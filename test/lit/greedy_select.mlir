// RUN: tamagoyaki-opt "--equivalence-select-greedy=default-cost=1" %s | FileCheck %s

// CHECK:  func.func @main(%{{.*}}: i32) -> i32 {

// CHECK:      %{{.*}} = arith.constant {equivalence.cost = #equivalence.cost<1>} 2 : i32
// CHECK-NEXT: %{{.*}} = arith.constant {equivalence.cost = #equivalence.cost<1>} 1 : i32
// CHECK-NEXT: %{{.*}} = arith.shli %{{.*}}, %{{.*}} {equivalence.cost = #equivalence.cost<2>} : i32
// CHECK-NEXT: %{{.*}} = arith.muli %{{.*}}, %{{.*}} {equivalence.cost = #equivalence.cost<1>} : i32
// CHECK-NEXT: %{{.*}} = equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 1) : i32
// CHECK-NEXT: equivalence.yield %{{.*}} : i32

func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
  ^bb0(%arg1: i32):
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %1 = arith.shli %arg1, %c1_i32 {equivalence.cost = #equivalence.cost<2>} : i32
    %2 = arith.muli %arg1, %c2_i32 : i32
    %3 = equivalence.class %1, %2 : i32
    equivalence.yield %3 : i32
  }
  return %0 : i32
}
