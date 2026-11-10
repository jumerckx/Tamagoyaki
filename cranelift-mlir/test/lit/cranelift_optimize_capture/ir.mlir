// RUN: cranelift-mlir-opt %s --pass-pipeline="builtin.module(func.func(cranelift-optimize{patterns-file=%p/patterns.mlir}))" | FileCheck %s

// The select becomes the load, which stays outside the graph: its e-class
// lives in the graph, and the uses of the select use the load again. ^bb2
// returns the load itself.

// CHECK-LABEL: func.func @f(
// CHECK-SAME:      %[[C:.*]]: i1, %[[X:.*]]: i32, %[[P:.*]]: memref<i32>)
// CHECK-NEXT:    %[[L:.*]] = memref.load %[[P]][]
// CHECK-NEXT:    cf.cond_br %[[C]], ^bb1, ^bb2
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    %[[A:.*]] = arith.addi %[[L]], %[[X]]
// CHECK-NEXT:    return %[[A]]
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    return %[[L]]
// CHECK-NOT:   equivalence

func.func @f(%c: i1, %x: i32, %p: memref<i32>) -> i32 {
  %l = memref.load %p[] : memref<i32>
  %s = arith.select %c, %l, %l : i32
  cf.cond_br %c, ^bb1, ^bb2
^bb1:
  %a = arith.addi %s, %x : i32
  return %a : i32
^bb2:
  return %s : i32
}
