// RUN: tamagoyaki-opt -equivalence-restore-invariants %s | FileCheck %s
// RUN: tamagoyaki-opt -equivalence-restore-invariants %s | tamagoyaki-opt | FileCheck %s

// equivalence-restore-invariants on nested e-graphs: the ClassOp normal form is
// restored independently per scope, and cross-scope references are preserved
// without introducing dominance/isolation violations.
//
//   * The nested-class violation `class(class(%a))` inside the inner graph is
//     collapsed to a single class (both classes live in the inner scope).
//   * The inner `addf` legally consumes the *outer* class result, and that
//     cross-scope reference must survive untouched (the second RUN line confirms
//     the result still verifies).

// CHECK-LABEL: func.func @f
// CHECK:         %[[COUTER:.*]] = equivalence.class %{{.*}} : f32
// CHECK:         scf.for {{.*}} iter_args(%[[ACC:.*]] = %arg3)
// CHECK:           equivalence.graph
// CHECK:             %[[A:.*]] = arith.addf %[[ACC]], %[[COUTER]] : f32
// CHECK:             %[[CA:.*]] = equivalence.class %[[A]] : f32
// CHECK-NOT:         equivalence.class %[[CA]]
// CHECK:             equivalence.yield %[[CA]] : f32
func.func @f(%arg0: index, %arg1: index, %x: f32, %init: f32) -> f32 {
  %0 = equivalence.graph -> (f32) {
    %step = arith.constant 1 : index
    %cst = arith.constant 2.000000e+00 : f32
    %couter = equivalence.class %cst : f32
    %r = scf.for %i = %arg0 to %arg1 step %step iter_args(%acc = %init) -> f32 {
      %ig = equivalence.graph -> (f32) {
        // Uses the outer class result (cross-scope, legal: loop body sees outer).
        %a = arith.addf %acc, %couter : f32
        %ca = equivalence.class %a : f32
        // Normal-form violation: a class whose operand is another class result.
        %cb = equivalence.class %ca : f32
        equivalence.yield %cb : f32
      }
      scf.yield %ig : f32
    }
    %cr = equivalence.class %r : f32
    equivalence.yield %cr : f32
  }
  return %0 : f32
}
