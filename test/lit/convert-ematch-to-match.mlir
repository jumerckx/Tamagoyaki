// RUN: tamagoyaki-opt --split-input-file --convert-ematch-to-match %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the convert-ematch-to-match pass.
//
// The matcher-side e-class navigation helpers (get_class_vals,
// get_class_representative, get_class_result, get_class_results) become
// match.apply_native_constraint ops with the same name and signature, so a
// match.matcher navigating equivalence classes can be lowered by
// MatchToPDLInterp. The rewriter-side ops (union, dedup) live in pdl_interp
// rewriters and are left untouched here.
// ===----------------------------------------------------------------------===//

// Case 1: patterns directly in the top-level module (no @patterns nesting).
module {
  // Rewriter side is untouched: union/dedup stay as ematch ops (they are lowered
  // by convert-ematch-to-pdl-interp, not this pass).
  //
  // CHECK-LABEL: pdl_interp.func @r
  // CHECK:         %[[OP:.*]] = pdl_interp.create_operation "arith.constant"
  // CHECK:         %[[DEDUP:.*]] = ematch.dedup %[[OP]]
  // CHECK:         %[[RES:.*]] = pdl_interp.get_results of %[[DEDUP]]
  // CHECK:         ematch.union %[[ROOT:.*]] : !pdl.operation, %[[RES]] : !pdl.range<value>
  // CHECK-NOT:     match.apply_native_constraint
  module @rewriters {
    pdl_interp.func @r(%root : !pdl.operation) {
      %t = pdl_interp.create_type f32
      %op = pdl_interp.create_operation "arith.constant" -> (%t : !pdl.type)
      %dedup = ematch.dedup %op
      %res = pdl_interp.get_results of %dedup : !pdl.range<value>
      ematch.union %root : !pdl.operation, %res : !pdl.range<value>
      pdl_interp.finalize
    }
  }

  // Matcher side: the get_class_* helpers become native constraints.
  //
  // CHECK-LABEL: match.matcher @m
  // CHECK-SAME:    root (%[[MROOT:.*]]: !pdl.operation)
  // CHECK:         %[[GR:.*]] = get_result 0 of %[[MROOT]]
  // CHECK:         %[[RV:.*]] = is_not_null %[[GR]]{{.*}} -> !pdl.value
  // Rule 1 helper: get_class_result -> apply_native_constraint.
  // CHECK-NEXT:    %[[CR:.*]] = apply_native_constraint "get_class_result"(%[[RV]] : !pdl.value) : !pdl.value
  // CHECK-NOT:     ematch.get_class_result
  // CHECK:         %[[GO:.*]] = get_operand 0 of %[[MROOT]]
  // CHECK:         %[[OV:.*]] = is_not_null %[[GO]]{{.*}} -> !pdl.value
  // Rule 2 helper: get_class_vals -> apply_native_constraint.
  // CHECK-NEXT:    %[[CV:.*]] = apply_native_constraint "get_class_vals"(%[[OV]] : !pdl.value) : !pdl.range<value>
  // CHECK-NOT:     ematch.get_class_vals
  // CHECK:         %[[EACH:.*]] = get_each %[[CV]] : !pdl.range<value> -> !pdl.value
  // CHECK:         equal %[[CR]], %[[OV]] : !pdl.value
  // CHECK:         success @rewriters::@r
  match.matcher @m root(%root : !pdl.operation) {
    match.has_name %root, "arith.addf"
    %r0 = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r0 : !match.optional<!pdl.value> -> !pdl.value
    %cr = ematch.get_class_result %v
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %ov = match.is_not_null %o0 : !match.optional<!pdl.value> -> !pdl.value
    %cv = ematch.get_class_vals %ov
    %each = match.get_each %cv : !pdl.range<value> -> !pdl.value
    %d = match.get_defining_op of %each : !pdl.value -> !match.optional<!pdl.operation>
    %dop = match.is_not_null %d : !match.optional<!pdl.operation> -> !pdl.operation
    match.equal %cr, %ov : !pdl.value
    match.success @rewriters::@r benefit(1) (%root : !pdl.operation)
  }
}

// -----

// Case 2: patterns wrapped in a nested @patterns submodule. Conversion still
// applies deep inside the nesting.
//
// CHECK-LABEL: match.matcher @nested
// CHECK:         apply_native_constraint "get_class_vals"({{.*}} : !pdl.value) : !pdl.range<value>
// CHECK-NOT:     ematch.get_class_vals
module {
  module @patterns {
    module @rewriters {
      pdl_interp.func @r(%root : !pdl.operation) {
        pdl_interp.finalize
      }
    }
    match.matcher @nested root(%root : !pdl.operation) {
      %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
      %ov = match.is_not_null %o0 : !match.optional<!pdl.value> -> !pdl.value
      %cv = ematch.get_class_vals %ov
      %each = match.get_each %cv : !pdl.range<value> -> !pdl.value
      match.success @rewriters::@r benefit(1) (%root : !pdl.operation)
    }
  }
}
