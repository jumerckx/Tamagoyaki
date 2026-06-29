// RUN: tamagoyaki-opt --loop-invariant-code-motion %s | FileCheck %s

// equivalence.graph implements the LoopLikeInterface by forwarding methods
// to it parent looplike op, if there is any.

// CHECK-LABEL: func.func @licm
// CHECK:         equivalence.graph
// CHECK:           %[[CST:.*]] = arith.constant 2.000000e+00 : f32
// CHECK:           %[[INV:.*]] = arith.mulf %arg2, %[[CST]] : f32
// CHECK:           %{{.*}} = scf.for %{{.*}} iter_args(%[[ACC:.*]] = %arg3)
// CHECK:             equivalence.graph
// CHECK-NOT:          arith.constant
// CHECK-NOT:          arith.mulf
// CHECK:              arith.addf %[[ACC]], %[[INV]] : f32
module @ir {
  func.func @licm(%arg0: index, %arg1: index, %arg2: f32, %arg3: f32) -> f32 {
    %0 = equivalence.graph -> (f32) {
      %c1 = arith.constant 1 : index
      %2 = scf.for %arg4 = %arg0 to %arg1 step %c1 iter_args(%arg5 = %arg3) -> (f32) {
        %4 = equivalence.graph -> (f32) {
          %cst = arith.constant 2.000000e+00 : f32
          %5 = arith.mulf %arg2, %cst : f32
          %6 = arith.addf %arg5, %5 : f32
          equivalence.yield %6 : f32
        }
        scf.yield %4 : f32
      }
      equivalence.yield %2 : f32
    }
    return %0 : f32
  }
}

module @patterns {}
