// RUN: tamagoyaki-opt --ematchify %s | FileCheck %s

// ===----------------------------------------------------------------------===//
// Test the ematchify pass on matchers and rewriters as produced by
// convert-pdl-to-match, using ematch ops. In the matchers:
//   * a matched result is mapped to its e-class result (get_class_result);
//   * get_defining_op, and the rest of its block, loops over the members of the
//     e-class of the value (get_class_vals);
//   * equal on values becomes ematch.equivalent;
//   * a matched operand passed to success becomes its e-class representative,
//     an e-class result the value it was computed from.
// In the rewriters, value arguments and results are mapped to their e-class
// results, created ops are deduplicated, replace becomes union and erase is
// dropped.
// ===----------------------------------------------------------------------===//

module {
  module @rewriters {
    // CHECK-LABEL: match.rewriter @r(
    // CHECK-SAME:      %[[ROOT:.*]]: !pdl.operation, %[[ARG:.*]]: !pdl.value, %[[ARGS:.*]]: !pdl.range<value>, %[[T:.*]]: !pdl.type, %[[DEAD:.*]]: !pdl.operation)
    // CHECK-NEXT:    %[[CA:.*]] = ematch.get_class_result %[[ARG]]
    // CHECK-NEXT:    %[[CAS:.*]] = ematch.get_class_results %[[ARGS]]
    // CHECK-NEXT:    %[[NEG:.*]] = create_operation "arith.negf"(%[[CA]] : !pdl.value) -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[NEGD:.*]] = ematch.dedup %[[NEG]]
    // CHECK-NEXT:    %[[RES:.*]] = pdl.result 0 of %[[NEGD]]
    // CHECK-NEXT:    %[[CRES:.*]] = ematch.get_class_result %[[RES]]
    // CHECK-NEXT:    %[[ADD:.*]] = create_operation "arith.addf"(%[[CRES]], %[[CAS]] : !pdl.value, !pdl.range<value>) -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[ADDD:.*]] = ematch.dedup %[[ADD]]
    // CHECK-NEXT:    %[[NATIVE:.*]] = apply_native_rewrite "build"(%[[CRES]] : !pdl.value) : !pdl.operation
    // CHECK-NEXT:    %[[NATIVED:.*]] = ematch.dedup %[[NATIVE]]
    // CHECK-NEXT:    %[[ALL:.*]] = pdl.results of %[[ADDD]]
    // CHECK-NEXT:    %[[CALL:.*]] = ematch.get_class_results %[[ALL]]
    // CHECK-NEXT:    ematch.union %[[ROOT]] : !pdl.operation, %[[CALL]] : !pdl.range<value>
    // CHECK-NEXT:    %[[RANGE:.*]] = create_range %[[CRES]] : !pdl.value
    // CHECK-NEXT:    ematch.union %[[NATIVED]] : !pdl.operation, %[[RANGE]] : !pdl.range<value>
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
  // CHECK-NEXT:    %[[CR:.*]] = ematch.get_class_result %[[RV]]
  // CHECK-NEXT:    %[[RT:.*]] = get_value_type of %[[CR]] : !pdl.type
  // CHECK-NEXT:    %[[MEMBERS:.*]] = ematch.get_class_vals %[[V0]]
  // The navigation and everything after it loop over the e-class members.
  // CHECK-NEXT:    foreach %[[M:.*]] in %[[MEMBERS]] : !pdl.range<value> {
  // CHECK-NEXT:      %[[D:.*]] = get_defining_op of %[[M]] : !pdl.value
  // CHECK-NEXT:      %[[DOP:.*]] = is_not_null %[[D]] : !pdl.operation
  // CHECK-NEXT:      has_name %[[DOP]], "arith.negf"
  // CHECK-NEXT:      %[[DR:.*]] = get_result 0 of %[[DOP]]
  // CHECK-NEXT:      %[[DRV:.*]] = is_not_null %[[DR]] : !pdl.value
  // CHECK-NEXT:      %[[DCR:.*]] = ematch.get_class_result %[[DRV]]
  // CHECK-NEXT:      ematch.equivalent %[[DCR]], %[[V0]]
  // CHECK-NEXT:      %[[DT:.*]] = get_value_type of %[[DCR]] : !pdl.type
  // Equality of types is untouched.
  // CHECK-NEXT:      equal %[[DT]], %[[RT]] : !pdl.type
  // CHECK-NEXT:      %[[REP:.*]] = ematch.get_class_representative %[[V1]]
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
