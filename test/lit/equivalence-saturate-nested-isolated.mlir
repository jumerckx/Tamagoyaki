// RUN: tamagoyaki-opt --ematch-saturate=max-iters=0 %s | FileCheck %s

// Nested e-graphs across an IsolatedFromAbove boundary: the inner graph sits
// inside an `smt.solver` region, which cannot reference values defined outside
// it. Its hash-cons scope must therefore be a *root* scope, not a child of the
// enclosing graph's scope. The inner `arith.constant 2.0` is congruent to the
// outer one, but it must NOT be deduplicated against it — doing so would make
// the inner op reference a value across the isolation boundary, producing
// invalid IR.

// CHECK-LABEL: func.func @isolated
// CHECK:         %[[CST:.*]] = arith.constant 2.000000e+00 : f32
// CHECK:         arith.mulf %arg0, %[[CST]] : f32
// CHECK:         smt.solver
// CHECK:           equivalence.graph
// The inner constant survives independently of the outer one.
// CHECK:             arith.constant 2.000000e+00 : f32
module @ir {
  func.func @isolated(%arg2: f32) -> f32 {
    %0 = equivalence.graph -> (f32) {
      %cst = arith.constant 2.000000e+00 : f32
      %1 = arith.mulf %arg2, %cst : f32
      %s = smt.solver(%arg2) {equivalence.allow_unspeculatable} : (f32) -> (f32) {
      ^bb0(%a: f32):
        %2 = equivalence.graph -> (f32) {
          %cst_0 = arith.constant 2.000000e+00 : f32
          %3 = arith.mulf %a, %cst_0 : f32
          equivalence.yield %3 : f32
        }
        smt.yield %2 : f32
      }
      equivalence.yield %1 : f32
    }
    return %0 : f32
  }
}

module @patterns {}
