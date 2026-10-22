// RUN: tamagoyaki-opt --ematchify %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the ematchify pass on matchers and rewriters as produced by
// convert-pdl-to-match. The e-class helpers become native calls:
//   * a matched result is mapped to its e-class result (get_class_result);
//   * get_defining_op, and the rest of its block, loops over the members of the
//     e-class of the value (get_class_vals);
//   * equal on values becomes the are_equivalent constraint;
//   * a matched operand passed to success becomes its e-class representative,
//     an e-class result the value it was computed from;
//   * in the rewriter, value arguments and results are mapped to their e-class
//     results, created ops are deduplicated, replace becomes union and erase is
//     dropped.
// ===----------------------------------------------------------------------===//

module {
  module @rewriters {
    // CHECK-LABEL: match.rewriter @r(
    // CHECK-SAME:      %[[ROOT:.*]]: !pdl.operation, %[[ARG:.*]]: !pdl.value, %[[ARGS:.*]]: !pdl.range<value>, %[[T:.*]]: !pdl.type, %[[DEAD:.*]]: !pdl.operation)
    // CHECK-NEXT:    %[[CA:.*]] = apply_native_rewrite "get_class_result"(%[[ARG]] : !pdl.value) : !pdl.value
    // CHECK-NEXT:    %[[CAS:.*]] = apply_native_rewrite "get_class_results"(%[[ARGS]] : !pdl.range<value>) : !pdl.range<value>
    // CHECK-NEXT:    %[[NEG:.*]] = create_operation "arith.negf"(%[[CA]] : !pdl.value) -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[NEGD:.*]] = apply_native_rewrite "dedup"(%[[NEG]] : !pdl.operation) : !pdl.operation
    // CHECK-NEXT:    %[[RES:.*]] = pdl.result 0 of %[[NEGD]]
    // CHECK-NEXT:    %[[CRES:.*]] = apply_native_rewrite "get_class_result"(%[[RES]] : !pdl.value) : !pdl.value
    // CHECK-NEXT:    %[[ADD:.*]] = create_operation "arith.addf"(%[[CRES]], %[[CAS]] : !pdl.value, !pdl.range<value>) -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[ADDD:.*]] = apply_native_rewrite "dedup"(%[[ADD]] : !pdl.operation) : !pdl.operation
    // CHECK-NEXT:    %[[NATIVE:.*]] = apply_native_rewrite "build"(%[[CRES]] : !pdl.value) : !pdl.operation
    // CHECK-NEXT:    %[[NATIVED:.*]] = apply_native_rewrite "dedup"(%[[NATIVE]] : !pdl.operation) : !pdl.operation
    // CHECK-NEXT:    %[[ALL:.*]] = pdl.results of %[[ADDD]]
    // CHECK-NEXT:    %[[CALL:.*]] = apply_native_rewrite "get_class_results"(%[[ALL]] : !pdl.range<value>) : !pdl.range<value>
    // CHECK-NEXT:    apply_native_rewrite "union"(%[[ROOT]], %[[CALL]] : !pdl.operation, !pdl.range<value>)
    // CHECK-NEXT:    %[[RANGE:.*]] = create_range %[[CRES]] : !pdl.value
    // CHECK-NEXT:    apply_native_rewrite "union"(%[[NATIVED]], %[[RANGE]] : !pdl.operation, !pdl.range<value>)
    // CHECK-NEXT:  }
    match.rewriter @r(%root : !pdl.operation, %arg : !pdl.value, %args : !pdl.range<value>, %t : !pdl.type, %dead : !pdl.operation) {
      %neg = create_operation "arith.negf"(%arg : !pdl.value) -> (%t : !pdl.type)
      %res = pdl.result 0 of %neg
      %add = create_operation "arith.addf"(%res, %args : !pdl.value, !pdl.range<value>) -> (%t : !pdl.type)
      %native = apply_native_rewrite "build"(%res : !pdl.value) : !pdl.operation
      %all = pdl.results of %add
      replace %root with (%all : !pdl.range<value>)
      replace %native with (%res : !pdl.value)
      erase %dead
    }
  }

  // CHECK-LABEL: match.matcher @m
  // CHECK-SAME:    root(%[[ROOT:.*]]: !pdl.operation)
  // CHECK:         has_name %[[ROOT]], "arith.mulf"
  // CHECK-NEXT:    %[[O0:.*]] = get_operand 0 of %[[ROOT]]
  // CHECK-NEXT:    %[[V0:.*]] = is_not_null %[[O0]] : !pdl.value
  // CHECK-NEXT:    %[[O1:.*]] = get_operand 1 of %[[ROOT]]
  // CHECK-NEXT:    %[[V1:.*]] = is_not_null %[[O1]] : !pdl.value
  // CHECK-NEXT:    %[[R:.*]] = get_result 0 of %[[ROOT]]
  // CHECK-NEXT:    %[[RV:.*]] = is_not_null %[[R]] : !pdl.value
  // CHECK-NEXT:    %[[CR:.*]] = apply_native_rewrite "get_class_result"(%[[RV]] : !pdl.value) : !pdl.value
  // CHECK-NEXT:    %[[RT:.*]] = get_value_type of %[[CR]] : !pdl.type
  // CHECK-NEXT:    %[[MEMBERS:.*]] = apply_native_rewrite "get_class_vals"(%[[V0]] : !pdl.value) : !pdl.range<value>
  // The navigation and everything after it loop over the e-class members.
  // CHECK-NEXT:    foreach %[[M:.*]] in %[[MEMBERS]] : !pdl.range<value> {
  // CHECK-NEXT:      %[[D:.*]] = get_defining_op of %[[M]] : !pdl.value
  // CHECK-NEXT:      %[[DOP:.*]] = is_not_null %[[D]] : !pdl.operation
  // CHECK-NEXT:      has_name %[[DOP]], "arith.negf"
  // CHECK-NEXT:      %[[DR:.*]] = get_result 0 of %[[DOP]]
  // CHECK-NEXT:      %[[DRV:.*]] = is_not_null %[[DR]] : !pdl.value
  // CHECK-NEXT:      %[[DCR:.*]] = apply_native_rewrite "get_class_result"(%[[DRV]] : !pdl.value) : !pdl.value
  // CHECK-NEXT:      apply_native_constraint "are_equivalent"(%[[DCR]], %[[V0]] : !pdl.value, !pdl.value)
  // CHECK-NEXT:      %[[DT:.*]] = get_value_type of %[[DCR]] : !pdl.type
  // Equality of types is untouched.
  // CHECK-NEXT:      equal %[[DT]], %[[RT]] : !pdl.type
  // CHECK-NEXT:      %[[REP:.*]] = apply_native_rewrite "get_class_representative"(%[[V1]] : !pdl.value) : !pdl.value
  // CHECK-NEXT:      success @rewriters::@r benefit(1) (%[[ROOT]], %[[REP]], %[[RV]], %[[RT]], %[[DOP]] : !pdl.operation, !pdl.value, !pdl.value, !pdl.type, !pdl.operation)
  // CHECK-NEXT:    }
  // CHECK-NEXT:  }
  match.matcher @m root(%root : !pdl.operation) {
    has_name %root, "arith.mulf"
    %o0 = get_operand 0 of %root : !match.optional<!pdl.value>
    %v0 = is_not_null %o0 : !pdl.value
    %o1 = get_operand 1 of %root : !match.optional<!pdl.value>
    %v1 = is_not_null %o1 : !pdl.value
    %r = get_result 0 of %root : !match.optional<!pdl.value>
    %rv = is_not_null %r : !pdl.value
    %rt = get_value_type of %rv : !pdl.type
    %d = get_defining_op of %v0 : !pdl.value -> !match.optional<!pdl.operation>
    %dop = is_not_null %d : !pdl.operation
    has_name %dop, "arith.negf"
    %dr = get_result 0 of %dop : !match.optional<!pdl.value>
    %drv = is_not_null %dr : !pdl.value
    equal %drv, %v0 : !pdl.value
    %dt = get_value_type of %drv : !pdl.type
    equal %dt, %rt : !pdl.type
    success @rewriters::@r benefit(1) (%root, %v1, %rv, %rt, %dop : !pdl.operation, !pdl.value, !pdl.value, !pdl.type, !pdl.operation)
  }
}
