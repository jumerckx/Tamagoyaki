// RUN: tamagoyaki-opt -ematch-saturate %s | FileCheck %s

// Running saturation without first inserting an equivalence.graph (i.e. the
// user forgot -equivalence-insert-graph) must not crash. Saturation operates on
// graph regions, so with no graph there is nothing to saturate: the IR passes
// through unchanged.

module @ir {
  // CHECK:      func.func @foo(%arg0: i32, %arg1: i32) -> i32 {
  // CHECK-NEXT:   %0 = arith.subi %arg0, %arg1 : i32
  // CHECK-NEXT:   %1 = arith.addi %arg0, %arg1 : i32
  // CHECK-NEXT:   %2 = arith.xori %0, %1 : i32
  // CHECK-NEXT:   return %2 : i32
  // CHECK-NEXT: }
  func.func @foo(%arg0: i32, %arg1: i32) -> i32 {
    %0 = arith.subi %arg0, %arg1 : i32
    %1 = arith.addi %arg0, %arg1 : i32
    %2 = arith.xori %0, %1 : i32
    return %2 : i32
  }
}

module @patterns {}
