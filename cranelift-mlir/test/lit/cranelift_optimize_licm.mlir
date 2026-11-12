// RUN: cranelift-mlir-opt %s --pass-pipeline="builtin.module(func.func(cranelift-optimize))" | FileCheck %s

// Elaboration hoists the muli and the constant out of the loop, whose body
// first uses them: their operands are defined outside of it. The addi of the
// induction variable stays in the body.

// CHECK-LABEL: func.func @f(
// CHECK-SAME:      %[[N:.*]]: index, %[[X:.*]]: i32, %[[P:.*]]: memref<?xi32>)
// CHECK-NEXT:    %[[C0:.*]] = arith.constant 0 : index
// CHECK-NEXT:    %[[SQ:.*]] = arith.muli %[[X]], %[[X]] : i32
// CHECK-NEXT:    %[[C1:.*]] = arith.constant 1 : index
// CHECK-NEXT:    cf.br ^bb1(%[[C0]] : index)
// CHECK-NEXT:  ^bb1(%[[I:.*]]: index):
// CHECK-NEXT:    %[[DONE:.*]] = arith.cmpi eq, %[[I]], %[[N]] : index
// CHECK-NEXT:    cf.cond_br %[[DONE]], ^bb3, ^bb2
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    memref.store %[[SQ]], %[[P]][%[[I]]] : memref<?xi32>
// CHECK-NEXT:    %[[NEXT:.*]] = arith.addi %[[I]], %[[C1]] : index
// CHECK-NEXT:    cf.br ^bb1(%[[NEXT]] : index)

func.func @f(%n: index, %x: i32, %p: memref<?xi32>) {
  %c0 = arith.constant 0 : index
  cf.br ^header(%c0 : index)
^header(%i: index):
  %done = arith.cmpi eq, %i, %n : index
  cf.cond_br %done, ^exit, ^body
^body:
  %sq = arith.muli %x, %x : i32
  memref.store %sq, %p[%i] : memref<?xi32>
  %c1 = arith.constant 1 : index
  %next = arith.addi %i, %c1 : index
  cf.br ^header(%next : index)
^exit:
  return
}
