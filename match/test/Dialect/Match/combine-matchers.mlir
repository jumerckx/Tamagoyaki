// RUN: tamagoyaki-opt %s -split-input-file -match-combine-matchers | FileCheck %s

// CHECK-LABEL: module
// CHECK-NOT:   match.matcher
module {
  module @rewriters { module @r {} }
}

// -----

// CHECK-LABEL: match.matcher @only root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "foo.op"
// CHECK-NEXT:    check_operand_count %arg0 is 1
// CHECK-NEXT:    success @rewriters::@r benefit(3) (%arg0 : !pdl.operation)
// CHECK-NOT:     try
module {
  module @rewriters { module @r {} }
  match.matcher @only root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(3) (%root : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_operand_count %arg0 is 1
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_result_count %arg0 is 2
// CHECK-NEXT:      success @rewriters::@r benefit(2)
// CHECK-NEXT:    }
module {
  module @rewriters { module @r {} }
  match.matcher @disjoint_a root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @disjoint_b root(%root : !pdl.operation) {
    match.check_result_count %root is 2
    match.success @rewriters::@r benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    switch_op_name %arg0
// CHECK-NEXT:    case "foo.op" {
// CHECK-NEXT:      check_operand_count %arg0 is 0
// CHECK-NEXT:      check_result_count %arg0 is 0
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:    case "bar.op" {
// CHECK-NEXT:      check_operand_count %arg0 is 0
// CHECK-NEXT:      check_result_count %arg0 is 0
// CHECK-NEXT:      success @rewriters::@r0 benefit(2)
// CHECK-NEXT:    }
// CHECK-NEXT:    case "baz.op" {
// CHECK-NEXT:      check_operand_count %arg0 is 0
// CHECK-NEXT:      check_result_count %arg0 is 0
// CHECK-NEXT:      success @rewriters::@r1 benefit(3)
// CHECK-NEXT:    }
// CHECK-NOT:     try
module {
  module @rewriters { module @r {} module @r0 {} module @r1 {} }
  match.matcher @sw_a root(%root : !pdl.operation) {
    match.check_operand_count %root is 0
    match.check_result_count %root is 0
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @sw_b root(%root : !pdl.operation) {
    match.check_operand_count %root is 0
    match.check_result_count %root is 0
    match.has_name %root, "bar.op"
    match.success @rewriters::@r0 benefit(2)
  }
  match.matcher @sw_c root(%root : !pdl.operation) {
    match.check_operand_count %root is 0
    match.check_result_count %root is 0
    match.has_name %root, "baz.op"
    match.success @rewriters::@r1 benefit(3)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    %[[R:.*]] = get_result 0 of %arg0 : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[V:.*]] = is_not_null %[[R]]
// CHECK-NEXT:    %[[T:.*]] = get_value_type of %[[V]] : !pdl.type
// CHECK-NEXT:    switch_type %[[T]]
// CHECK-NEXT:    case i32 {
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:    case i64 {
// CHECK-NEXT:      success @rewriters::@r0 benefit(2)
// CHECK-NEXT:    }
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @st_a root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.has_type %t, i32
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @st_b root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.has_type %t, i64
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
// CHECK-NOT:     switch_op_name
// CHECK:         try {
// CHECK-NEXT:      has_name %{{.*}}, "foo.op"
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @one_case_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @one_case_b root(%root : !pdl.operation) {
    match.check_operand_count %root is 3
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
// CHECK-NOT:     switch_op_name
// CHECK:         try {
// CHECK-NEXT:      has_name %{{.*}}, "foo.op"
// CHECK:         try {
// CHECK-NEXT:      check_operand_count %{{.*}} is 3
// CHECK:         try {
// CHECK-NEXT:      has_name %{{.*}}, "bar.op"
module {
  module @rewriters { module @r {} module @r0 {} module @r1 {} }
  match.matcher @nc_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @nc_b root(%root : !pdl.operation) {
    match.check_operand_count %root is 3
    match.success @rewriters::@r0 benefit(2)
  }
  match.matcher @nc_c root(%root : !pdl.operation) {
    match.has_name %root, "bar.op"
    match.success @rewriters::@r1 benefit(3)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_operand_count %arg0 is 7
// CHECK-NEXT:      check_result_count %arg0 is 1
// CHECK:         try {
// CHECK-NEXT:      check_operand_count %arg0 is 8
// CHECK-NEXT:      check_result_count %arg0 is 1
// CHECK:         try {
// CHECK-NEXT:      check_operand_count %arg0 is 9
// CHECK-NEXT:      check_result_count %arg0 is 1
// CHECK:         try {
// CHECK-NEXT:      check_operand_count %arg0 is 10
module {
  module @rewriters { module @r {} module @r0 {} module @r1 {} module @r2 {} }
  match.matcher @cost_a root(%root : !pdl.operation) {
    match.check_operand_count %root is 7
    match.check_result_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @cost_b root(%root : !pdl.operation) {
    match.check_result_count %root is 1
    match.check_operand_count %root is 8
    match.success @rewriters::@r0 benefit(2)
  }
  match.matcher @cost_c root(%root : !pdl.operation) {
    match.check_result_count %root is 1
    match.check_operand_count %root is 9
    match.success @rewriters::@r1 benefit(3)
  }
  match.matcher @cost_d root(%root : !pdl.operation) {
    match.check_operand_count %root is 10
    match.success @rewriters::@r2 benefit(4)
  }
}

// -----

// CHECK-LABEL: match.matcher @dead_nav root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "foo.op"
// CHECK-NEXT:    %[[O:.*]] = get_operand 0 of %arg0 : !match.optional<!pdl.value>
// CHECK-NEXT:    %{{.*}} = is_not_null %[[O]]
// CHECK-NEXT:    success @rewriters::@r benefit(1)
// CHECK-NOT:     get_value_type
module {
  module @rewriters { module @r {} }
  match.matcher @dead_nav root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %o = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %o : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "foo.op"
// CHECK-NEXT:    try {
// CHECK-NEXT:      %[[A:.*]] = get_attribute "attr" of %arg0 : !match.optional<!pdl.attribute>
// CHECK-NEXT:      %[[AV:.*]] = is_not_null %[[A]]
// CHECK-NEXT:      has_attr_value %[[AV]] is 10 : i64
// CHECK:         try {
// CHECK-NEXT:      check_operand_count %arg0 is 4
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @sink_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    %av = match.is_not_null %a : !pdl.attribute
    match.has_attr_value %av is 10 : i64
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @sink_b root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.check_operand_count %root is 4
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "foo.op"
// CHECK-NEXT:    %[[A:.*]] = get_attribute "attr" of %arg0 : !match.optional<!pdl.attribute>
// CHECK-NEXT:    %[[AV:.*]] = is_not_null %[[A]]
// CHECK-NEXT:    try {
// CHECK-NEXT:      has_attr_value %[[AV]] is 10 : i64
// CHECK:         try {
// CHECK-NEXT:      has_attr_value %[[AV]] is 20 : i64
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @keep_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    %av = match.is_not_null %a : !pdl.attribute
    match.has_attr_value %av is 10 : i64
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @keep_b root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %a = match.get_attribute "attr" of %root : !match.optional<!pdl.attribute>
    %av = match.is_not_null %a : !pdl.attribute
    match.has_attr_value %av is 20 : i64
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
// CHECK:         try {
// CHECK:           foreach %[[E:.*]] in %{{.*}} : !pdl.range<value> {
// CHECK-NEXT:        %[[T:.*]] = get_value_type of %[[E]]
// CHECK-NEXT:        has_type %[[T]], i32
// CHECK-NEXT:        success @rewriters::@r benefit(1)
// CHECK:         try {
// CHECK:           check_operand_count %{{.*}} is 5
// CHECK:           success @rewriters::@r0 benefit(2)
module {
  module @rewriters { module @r {} module @r0 {} }
  match.matcher @each_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    match.foreach %e in %vs : !pdl.range<value> {
      %t = match.get_value_type of %e : !pdl.type
      match.has_type %t, i32
      match.success @rewriters::@r benefit(1)
    }
  }
  match.matcher @each_b root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.check_operand_count %root is 5
    match.success @rewriters::@r0 benefit(2)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
module {
  module @rewriters {
    module @r {}
  }

  // CHECK: has_name %{{.*}}, "foo.op"
  // CHECK: %[[ATTR:.*]] = constant_attribute 10 : i64
  // CHECK: try {
  // CHECK: apply_native_constraint "c1"(%[[ATTR]] : !pdl.attribute)
  // CHECK: try {
  // CHECK: apply_native_constraint "c2"(%[[ATTR]] : !pdl.attribute)
  // CHECK-NOT: constant_attribute

  match.matcher @shared root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %attr = match.constant_attribute 10 : i64
    match.apply_native_constraint "c1"(%attr : !pdl.attribute)
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @shared_other root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %attr = match.constant_attribute 10 : i64
    match.apply_native_constraint "c2"(%attr : !pdl.attribute)
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
// CHECK-NOT: constant_attribute
// CHECK: try {
// CHECK: constant_attribute 10 : i64
module {
  module @rewriters {
    module @r {}
  }

  match.matcher @sunk root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %attr = match.constant_attribute 10 : i64
    match.apply_native_constraint "c1"(%attr : !pdl.attribute)
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @sunk_other root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.apply_native_constraint "c2"(%root : !pdl.operation)
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: match.matcher @dead
// CHECK-NOT: constant_
module {
  module @rewriters {
    module @r {}
  }

  match.matcher @dead root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    %attr = match.constant_attribute 10 : i64
    %type = match.constant_type i32
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined
// CHECK-NOT:     apply_native_constraint
// CHECK:         switch_op_name %arg0
// CHECK-NEXT:    case "foo.op" {
// CHECK-NEXT:      apply_native_constraint "guarded"(%arg0 : !pdl.operation)
// CHECK:         case "bar.op" {
// CHECK-NEXT:      apply_native_constraint "guarded"(%arg0 : !pdl.operation)
// CHECK:         case "baz.op" {
// CHECK-NEXT:      apply_native_constraint "guarded"(%arg0 : !pdl.operation)
module {
  module @rewriters {
    module @r {}
  }

  match.matcher @a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.apply_native_constraint "guarded"(%root : !pdl.operation)
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @b root(%root : !pdl.operation) {
    match.has_name %root, "bar.op"
    match.apply_native_constraint "guarded"(%root : !pdl.operation)
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @c root(%root : !pdl.operation) {
    match.has_name %root, "baz.op"
    match.apply_native_constraint "guarded"(%root : !pdl.operation)
    match.success @rewriters::@r benefit(1)
  }
}

// -----

// CHECK-LABEL: match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    switch_op_name %arg0
// CHECK-NEXT:    case "foo.op" {
// CHECK:         case "bar.op" {
// CHECK:         case "baz.op" {
// CHECK:         case "qux.op" {
module {
  module @rewriters { module @r {} }
  match.matcher @q_a root(%root : !pdl.operation) {
    %0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %1 = match.is_not_null %0 : !pdl.value
    match.check_operand_count %root is 2
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @q_b root(%root : !pdl.operation) {
    %0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %1 = match.is_not_null %0 : !pdl.value
    match.check_operand_count %root is 2
    match.has_name %root, "bar.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @q_c root(%root : !pdl.operation) {
    %0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %1 = match.is_not_null %0 : !pdl.value
    match.check_operand_count %root is 1
    match.has_name %root, "baz.op"
    match.success @rewriters::@r benefit(1)
  }
  match.matcher @q_d root(%root : !pdl.operation) {
    %0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %1 = match.is_not_null %0 : !pdl.value
    match.check_operand_count %root is 1
    match.has_name %root, "qux.op"
    match.success @rewriters::@r benefit(1)
  }
}
