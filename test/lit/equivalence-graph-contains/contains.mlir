// RUN: tamagoyaki-opt -equivalence-graph-contains=patterns-file=%p/patterns.mlir %s | FileCheck %s

// The `arith.muli %arg0, 2` node lives in the same e-class as the yielded
// value, and its multiplied operand is block argument 0, so the pattern is
// contained.

// CHECK: Pattern containment results:
// CHECK-NEXT: @mul_to_shift: contained
module {
  func.func @main(%arg0: i32) -> i32 {
    %r = equivalence.graph -> (i32) {
      %two = arith.constant 2 : i32
      %mul = arith.muli %arg0, %two : i32
      %one = arith.constant 1 : i32
      %shl = arith.shli %arg0, %one : i32
      %cls = equivalence.class %shl, %mul : i32
      equivalence.yield %cls : i32
    }
    return %r : i32
  }
}
