// RUN: tamagoyaki-opt -equivalence-insert-graph %s | FileCheck %s

// The pass wraps the function body in a graph and recurses into the
// single-block regions of speculatable operations (here, scf.for), wrapping
// each in its own nested graph.

// Captured block arguments (the loop bounds and the iter_arg) are wrapped in a
// ClassOp inside the graph that captures them, so every e-class lives inside a
// graph.

// CHECK-LABEL: func.func @nested_for
// CHECK:         %0 = equivalence.graph -> (f32) {
// CHECK:           %[[LB:.*]] = equivalence.class %arg0 : index
// CHECK:           %[[UB:.*]] = equivalence.class %arg1 : index
// CHECK:           %[[INIT:.*]] = equivalence.class %arg3 : f32
// CHECK:           %[[R:.*]] = scf.for %{{.*}} = %[[LB]] to %[[UB]] step %{{.*}} iter_args(%[[ACC:.*]] = %[[INIT]]) -> (f32) {
// CHECK:             %{{.*}} = equivalence.graph -> (f32) {
// CHECK:               %[[ACCCLS:.*]] = equivalence.class %[[ACC]] : f32
// CHECK:               %[[C:.*]] = arith.constant 2.000000e+00 : f32
// CHECK:               %[[SUM:.*]] = arith.addf %[[ACCCLS]], %[[C]] : f32
// CHECK:               equivalence.yield %[[SUM]] : f32
// CHECK:             }
// CHECK:           }
// CHECK:           equivalence.yield %[[R]] : f32
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
