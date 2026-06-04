// RUN: tamagoyaki-opt -equivalence-graph-contains=patterns-file=%p/patterns.mlir %s | FileCheck %s

// The `arith.muli %arg0, 2` node matches the pattern, but the yielded value is
// a different (addi) e-class, so the pattern is not contained even though there
// is a match.

// CHECK: Pattern containment results:
// CHECK-NEXT: @mul_to_shift: not contained (1 match)
module {
  func.func @main(%arg0: i32) -> i32 {
    %r = equivalence.graph -> (i32) {
      %two = arith.constant 2 : i32
      %mul = arith.muli %arg0, %two : i32
      %three = arith.constant 3 : i32
      %add = arith.addi %arg0, %three : i32
      equivalence.yield %add : i32
    }
    return %r : i32
  }
}
