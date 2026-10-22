// RUN: tamagoyaki-opt %s -split-input-file -convert-match-to-pdl-interp | FileCheck %s

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.branch ^bb1
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
module {
  module @rewriters { module @r {} }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "foo.op" -> ^bb2, ^bb1
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.check_operand_count of %arg0 is 1 -> ^bb3, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r(%arg0 : !pdl.operation) : benefit(1), loc([%arg0]), root("foo.op") -> ^bb4
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.branch ^bb1
module {
  module @rewriters { module @r {} }
  match.matcher @flat root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1) (%root : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "foo.op" -> ^bb3, ^bb2
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "bar.op" -> ^bb5, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("foo.op") -> ^bb4
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.branch ^bb2
// CHECK-NEXT:  ^bb5:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(2), loc([%arg0]), root("bar.op") -> ^bb6
// CHECK-NEXT:  ^bb6:
// CHECK-NEXT:    pdl_interp.branch ^bb1
module {
  module @rewriters { module @r {} }
  match.matcher @first root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @second root(%root : !pdl.operation) {
    match.has_name %root, "bar.op"
    match.success @rewriters::@r benefit(2)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "foo.op" -> ^bb3, ^bb2
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.check_operand_count of %arg0 is 2 -> ^bb5, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("foo.op") -> ^bb4
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.branch ^bb2
// CHECK-NEXT:  ^bb5:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(2), loc([%arg0]) -> ^bb6
module {
  module @rewriters { module @r {} }
  match.matcher @with_try root(%root : !pdl.operation) {
    match.try {
      match.has_name %root, "foo.op"
      match.success @rewriters::@r benefit(1)
    }
    match.check_operand_count %root is 2
    match.success @rewriters::@r benefit(2)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "inner.op" -> ^bb4, ^bb3
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.check_result_count of %arg0 is 3 -> ^bb8, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.check_operand_count of %arg0 is 1 -> ^bb6, ^bb2
// CHECK:         pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("inner.op")
// CHECK:         pdl_interp.record_match @rewriters::@r : benefit(2), loc([%arg0]) ->
// CHECK:         pdl_interp.record_match @rewriters::@r : benefit(3), loc([%arg0]) ->
module {
  module @rewriters { module @r {} }
  match.matcher @nested_try root(%root : !pdl.operation) {
    match.try {
      match.try {
        match.has_name %root, "inner.op"
        match.success @rewriters::@r benefit(1)
      }
      match.check_operand_count %root is 1
      match.success @rewriters::@r benefit(2)
    }
    match.check_result_count %root is 3
    match.success @rewriters::@r benefit(3)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.switch_operation_name of %arg0 to ["a.op", "b.op"](^bb3, ^bb4) -> ^bb2
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.check_operand_count of %arg0 is 9 -> ^bb7, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("a.op") -> ^bb5
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(2), loc([%arg0]), root("b.op") -> ^bb6
// CHECK-NEXT:  ^bb5:
// CHECK-NEXT:    pdl_interp.branch ^bb2
// CHECK-NEXT:  ^bb6:
// CHECK-NEXT:    pdl_interp.branch ^bb2
// CHECK-NEXT:  ^bb7:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(3), loc([%arg0]) -> ^bb8
module {
  module @rewriters { module @r {} }
  match.matcher @sw_mid root(%root : !pdl.operation) {
    match.switch_op_name %root
    case "a.op" { match.success @rewriters::@r benefit(1) }
    case "b.op" { match.success @rewriters::@r benefit(2) }
    match.check_operand_count %root is 9
    match.success @rewriters::@r benefit(3)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.switch_operation_name of %arg0 to ["a.op", "b.op"](^bb2, ^bb3) -> ^bb1
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
module {
  module @rewriters { module @r {} }
  match.matcher @sw_last root(%root : !pdl.operation) {
    match.switch_op_name %root
    case "a.op" { match.success @rewriters::@r benefit(1) }
    case "b.op" { match.success @rewriters::@r benefit(2) }
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         pdl_interp.switch_type %{{.*}} to [i32, i64]
module {
  module @rewriters { module @r {} }
  match.matcher @sw_type root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.switch_type %t
    case i32 { match.success @rewriters::@r benefit(1) }
    case i64 { match.success @rewriters::@r benefit(2) }
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-DAG:     pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("foo.op")
// CHECK-DAG:     pdl_interp.record_match @rewriters::@r0 : benefit(2), loc([%arg0]) ->
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @sw_type_name_scope root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.switch_type %t
    case i32 {
      match.has_name %root, "foo.op"
      match.success @rewriters::@r benefit(1)
    }
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    %[[RS:.*]] = pdl_interp.get_results of %arg0 : !pdl.range<value>
// CHECK-NEXT:    pdl_interp.is_not_null %[[RS]] : !pdl.range<value> -> ^bb2, ^bb1
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.foreach %[[E:.*]] : !pdl.value in %[[RS]] {
// CHECK-NEXT:      %[[D:.*]] = pdl_interp.get_defining_op of %[[E]] : !pdl.value
// CHECK-NEXT:      pdl_interp.is_not_null %[[D]] : !pdl.operation -> ^bb2, ^bb1
// CHECK-NEXT:    ^bb1:
// CHECK-NEXT:      pdl_interp.continue
// CHECK-NEXT:    ^bb2:
// CHECK-NEXT:      pdl_interp.check_operation_name of %[[D]] is "inner.op" -> ^bb3, ^bb1
// CHECK-NEXT:    ^bb3:
// CHECK-NEXT:      pdl_interp.record_match @rewriters::@r(%arg0, %[[D]] : !pdl.operation, !pdl.operation) : benefit(1), loc([%arg0, %[[D]]]) -> ^bb4
// CHECK-NEXT:    ^bb4:
// CHECK-NEXT:      pdl_interp.branch ^bb1
// CHECK-NEXT:    } -> ^bb1
module {
  module @rewriters { module @r {} }
  match.matcher @each root(%root : !pdl.operation) {
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    match.foreach %e in %vs : !pdl.range<value> {
      %d = match.get_defining_op of %e : !pdl.value -> !match.optional<!pdl.operation>
      %dop = match.is_not_null %d : !pdl.operation
      match.has_name %dop, "inner.op"
      match.success @rewriters::@r benefit(1) (%root, %dop : !pdl.operation, !pdl.operation)
    }
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    %[[RS:.*]] = pdl_interp.get_results of %arg0 : !pdl.range<value>
// CHECK-NEXT:    pdl_interp.is_not_null %[[RS]] : !pdl.range<value> -> ^bb2, ^bb1
// CHECK-NEXT:  ^bb1:
// CHECK-NEXT:    pdl_interp.finalize
// CHECK-NEXT:  ^bb2:
// CHECK-NEXT:    pdl_interp.foreach %[[E:.*]] : !pdl.value in %[[RS]] {
// CHECK-NEXT:      %[[T:.*]] = pdl_interp.get_value_type of %[[E]] : !pdl.type
// CHECK-NEXT:      pdl_interp.check_type %[[T]] is i32 -> ^bb2, ^bb1
// CHECK-NEXT:    ^bb1:
// CHECK-NEXT:      pdl_interp.continue
// CHECK-NEXT:    ^bb2:
// CHECK-NEXT:      pdl_interp.record_match @rewriters::@r{{.*}}benefit(2){{.*}} -> ^bb3
// CHECK-NEXT:    ^bb3:
// CHECK-NEXT:      pdl_interp.branch ^bb1
// CHECK-NEXT:    } -> ^bb3
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.check_operation_name of %arg0 is "fallback.op" -> ^bb4, ^bb1
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r0{{.*}}benefit(1){{.*}} -> ^bb5
// CHECK-NEXT:  ^bb5:
// CHECK-NEXT:    pdl_interp.branch ^bb1
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @each_then_alternative root(%root : !pdl.operation) {
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    match.foreach %e in %vs : !pdl.range<value> {
      %t = match.get_value_type of %e : !pdl.type
      match.has_type %t, i32
      match.success @rewriters::@r benefit(2)
    }
    match.has_name %root, "fallback.op"
    match.success @rewriters::@r0 benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-DAG:     pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0, %{{.*}}]), root("foo.op")
// CHECK-DAG:     pdl_interp.record_match @rewriters::@r0 : benefit(2), loc([%arg0]) ->
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @foreach_name_scope root(%root : !pdl.operation) {
    %os = match.get_operands of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %os : !pdl.range<value>
    match.foreach %e in %vs : !pdl.range<value> {
      %users = match.get_users of %e
      match.foreach %u in %users : !pdl.range<operation> {
        match.has_name %root, "foo.op"
        match.success @rewriters::@r benefit(1)
      }
    }
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:       ^bb2:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]), root("foo.op") -> ^bb3
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    pdl_interp.record_match @rewriters::@r0 : benefit(2), loc([%arg0]), root("foo.op") -> ^bb4
// CHECK-NEXT:  ^bb4:
// CHECK-NEXT:    pdl_interp.branch ^bb1
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @multi root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    %[[A:.*]] = pdl_interp.apply_rewrite "mk"(%arg0 : !pdl.operation) : !pdl.attribute
// CHECK-NEXT:    pdl_interp.apply_constraint "c"(%[[A]] : !pdl.attribute) -> ^bb2, ^bb1
module {
  module @rewriters { module @r {} }
  match.matcher @nat root(%root : !pdl.operation) {
    %a = match.apply_native_rewrite "mk"(%root : !pdl.operation) : !pdl.attribute
    match.apply_native_constraint "c"(%a : !pdl.attribute)
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK-NEXT:    pdl_interp.apply_constraint "c"(%arg0 : !pdl.operation) {isNegated = true} -> ^bb2, ^bb1
// CHECK:       ^bb2:
// CHECK-NEXT:    %[[O:.*]] = pdl_interp.get_operand 0 of %arg0
// CHECK-NEXT:    pdl_interp.is_not_null %[[O]] : !pdl.value -> ^bb3, ^bb1
// CHECK-NEXT:  ^bb3:
// CHECK-NEXT:    %[[T:.*]] = pdl_interp.get_value_type of %[[O]] : !pdl.type
// CHECK-NEXT:    pdl_interp.check_type %[[T]] is i32 -> ^bb4, ^bb1
module {
  module @rewriters { module @r {} }
  match.matcher @neg root(%root : !pdl.operation) {
    match.apply_native_constraint "c"(%root : !pdl.operation) is_negated = true
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %o : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.has_type %t, i32
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0]) -> ^bb3
// CHECK-NOT:     root(
module {
  module @rewriters { module @r {} }
  match.matcher @noname root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         pdl_interp.check_operation_name of %[[D:.*]] is "other.op"
// CHECK:         pdl_interp.record_match @rewriters::@r : benefit(1), loc([%arg0, %[[D]]]) -> ^bb5
module {
  module @rewriters { module @r {} }
  match.matcher @nonroot root(%root : !pdl.operation) {
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %o : !pdl.value
    %d = match.get_defining_op of %v : !pdl.value -> !match.optional<!pdl.operation>
    %dop = match.is_not_null %d : !pdl.operation
    match.has_name %dop, "other.op"
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         pdl_interp.check_operand_count of %arg0 is at_least 1
// CHECK:         pdl_interp.check_result_count of %arg0 is at_least 1
// CHECK:         %[[A:.*]] = pdl_interp.get_attribute "attr" of %arg0
// CHECK:         pdl_interp.is_not_null %[[A]] : !pdl.attribute
// CHECK:         pdl_interp.check_attribute %[[A]] is 10 : i64
// CHECK:         %[[AT:.*]] = pdl_interp.get_attribute_type of %[[A]]
// CHECK:         pdl_interp.check_type %[[AT]] is i64
// CHECK:         %[[RS:.*]] = pdl_interp.get_results of %arg0 : !pdl.range<value>
// CHECK:         %[[TS:.*]] = pdl_interp.get_value_type of %[[RS]] : !pdl.range<type>
// CHECK:         pdl_interp.check_types %[[TS]] are [i32]
// CHECK:         %[[EX:.*]] = pdl_interp.extract 0 of %[[RS]] : !pdl.value
// CHECK:         pdl_interp.are_equal
module {
  module @rewriters { module @r {} }
  match.matcher @tests root(%root : !pdl.operation) {
    match.check_operand_count %root is at_least 1
    match.check_result_count %root is at_least 1

    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    %av = match.is_not_null %a : !pdl.attribute
    match.has_attr_value %av is 10 : i64
    %at = match.get_attribute_type of %av
    match.has_type %at, i64

    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    %ts = match.get_value_type of %vs : !pdl.range<type>
    match.has_types %ts, [i32]

    %ex = match.extract 0 of %vs : !pdl.value
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %ov = match.is_not_null %o : !pdl.value
    match.equal %ex, %ov : !pdl.value
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         %[[U:.*]] = pdl_interp.get_users of %{{.*}} : !pdl.value
// CHECK:         pdl_interp.foreach %{{.*}} : !pdl.operation in %[[U]]
module {
  module @rewriters { module @r {} }
  match.matcher @users root(%root : !pdl.operation) {
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %o : !pdl.value
    %u = match.get_users of %v
    match.foreach %e in %u : !pdl.range<operation> {
      match.has_name %e, "user.op"
      match.success @rewriters::@r benefit(1) (%root, %e : !pdl.operation, !pdl.operation)
    }
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher
// CHECK: %[[ATTR:.*]] = pdl_interp.create_attribute 10 : i64
// CHECK-NEXT: %[[TYPE:.*]] = pdl_interp.create_type i32
// CHECK-NEXT: %[[TYPES:.*]] = pdl_interp.create_types [i32, i64]
// CHECK-NEXT: pdl_interp.apply_constraint "c"(%[[ATTR]], %[[TYPE]], %[[TYPES]] : !pdl.attribute, !pdl.type, !pdl.range<type>)
module {
  module @rewriters {
    module @rewriter {}
  }

  match.matcher @constants root(%root : !pdl.operation) {
    %attr = match.constant_attribute 10 : i64
    %type = match.constant_type i32
    %types = match.constant_types [i32, i64]
    match.apply_native_constraint "c"(%attr, %type, %types : !pdl.attribute, !pdl.type, !pdl.range<type>)
    match.success @rewriters::@rewriter benefit(1) (%root : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: pdl_interp.func @matcher(%arg0: !pdl.operation) {
// CHECK:         pdl_interp.record_match @rewriters::@r(%arg0, %{{.*}} : !pdl.operation, !pdl.value) : benefit(1), generatedOps(["foo.op", "bar.op"]), loc([%arg0]) -> ^bb{{.*}}
// CHECK-LABEL: module @rewriters
// CHECK-NEXT:    pdl_interp.func @r(%[[ROOT:.*]]: !pdl.operation, %[[V:.*]]: !pdl.value) {
// CHECK-NEXT:      %[[A:.*]] = pdl_interp.apply_rewrite "flags"(%[[ROOT]] : !pdl.operation) : !pdl.attribute
// CHECK-NEXT:      %[[CA:.*]] = pdl_interp.create_attribute 1 : i32
// CHECK-NEXT:      %[[T:.*]] = pdl_interp.get_value_type of %[[V]] : !pdl.type
// CHECK-NEXT:      %[[TS:.*]] = pdl_interp.create_types [i32, i64]
// CHECK-NEXT:      %[[OP:.*]] = pdl_interp.create_operation "foo.op"(%[[V]] : !pdl.value) {"a" = %[[A]], "b" = %[[CA]]} -> (%[[T]], %[[TS]] : !pdl.type, !pdl.range<type>)
// CHECK-NEXT:      %[[INF:.*]] = pdl_interp.create_operation "bar.op"
// CHECK-NEXT:      %[[R:.*]] = pdl_interp.get_result 0 of %[[OP]]
// CHECK-NEXT:      %[[RS:.*]] = pdl_interp.get_results 1 of %[[OP]] : !pdl.range<value>
// CHECK-NEXT:      %[[RANGE:.*]] = pdl_interp.create_range %[[R]], %[[RS]] : !pdl.value, !pdl.range<value>
// CHECK-NEXT:      pdl_interp.replace %[[ROOT]] with (%[[RANGE]] : !pdl.range<value>)
// CHECK-NEXT:      pdl_interp.erase %[[INF]]
// CHECK-NEXT:      pdl_interp.finalize
// CHECK-NEXT:    }
module {
  module @rewriters {
    match.rewriter @r(%root : !pdl.operation, %v : !pdl.value) {
      %a = apply_native_rewrite "flags"(%root : !pdl.operation) : !pdl.attribute
      %ca = constant_attribute 1 : i32
      %t = get_value_type of %v : !pdl.type
      %ts = constant_types [i32, i64]
      %op = create_operation "foo.op"(%v : !pdl.value) {"a" = %a, "b" = %ca} -> (%t, %ts : !pdl.type, !pdl.range<type>)
      %inf = create_operation "bar.op"
      %r = pdl.result 0 of %op
      %rs = pdl.results 1 of %op -> !pdl.range<value>
      %range = create_range %r, %rs : !pdl.value, !pdl.range<value>
      replace %root with (%range : !pdl.range<value>)
      erase %inf
    }
  }
  match.matcher @m root(%root : !pdl.operation) {
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %o : !pdl.value
    match.success @rewriters::@r benefit(1) (%root, %v : !pdl.operation, !pdl.value)
  }
}
