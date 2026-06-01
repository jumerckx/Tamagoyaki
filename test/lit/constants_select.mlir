// RUN: tamagoyaki-opt --equivalence-select-constants %s | FileCheck %s

// CHECK:  func.func @main(%{{.*}}: i32) -> i32 {

func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    // A class with a constant operand: the constant is selected.
    // CHECK:      %[[A:.*]] = arith.muli
    // CHECK-NEXT: %[[C5:.*]] = arith.constant 5 : i32
    // CHECK-NEXT: %{{.*}} = equivalence.class %[[A]], %[[C5]] (min_cost_index = 1) : i32
    %a = arith.muli %arg0, %arg0 : i32
    %c5 = arith.constant 5 : i32
    %k1 = equivalence.class %a, %c5 : i32

    // A class that already carries a selection is left untouched.
    // CHECK:      %[[C1:.*]] = arith.constant 1 : i32
    // CHECK-NEXT: %[[B:.*]] = arith.muli
    // CHECK-NEXT: %{{.*}} = equivalence.class %[[C1]], %[[B]] (min_cost_index = 1) : i32
    %c1 = arith.constant 1 : i32
    %b = arith.muli %arg0, %arg0 : i32
    %k2 = equivalence.class %c1, %b (min_cost_index = 1) : i32

    // A class with no constant operand is left untouched.
    // CHECK:      %[[C:.*]] = arith.muli
    // CHECK-NEXT: %[[D:.*]] = arith.addi
    // CHECK-NEXT: %{{.*}} = equivalence.class %[[C]], %[[D]] : i32
    %c = arith.muli %arg0, %arg0 : i32
    %d = arith.addi %arg0, %arg0 : i32
    %k3 = equivalence.class %c, %d : i32

    // A class with multiple constants: the first one is selected.
    // CHECK:      %[[C2:.*]] = arith.constant 2 : i32
    // CHECK-NEXT: %[[C3:.*]] = arith.constant 3 : i32
    // CHECK-NEXT: %{{.*}} = equivalence.class %[[C2]], %[[C3]] (min_cost_index = 0) : i32
    %c2 = arith.constant 2 : i32
    %c3 = arith.constant 3 : i32
    %k4 = equivalence.class %c2, %c3 : i32

    %r1 = arith.addi %k1, %k2 : i32
    %r2 = arith.addi %k3, %k4 : i32
    %r3 = arith.addi %r1, %r2 : i32
    equivalence.yield %r3 : i32
  }
  return %0 : i32
}
