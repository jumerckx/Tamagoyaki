// RUN: tamagoyaki-opt --convert-match-to-ematch %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the convert-match-to-ematch pass.
//
// The pass inserts the ematch operations required for e-matching into a
// match-dialect matcher and its pdl_interp rewriter:
//   * match.get_result (unwrapped by is_not_null) is followed by
//     ematch.get_class_result, and downstream uses take the class result;
//   * match.get_defining_op navigates from the whole e-class of its operand
//     via match.get_each(ematch.get_class_vals ...);
//   * pdl_interp.replace becomes ematch.union;
//   * pdl_interp.create_operation is followed by ematch.dedup, and its uses
//     take the deduped op.
// ===----------------------------------------------------------------------===//

module {
  // Rewriter side: rules 3 (replace -> union) and 4 (create_operation -> dedup).
  //
  // CHECK-LABEL: pdl_interp.func @r
  // CHECK-SAME:    (%[[ROOT:.*]]: !pdl.operation)
  // CHECK:         %[[T:.*]] = pdl_interp.create_type f32
  // CHECK:         %[[OP:.*]] = pdl_interp.create_operation "arith.constant"
  // Rule 4: dedup follows create_operation, and get_results consumes the dedup.
  // CHECK-NEXT:    %[[DEDUP:.*]] = ematch.dedup %[[OP]]
  // CHECK-NEXT:    %[[RES:.*]] = pdl_interp.get_results of %[[DEDUP]] : !pdl.range<value>
  // Rule 3: replace becomes a union of the root op with its replacement range.
  // CHECK-NEXT:    ematch.union %[[ROOT]] : !pdl.operation, %[[RES]] : !pdl.range<value>
  // CHECK-NOT:     pdl_interp.replace
  // CHECK:         pdl_interp.finalize
  module @rewriters {
    pdl_interp.func @r(%root : !pdl.operation) {
      %t = pdl_interp.create_type f32
      %op = pdl_interp.create_operation "arith.constant" -> (%t : !pdl.type)
      %res = pdl_interp.get_results of %op : !pdl.range<value>
      pdl_interp.replace %root with (%res : !pdl.range<value>)
      pdl_interp.finalize
    }
  }

  // Matcher side: rules 1 (get_result -> get_class_result) and 2 (get_defining_op).
  //
  // CHECK-LABEL: match.matcher @m
  // CHECK-SAME:    root (%[[MROOT:.*]]: !pdl.operation)
  // CHECK:         has_name %[[MROOT]], "arith.addf"
  // Rule 1: get_class_result follows the unwrap of get_result.
  // CHECK:         %[[GR:.*]] = get_result 0 of %[[MROOT]]
  // CHECK-NEXT:    %[[RV:.*]] = is_not_null %[[GR]]{{.*}} -> !pdl.value
  // CHECK-NEXT:    %[[CR:.*]] = ematch.get_class_result %[[RV]]
  // Rule 2: get_defining_op navigates the whole e-class of the operand value.
  // CHECK:         %[[GO:.*]] = get_operand 0 of %[[MROOT]]
  // CHECK-NEXT:    %[[OV:.*]] = is_not_null %[[GO]]{{.*}} -> !pdl.value
  // CHECK-NEXT:    %[[CV:.*]] = ematch.get_class_vals %[[OV]]
  // CHECK-NEXT:    %[[EACH:.*]] = get_each %[[CV]] : !pdl.range<value> -> !pdl.value
  // CHECK-NEXT:    %[[DEF:.*]] = get_defining_op of %[[EACH]] : !pdl.value
  // CHECK:         is_not_null %[[DEF]]
  // The equality now compares the class result (rule 1) against the raw operand.
  // CHECK:         equal %[[CR]], %[[OV]] : !pdl.value
  // CHECK:         success @rewriters::@r
  match.matcher @m root(%root : !pdl.operation) {
    match.has_name %root, "arith.addf"
    %r0 = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r0 : !match.optional<!pdl.value> -> !pdl.value
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %ov = match.is_not_null %o0 : !match.optional<!pdl.value> -> !pdl.value
    %d = match.get_defining_op of %ov : !pdl.value -> !match.optional<!pdl.operation>
    %dop = match.is_not_null %d : !match.optional<!pdl.operation> -> !pdl.operation
    match.equal %v, %ov : !pdl.value
    match.success @rewriters::@r benefit(1) (%root : !pdl.operation)
  }
}
