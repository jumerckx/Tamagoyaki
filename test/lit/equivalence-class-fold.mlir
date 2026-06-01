// RUN: tamagoyaki-opt --canonicalize %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the equivalence.class folder.
//
// A class whose result is consumed by another class is invalid IR, so it can
// never be written directly. Instead each test starts from valid IR and relies
// on a separate fold (`arith.addi %v, 0` -> `%v`) to rewrite a plain operand
// into a class result *during* canonicalization. That transient
// class-consumes-class state is exactly what the ClassOp folder is meant to
// resolve.
// ===----------------------------------------------------------------------===//

// CHECK-LABEL: func @merge_consumed_class
// CHECK-SAME:    (%[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32)
// CHECK-NEXT:    %[[CLS:.*]] = equivalence.class %[[A]], %[[B]], %[[C]] : i32
// CHECK-NEXT:    return %[[CLS]] : i32
func.func @merge_consumed_class(%a: i32, %b: i32, %c: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %inner = equivalence.class %a, %b : i32
  %x = arith.addi %inner, %zero : i32
  %O = equivalence.class %x, %c : i32
  return %O : i32
}

// CHECK-LABEL: func @merge_drops_min_cost_index
// CHECK-SAME:    (%[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32)
// CHECK-NEXT:    %[[CLS:.*]] = equivalence.class %[[A]], %[[B]], %[[C]] : i32
// CHECK-NOT:     min_cost_index
// CHECK-NEXT:    return %[[CLS]] : i32
func.func @merge_drops_min_cost_index(%a: i32, %b: i32, %c: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %inner = equivalence.class %a, %b (min_cost_index = 1) : i32
  %x = arith.addi %inner, %zero : i32
  %O = equivalence.class %x, %c : i32
  return %O : i32
}

// CHECK-LABEL: func @self_consuming_class
// CHECK-SAME:    (%[[A:.*]]: i32, %[[B:.*]]: i32)
// CHECK:         equivalence.graph
// CHECK-NEXT:      %[[CLS:.*]] = equivalence.class %[[A]], %[[B]] : i32
// CHECK-NEXT:      equivalence.yield %[[CLS]] : i32
func.func @self_consuming_class(%a: i32, %b: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %O = equivalence.graph -> (i32) {
    %x = arith.addi %cls, %zero : i32
    %cls = equivalence.class %x, %a, %b : i32
    equivalence.yield %cls : i32
  }
  return %O : i32
}
