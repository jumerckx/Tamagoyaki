// RUN: tamagoyaki-opt --convert-ematch-to-match %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the convert-ematch-to-match pass: the ematch ops that ematchify puts in
// matchers and rewriters become the native calls that ematch-saturate
// implements. ematch.equivalent becomes the are_equivalent constraint. Ematch
// ops outside of matchers and rewriters are left alone.
// ===----------------------------------------------------------------------===//

module {
  module @rewriters {
    // CHECK-LABEL: match.rewriter @r(
    // CHECK-SAME:      %[[ROOT:.*]]: !pdl.operation, %[[V:.*]]: !pdl.value)
    // CHECK-NEXT:    %[[CV:.*]] = apply_native_rewrite "get_class_result"(%[[V]] : !pdl.value) : !pdl.value
    // CHECK-NEXT:    %[[T:.*]] = get_value_type of %[[CV]] : !pdl.type
    // CHECK-NEXT:    %[[NEG:.*]] = create_operation "arith.negf"(%[[CV]] : !pdl.value) -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[NEGD:.*]] = apply_native_rewrite "dedup"(%[[NEG]] : !pdl.operation) : !pdl.operation
    // CHECK-NEXT:    %[[RES:.*]] = pdl.results of %[[NEGD]]
    // CHECK-NEXT:    %[[CRES:.*]] = apply_native_rewrite "get_class_results"(%[[RES]] : !pdl.range<value>) : !pdl.range<value>
    // CHECK-NEXT:    apply_native_rewrite "union"(%[[ROOT]], %[[CRES]] : !pdl.operation, !pdl.range<value>)
    // CHECK-NEXT:  }
    match.rewriter @r(%root : !pdl.operation, %v : !pdl.value) {
      %cv = ematch.get_class_result %v
      %t = get_value_type of %cv : !pdl.type
      %neg = create_operation "arith.negf"(%cv : !pdl.value) -> (%t : !pdl.type)
      %negd = ematch.dedup %neg
      %res = pdl.results of %negd
      %cres = ematch.get_class_results %res
      ematch.union %root : !pdl.operation, %cres : !pdl.range<value>
    }
  }

  // CHECK-LABEL: match.matcher @m
  // CHECK-SAME:    root(%[[ROOT:.*]]: !pdl.operation)
  // CHECK:         %[[V:.*]] = is_not_null %{{.*}} : !pdl.value
  // CHECK:         %[[RS:.*]] = is_not_null %{{.*}} : !pdl.range<value>
  // CHECK-NEXT:    %[[CRS:.*]] = apply_native_rewrite "get_class_results"(%[[RS]] : !pdl.range<value>) : !pdl.range<value>
  // CHECK-NEXT:    %[[MEMBERS:.*]] = apply_native_rewrite "get_class_vals"(%[[V]] : !pdl.value) : !pdl.range<value>
  // CHECK-NEXT:    foreach %[[M:.*]] in %[[MEMBERS]] : !pdl.range<value> {
  // CHECK-NEXT:      %[[D:.*]] = get_defining_op of %[[M]]
  // CHECK-NEXT:      %[[DOP:.*]] = is_not_null %[[D]] : !pdl.operation
  // CHECK-NEXT:      %[[R:.*]] = get_result 0 of %[[DOP]]
  // CHECK-NEXT:      %[[RV:.*]] = is_not_null %[[R]] : !pdl.value
  // CHECK-NEXT:      %[[CR:.*]] = apply_native_rewrite "get_class_result"(%[[RV]] : !pdl.value) : !pdl.value
  // CHECK-NEXT:      apply_native_constraint "are_equivalent"(%[[CR]], %[[V]] : !pdl.value, !pdl.value)
  // CHECK-NEXT:      %[[REP:.*]] = apply_native_rewrite "get_class_representative"(%[[V]] : !pdl.value) : !pdl.value
  // CHECK-NEXT:      success @rewriters::@r benefit(1) (%[[ROOT]], %[[REP]] : !pdl.operation, !pdl.value)
  // CHECK-NOT:     ematch.
  match.matcher @m root(%root : !pdl.operation) {
    %o = get_operand 0 of %root : !match.optional<!pdl.value>
    %v = is_not_null %o : !pdl.value
    %rs_opt = get_results of %root : !match.optional<!pdl.range<value>>
    %rs = is_not_null %rs_opt : !pdl.range<value>
    %crs = ematch.get_class_results %rs
    %members = ematch.get_class_vals %v
    foreach %m in %members : !pdl.range<value> {
      %d = get_defining_op of %m : !pdl.value -> !match.optional<!pdl.operation>
      %dop = is_not_null %d : !pdl.operation
      %r = get_result 0 of %dop : !match.optional<!pdl.value>
      %rv = is_not_null %r : !pdl.value
      %cr = ematch.get_class_result %rv
      ematch.equivalent %cr, %v
      %rep = ematch.get_class_representative %v
      success @rewriters::@r benefit(1) (%root, %rep : !pdl.operation, !pdl.value)
    }
  }

  // CHECK-LABEL: pdl_interp.func @outside
  // CHECK:         ematch.get_class_result
  pdl_interp.func @outside(%v : !pdl.value) {
    %cr = ematch.get_class_result %v
    pdl_interp.finalize
  }
}
