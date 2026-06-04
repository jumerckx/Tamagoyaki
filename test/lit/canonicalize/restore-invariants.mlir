// RUN: tamagoyaki-opt --equivalence-restore-invariants %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the equivalence-restore-invariants pass.
//
// The pass re-establishes the class normal form to a fixpoint:
//   * a class result is never an operand of another class (nested classes are
//     merged), and
//   * a class's operands are used only by that class (external uses are
//     rerouted through the class result).
//   * class operands are deduplicated
// ===----------------------------------------------------------------------===//

// A nested class operand is absorbed and external operand uses are rerouted
// through the class result. %extra uses both %a and %c, which are operands of
// the merged class, so both uses are redirected to the class result.
// CHECK-LABEL: func @nested_and_reroute
// CHECK-SAME:    (%[[A:.*]]: i32, %[[B:.*]]: i32, %[[C:.*]]: i32)
// CHECK-NEXT:    %[[CLS:.*]] = equivalence.class %[[A]], %[[B]], %[[C]] : i32
// CHECK-NEXT:    %[[EXTRA:.*]] = arith.addi %[[CLS]], %[[CLS]] : i32
// CHECK-NEXT:    return %[[CLS]], %[[EXTRA]] : i32, i32
func.func @nested_and_reroute(%a: i32, %b: i32, %c: i32) -> (i32, i32) {
  %zero = arith.constant 0 : i32
  %inner = equivalence.class %a, %b : i32
  %x = arith.addi %inner, %zero : i32
  %O = equivalence.class %x, %c : i32
  %extra = arith.addi %a, %c : i32
  return %O, %extra : i32, i32
}

// The merged class drops its stale min_cost_index (operand indices shift).
// CHECK-LABEL: func @merge_drops_min_cost_index
// CHECK-NEXT:    %[[CLS:.*]] = equivalence.class %{{.*}}, %{{.*}}, %{{.*}} : i32
// CHECK-NOT:     min_cost_index
// CHECK-NEXT:    return %[[CLS]] : i32
func.func @merge_drops_min_cost_index(%a: i32, %b: i32, %c: i32) -> i32 {
  %zero = arith.constant 0 : i32
  %inner = equivalence.class %a, %b (min_cost_index = 1) : i32
  %x = arith.addi %inner, %zero : i32
  %O = equivalence.class %x, %c : i32
  return %O : i32
}

// Duplicate operands are not a verifier error; the pass deduplicates them.
// CHECK-LABEL: func @duplicate_operands
// CHECK-SAME:    (%[[A:.*]]: i32, %[[B:.*]]: i32)
// CHECK-NEXT:    %[[CLS:.*]] = equivalence.class %[[A]], %[[B]] : i32
// CHECK-NEXT:    return %[[CLS]] : i32
func.func @duplicate_operands(%a: i32, %b: i32) -> i32 {
  %c = equivalence.class %a, %b, %a : i32
  return %c : i32
}
