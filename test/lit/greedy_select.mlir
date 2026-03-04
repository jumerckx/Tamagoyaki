// RUN: tamagoyaki-opt "--equivalence-select-greedy=default-cost=1" %s | FileCheck %s
// RUN: tamagoyaki-opt "--equivalence-select-greedy=default-cost=1 attribute-name=other.cost" %s | FileCheck %s -check-prefixes=OTHER-COST

// CHECK:  func.func @main(%{{.*}}: i32) -> i32 {

// CHECK:      %{{.*}} = arith.constant 2 : i32
// CHECK-NEXT: %{{.*}} = arith.constant 1 : i32
// CHECK-NEXT: %{{.*}} = arith.shli %{{.*}}, %{{.*}} {equivalence.cost = #equivalence.cost<2>} : i32
// CHECK-NEXT: %{{.*}} = arith.muli %{{.*}}, %{{.*}} {other.cost = #equivalence.cost<3>} : i32
// CHECK-NEXT: %{{.*}} = equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 1) : i32
// CHECK-NEXT: equivalence.yield %{{.*}} : i32

// OTHER-COST:      func.func @main(%{{.*}}: i32) -> i32 {

// OTHER-COST:   %{{.*}} = arith.constant 2 : i32
// OTHER-COST-NEXT:   %{{.*}} = arith.constant 1 : i32
// OTHER-COST-NEXT:   %{{.*}} = arith.shli %{{.*}}, %{{.*}} {equivalence.cost = #equivalence.cost<2>} : i32
// OTHER-COST-NEXT:   %{{.*}} = arith.muli %{{.*}}, %{{.*}} {other.cost = #equivalence.cost<3>}  : i32
// OTHER-COST-NEXT:   %{{.*}} = equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 0) : i32
// OTHER-COST-NEXT:   equivalence.yield %{{.*}} : i32

func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %1 = arith.shli %arg0, %c1_i32 {equivalence.cost = #equivalence.cost<2>} : i32
    %2 = arith.muli %arg0, %c2_i32 {other.cost = #equivalence.cost<3>}: i32
    %3 = equivalence.class %1, %2 : i32
    equivalence.yield %3 : i32
  }
  return %0 : i32
}
