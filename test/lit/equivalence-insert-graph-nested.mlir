// RUN: tamagoyaki-opt -equivalence-insert-graph %s | FileCheck %s

// The pass wraps the function body in a graph and recurses into the
// single-block regions of speculatable operations (here, scf.for), wrapping
// each in its own nested graph.

// CHECK-LABEL: func.func @nested_for
// CHECK:         %0 = equivalence.graph -> (f32) {
// CHECK:           %1 = scf.for %{{.*}} = %arg0 to %arg1 step %{{.*}} iter_args(%[[ACC:.*]] = %arg3) -> (f32) {
// CHECK:             %2 = equivalence.graph -> (f32) {
// CHECK:               %[[C:.*]] = arith.constant 2.000000e+00 : f32
// CHECK:               %[[SUM:.*]] = arith.addf %[[ACC]], %[[C]] : f32
// CHECK:               equivalence.yield %[[SUM]] : f32
// CHECK:             }
// CHECK:             scf.yield %2 : f32
// CHECK:           }
// CHECK:           equivalence.yield %1 : f32
// CHECK:         }
// CHECK:         return %0 : f32

func.func @nested_for(%arg0: index, %arg1: index, %arg2: index, %init: f32) -> f32 {
  %step = arith.constant 1 : index
  %r = scf.for %i = %arg0 to %arg1 step %step iter_args(%acc = %init) -> (f32) {
    %c = arith.constant 2.0 : f32
    %sum = arith.addf %acc, %c : f32
    scf.yield %sum : f32
  }
  return %r : f32
}

// A doubly-nested loop produces three levels of graphs: function body, outer
// loop body, inner loop body.

// CHECK-LABEL: func.func @doubly_nested_for
// CHECK:         equivalence.graph
// CHECK:           scf.for
// CHECK:             equivalence.graph
// CHECK:               scf.for
// CHECK:                 equivalence.graph
// CHECK:                   arith.addf
// CHECK:                   equivalence.yield
// CHECK:                 scf.yield
// CHECK:               equivalence.yield
// CHECK:             scf.yield
// CHECK:           equivalence.yield

func.func @doubly_nested_for(%arg0: index, %arg1: index, %init: f32) -> f32 {
  %step = arith.constant 1 : index
  %r = scf.for %i0 = %arg0 to %arg1 step %step iter_args(%acc0 = %init) -> (f32) {
    %inner = scf.for %i1 = %arg0 to %arg1 step %step iter_args(%acc1 = %acc0) -> (f32) {
      %c = arith.constant 2.0 : f32
      %sum = arith.addf %acc1, %c : f32
      scf.yield %sum : f32
    }
    scf.yield %inner : f32
  }
  return %r : f32
}
