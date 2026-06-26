// RUN: tamagoyaki-opt --ematch-saturate=max-iters=0 %s | FileCheck %s

// Nested e-graphs: the inner graph's hash-cons scope is a child of the
// enclosing graph's scope (no IsolatedFromAbove boundary between them), so an
// operation inside the loop that is congruent to one outside is removed and its
// uses are rerouted to the outer (ancestor) operation.

// The inner `arith.constant 2.0` and `arith.mulf %arg2, %cst` are duplicates of
// the outer `%cst` / `%1`; both are removed from the loop body, and the inner
// `addf` is rewritten to consume the outer `%1` directly. The op that depends
// on the loop-carried `%arg5` is preserved.

// CHECK-LABEL: func.func @licm
// CHECK:         %[[CST:.*]] = arith.constant 2.000000e+00 : f32
// CHECK:         %[[OUTER:.*]] = arith.mulf %arg2, %[[CST]] : f32
// CHECK:         %{{.*}} = scf.for %{{.*}} iter_args(%[[ACC:.*]] = %arg3)
// CHECK:           equivalence.graph
// CHECK-NOT:        arith.constant
// CHECK-NOT:        arith.mulf
// CHECK:            arith.addf %[[ACC]], %[[OUTER]] : f32
module @ir {
  func.func @licm(%arg0: index, %arg1: index, %arg2: f32, %arg3: f32) -> f32 {
    %0 = equivalence.graph -> (f32) {
      %c1 = arith.constant 1 : index
      %cst = arith.constant 2.000000e+00 : f32
      %1 = arith.mulf %arg2, %cst : f32
      %2 = scf.for %arg4 = %arg0 to %arg1 step %c1 iter_args(%arg5 = %arg3) -> (f32) {
        %4 = equivalence.graph -> (f32) {
          %cst_0 = arith.constant 2.000000e+00 : f32
          %5 = arith.mulf %arg2, %cst_0 : f32
          %6 = arith.addf %arg5, %5 : f32
          equivalence.yield %6 : f32
        }
        scf.yield %4 : f32
      }
      %3 = arith.addf %1, %2 : f32
      equivalence.yield %3 : f32
    }
    return %0 : f32
  }
}

module @patterns {}
