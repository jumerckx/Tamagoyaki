// RUN: tamagoyaki-opt %s | tamagoyaki-opt | FileCheck %s

module {
  module @rewriters {
    module @foo {}
    module @bar {}

    // CHECK-LABEL: match.rewriter @rewrite(%arg0: !pdl.operation, %arg1: !pdl.value, %arg2: !pdl.attribute) {
    // CHECK-NEXT:    %[[A:.*]] = apply_native_rewrite "flags"(%arg0 : !pdl.operation) : !pdl.attribute
    // CHECK-NEXT:    %[[T:.*]] = get_value_type of %arg1 : !pdl.type
    // CHECK-NEXT:    %[[OP:.*]] = create_operation "foo.op"(%arg1 : !pdl.value) {"a" = %[[A]], "b" = %arg2} -> (%[[T]] : !pdl.type)
    // CHECK-NEXT:    %[[INF:.*]] = create_operation "bar.op" -> <inferred>
    // CHECK-NEXT:    %[[R:.*]] = pdl.result 0 of %[[OP]]
    // CHECK-NEXT:    %[[RS:.*]] = pdl.results of %arg0
    // CHECK-NEXT:    %[[RANGE:.*]] = create_range %[[R]], %[[RS]] : !pdl.value, !pdl.range<value>
    // CHECK-NEXT:    %[[EMPTY:.*]] = create_range : !pdl.range<type>
    // CHECK-NEXT:    %[[CT:.*]] = constant_type i32
    // CHECK-NEXT:    replace %arg0 with (%[[RANGE]] : !pdl.range<value>)
    // CHECK-NEXT:    replace %[[INF]] with ()
    // CHECK-NEXT:    erase %[[OP]]
    // CHECK-NEXT:  }
    match.rewriter @rewrite(%root : !pdl.operation, %v : !pdl.value, %attr : !pdl.attribute) {
      %a = match.apply_native_rewrite "flags"(%root : !pdl.operation) : !pdl.attribute
      %t = match.get_value_type of %v : !pdl.type
      %op = match.create_operation "foo.op"(%v : !pdl.value) {"a" = %a, "b" = %attr} -> (%t : !pdl.type)
      %inf = match.create_operation "bar.op" -> <inferred>
      %r = pdl.result 0 of %op
      %rs = pdl.results of %root
      %range = match.create_range %r, %rs : !pdl.value, !pdl.range<value>
      %empty = match.create_range : !pdl.range<type>
      %ct = match.constant_type i32
      match.replace %root with (%range : !pdl.range<value>)
      match.replace %inf with ()
      match.erase %op
    }
  }

  // CHECK-LABEL: match.matcher @named root(%arg0: !pdl.operation) {
  // CHECK-NEXT:    success @rewriters::@foo benefit(1)
  match.matcher @named root(%root : !pdl.operation) {
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher root(%arg0: !pdl.operation) {
  // CHECK-NEXT:    success @rewriters::@foo benefit(0)
  match.matcher root(%root : !pdl.operation) {
    match.success @rewriters::@foo benefit(0)
  }

  // CHECK-LABEL: match.matcher @tries
  match.matcher @tries root(%root : !pdl.operation) {
    // CHECK:      try {
    // CHECK-NEXT:   has_name %arg0, "foo.op"
    // CHECK-NEXT:   success @rewriters::@foo benefit(1)
    // CHECK-NEXT: }
    match.try {
      match.has_name %root, "foo.op"
      match.success @rewriters::@foo benefit(1)
    }
    // CHECK:      try {
    // CHECK-NEXT:   try {
    // CHECK-NEXT:     has_name %arg0, "bar.op"
    // CHECK-NEXT:     success @rewriters::@bar benefit(2)
    // CHECK-NEXT:   }
    // CHECK-NEXT:   success @rewriters::@foo benefit(3)
    // CHECK-NEXT: }
    match.try {
      match.try {
        match.has_name %root, "bar.op"
        match.success @rewriters::@bar benefit(2)
      }
      match.success @rewriters::@foo benefit(3)
    }
    // CHECK: success @rewriters::@foo benefit(4)
    match.success @rewriters::@foo benefit(4)
  }

  // CHECK-LABEL: match.matcher @switch_names
  match.matcher @switch_names root(%root : !pdl.operation) {
    // CHECK:      switch_op_name %arg0
    // CHECK-NEXT: case "foo.op" {
    // CHECK-NEXT:   success @rewriters::@foo benefit(1)
    // CHECK-NEXT: }
    match.switch_op_name %root
    case "foo.op" {
      match.success @rewriters::@foo benefit(1)
    }

    // CHECK:      switch_op_name %arg0
    // CHECK-NEXT: case "a.op" {
    // CHECK-NEXT:   success @rewriters::@foo benefit(1)
    // CHECK-NEXT: }
    // CHECK-NEXT: case "b.op" {
    // CHECK-NEXT:   switch_op_name %arg0
    // CHECK-NEXT:   case "c.op" {
    // CHECK-NEXT:     success @rewriters::@bar benefit(2)
    // CHECK-NEXT:   }
    // CHECK-NEXT: }
    // CHECK-NEXT: case "d.op" {
    // CHECK-NEXT:   success @rewriters::@foo benefit(3)
    // CHECK-NEXT: }
    match.switch_op_name %root
    case "a.op" {
      match.success @rewriters::@foo benefit(1)
    }
    case "b.op" {
      match.switch_op_name %root
      case "c.op" {
        match.success @rewriters::@bar benefit(2)
      }
    }
    case "d.op" {
      match.success @rewriters::@foo benefit(3)
    }
    match.success @rewriters::@foo benefit(0)
  }

  // CHECK-LABEL: match.matcher @switch_types
  match.matcher @switch_types root(%root : !pdl.operation) {
    %r0 = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v0 = match.is_not_null %r0 : !pdl.value
    // CHECK: %[[T:.*]] = get_value_type of %{{.*}} : !pdl.type
    %t0 = match.get_value_type of %v0 : !pdl.type
    // CHECK:      switch_type %[[T]]
    // CHECK-NEXT: case i32 {
    // CHECK-NEXT:   success @rewriters::@foo benefit(1)
    // CHECK-NEXT: }
    // CHECK-NEXT: case i64 {
    // CHECK-NEXT:   success @rewriters::@bar benefit(2)
    // CHECK-NEXT: }
    match.switch_type %t0
    case i32 {
      match.success @rewriters::@foo benefit(1)
    }
    case i64 {
      match.success @rewriters::@bar benefit(2)
    }
    match.success @rewriters::@foo benefit(0)
  }

  // CHECK-LABEL: match.matcher @constants
  match.matcher @constants root(%root : !pdl.operation) {
    // CHECK: %{{.*}} = constant_attribute 10 : i64
    %attr = match.constant_attribute 10 : i64
    // CHECK: %{{.*}} = constant_attribute "hello"
    %str = match.constant_attribute "hello"
    // CHECK: %{{.*}} = constant_attribute unit
    %unit = match.constant_attribute unit
    // CHECK: %{{.*}} = constant_attribute i32
    %typeAttr = match.constant_attribute i32
    // CHECK: %{{.*}} = constant_attribute dense<[1, 2]> : tensor<2xi32>
    %dense = match.constant_attribute dense<[1, 2]> : tensor<2xi32>
    // CHECK: %{{.*}} = constant_type i32
    %type = match.constant_type i32
    // CHECK: %{{.*}} = constant_types [i32, i64]
    %types = match.constant_types [i32, i64]
    // CHECK: %{{.*}} = constant_types []
    %empty = match.constant_types []

    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @constant_use
  match.matcher @constant_use root(%root : !pdl.operation) {
    // CHECK: %[[ATTR:.*]] = constant_attribute 10 : i64
    %attr = match.constant_attribute 10 : i64
    // CHECK: %[[TYPES:.*]] = constant_types [i32]
    %types = match.constant_types [i32]
    // CHECK: apply_native_constraint "c"(%[[ATTR]], %[[TYPES]] : !pdl.attribute, !pdl.range<type>)
    match.apply_native_constraint "c"(%attr, %types : !pdl.attribute, !pdl.range<type>)
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @nav_nullable
  match.matcher @nav_nullable root(%root : !pdl.operation) {
    // CHECK: %[[O0:.*]] = get_operand 0 of %arg0 : !match.optional<!pdl.value>
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    // CHECK: %[[OS:.*]] = get_operands of %arg0 : !match.optional<!pdl.range<value>>
    %os = match.get_operands of %root : !match.optional<!pdl.range<value>>
    // CHECK: %{{.*}} = get_operands 1 of %arg0 : !match.optional<!pdl.range<value>>
    %os1 = match.get_operands 1 of %root : !match.optional<!pdl.range<value>>
    // CHECK: %{{.*}} = get_result 0 of %arg0 : !match.optional<!pdl.value>
    %r0 = match.get_result 0 of %root : !match.optional<!pdl.value>
    // CHECK: %{{.*}} = get_results of %arg0 : !match.optional<!pdl.range<value>>
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    // CHECK: %{{.*}} = get_results 1 of %arg0 : !match.optional<!pdl.range<value>>
    %rs1 = match.get_results 1 of %root : !match.optional<!pdl.range<value>>
    // CHECK: %{{.*}} = get_attribute "attr" of %arg0 : !match.optional<!pdl.attribute>
    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>

    // CHECK: %[[V0:.*]] = is_not_null %[[O0]] : !pdl.value
    %v0 = match.is_not_null %o0 : !pdl.value
    // CHECK: %{{.*}} = get_defining_op of %[[V0]] : !pdl.value -> !match.optional<!pdl.operation>
    %d = match.get_defining_op of %v0 : !pdl.value -> !match.optional<!pdl.operation>
    // CHECK: %[[VS:.*]] = is_not_null %[[OS]] : !pdl.range<value>
    %vs = match.is_not_null %os : !pdl.range<value>
    // CHECK: %{{.*}} = get_defining_op of %[[VS]] : !pdl.range<value> -> !match.optional<!pdl.operation>
    %dr = match.get_defining_op of %vs : !pdl.range<value> -> !match.optional<!pdl.operation>
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @nav_plain
  match.matcher @nav_plain root(%root : !pdl.operation) {
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    // CHECK: %[[V0:.*]] = is_not_null
    %v0 = match.is_not_null %o0 : !pdl.value
    %os = match.get_operands of %root : !match.optional<!pdl.range<value>>
    // CHECK: %[[VS:.*]] = is_not_null
    %vs = match.is_not_null %os : !pdl.range<value>

    // CHECK: %{{.*}} = get_value_type of %[[V0]] : !pdl.type
    %t0 = match.get_value_type of %v0 : !pdl.type
    // CHECK: %{{.*}} = get_value_type of %[[VS]] : !pdl.range<type>
    %ts = match.get_value_type of %vs : !pdl.range<type>

    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    // CHECK: %[[AV:.*]] = is_not_null
    %av = match.is_not_null %a : !pdl.attribute
    // CHECK: %{{.*}} = get_attribute_type of %[[AV]]
    %at = match.get_attribute_type of %av
    // CHECK: %[[USERS:.*]] = get_users of %[[V0]]
    %users = match.get_users of %v0

    // CHECK: %{{.*}} = extract 0 of %[[VS]] : !pdl.value
    %ex = match.extract 0 of %vs : !pdl.value
    // CHECK: %{{.*}} = extract 1 of %[[USERS]] : !pdl.operation
    %exo = match.extract 1 of %users : !pdl.operation
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @loops
  match.matcher @loops root(%root : !pdl.operation) {
    %os = match.get_operands of %root : !match.optional<!pdl.range<value>>
    // CHECK: %[[VS:.*]] = is_not_null
    %vs = match.is_not_null %os : !pdl.range<value>
    // CHECK: foreach %[[E:.*]] in %[[VS]] : !pdl.range<value> {
    match.foreach %e in %vs : !pdl.range<value> {
      // CHECK: %[[USERS:.*]] = get_users of %[[E]]
      %users = match.get_users of %e
      // CHECK: foreach %[[U:.*]] in %[[USERS]] : !pdl.range<operation> {
      match.foreach %u in %users : !pdl.range<operation> {
        // CHECK: has_name %[[U]], "foo.op"
        match.has_name %u, "foo.op"
        // CHECK: success @rewriters::@foo benefit(1) (%[[U]] : !pdl.operation)
        match.success @rewriters::@foo benefit(1) (%u : !pdl.operation)
      }
    }
  }

  // CHECK-LABEL: match.matcher @tests
  match.matcher @tests root(%root : !pdl.operation) {
    // CHECK: has_name %arg0, "foo.op"
    match.has_name %root, "foo.op"
    // CHECK: check_operand_count %arg0 is 2
    match.check_operand_count %root is 2
    // CHECK: check_operand_count %arg0 is at_least 2
    match.check_operand_count %root is at_least 2
    // CHECK: check_result_count %arg0 is 1
    match.check_result_count %root is 1
    // CHECK: check_result_count %arg0 is at_least 1
    match.check_result_count %root is at_least 1

    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    // CHECK: %[[V0:.*]] = is_not_null
    %v0 = match.is_not_null %o0 : !pdl.value
    %o1 = match.get_operand 1 of %root : !match.optional<!pdl.value>
    // CHECK: %[[V1:.*]] = is_not_null
    %v1 = match.is_not_null %o1 : !pdl.value
    // CHECK: equal %[[V0]], %[[V1]] : !pdl.value
    match.equal %v0, %v1 : !pdl.value

    // CHECK: %[[T0:.*]] = get_value_type of %[[V0]]
    %t0 = match.get_value_type of %v0 : !pdl.type
    // CHECK: has_type %[[T0]], i32
    match.has_type %t0, i32
    %os = match.get_operands of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %os : !pdl.range<value>
    // CHECK: %[[TS:.*]] = get_value_type of %{{.*}} : !pdl.range<type>
    %ts = match.get_value_type of %vs : !pdl.range<type>
    // CHECK: has_types %[[TS]], [i32, i64]
    match.has_types %ts, [i32, i64]

    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    // CHECK: %[[AV:.*]] = is_not_null
    %av = match.is_not_null %a : !pdl.attribute
    // CHECK: has_attr_value %[[AV]] is 10 : i64
    match.has_attr_value %av is 10 : i64
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @natives
  match.matcher @natives root(%root : !pdl.operation) {
    // CHECK: apply_native_constraint "c0"(%arg0 : !pdl.operation)
    match.apply_native_constraint "c0"(%root : !pdl.operation)
    // CHECK: %{{.*}} = apply_native_constraint "c1"(%arg0 : !pdl.operation) : !pdl.attribute
    %c1 = match.apply_native_constraint "c1"(%root : !pdl.operation) : !pdl.attribute
    // CHECK: %{{.*}}:2 = apply_native_constraint "c2"(%arg0 : !pdl.operation) : !pdl.attribute, !pdl.type
    %c2:2 = match.apply_native_constraint "c2"(%root : !pdl.operation) : !pdl.attribute, !pdl.type
    // CHECK: apply_native_constraint "c3"(%arg0 : !pdl.operation) is_negated = true
    match.apply_native_constraint "c3"(%root : !pdl.operation) is_negated = true

    // CHECK: %{{.*}} = apply_native_rewrite "r1"(%arg0 : !pdl.operation) : !pdl.attribute
    %r1 = match.apply_native_rewrite "r1"(%root : !pdl.operation) : !pdl.attribute
    // CHECK: %{{.*}} = apply_native_rewrite "r2" : !pdl.attribute
    %r2 = match.apply_native_rewrite "r2" : !pdl.attribute
    // CHECK: apply_native_rewrite "r3"(%arg0 : !pdl.operation)
    match.apply_native_rewrite "r3"(%root : !pdl.operation)
    match.success @rewriters::@foo benefit(1)
  }

  // CHECK-LABEL: match.matcher @successes
  match.matcher @successes root(%root : !pdl.operation) {
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    // CHECK: %[[V0:.*]] = is_not_null
    %v0 = match.is_not_null %o0 : !pdl.value
    // CHECK: success @rewriters::@foo benefit(3) (%arg0, %[[V0]] : !pdl.operation, !pdl.value)
    match.success @rewriters::@foo benefit(3) (%root, %v0 : !pdl.operation, !pdl.value)
  }

  // CHECK-LABEL: func private @optional_types
  // CHECK-SAME:    !match.optional<!pdl.attribute>
  // CHECK-SAME:    !match.optional<!pdl.operation>
  // CHECK-SAME:    !match.optional<!pdl.type>
  // CHECK-SAME:    !match.optional<!pdl.value>
  // CHECK-SAME:    !match.optional<!pdl.range<value>>
  // CHECK-SAME:    !match.optional<!pdl.range<type>>
  func.func private @optional_types(
    !match.optional<!pdl.attribute>,
    !match.optional<!pdl.operation>,
    !match.optional<!pdl.type>,
    !match.optional<!pdl.value>,
    !match.optional<!pdl.range<value>>,
    !match.optional<!pdl.range<type>>)
}
