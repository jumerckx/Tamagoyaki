// RUN: tamagoyaki-opt -equivalence-insert-graph %s | FileCheck %s

// CHECK:      func.func @main(%arg0: i32) -> (i32, i32) {
// CHECK-NEXT:   %0:2 = equivalence.graph -> (i32, i32) {
// CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
// CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
// CHECK-NEXT:     %2 = arith.addi %1, %c1_i32 : i32
// CHECK-NEXT:     equivalence.yield %c1_i32, %2 : i32, i32
// CHECK-NEXT:   }
// CHECK-NEXT:   return %0#0, %0#1 : i32, i32
// CHECK-NEXT: }


func.func @main(%arg0: i32) -> (i32, i32) {
  %a = arith.constant 1 : i32
  %b = arith.addi %arg0, %a : i32
  return %a, %b : i32, i32
}
