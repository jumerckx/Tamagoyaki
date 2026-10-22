// RUN: tamagoyaki-opt -split-input-file -convert-pdl-to-match \
// RUN:   -match-combine-matchers -convert-match-to-pdl-interp %s | FileCheck %s

// CHECK-LABEL: module @empty_module
// CHECK:         pdl_interp.func @matcher
// CHECK:           pdl_interp.finalize
module @empty_module {
}

// -----

// CHECK-LABEL: module @simple
// CHECK:         pdl_interp.check_operation_name of %arg0 is "foo.op"
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%arg0 : !pdl.operation) : benefit(1), loc([%arg0]), root("foo.op")
module @simple {
  pdl.pattern : benefit(1) {
    %root = operation "foo.op"
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @attributes
// CHECK:         pdl_interp.get_attribute "attr" of %arg0
// CHECK:         pdl_interp.check_attribute %{{.*}} is 10 : i64
// CHECK:         pdl_interp.get_attribute_type of
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter
module @attributes {
  pdl.pattern : benefit(1) {
    %type = type : i64
    %attr = attribute = 10 : i64
    %attr1 = attribute : %type
    %root = operation {"attr" = %attr, "attr1" = %attr1}
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @constraints
// CHECK:         pdl_interp.apply_constraint "multi_constraint"(%{{.*}}, %{{.*}}, %{{.*}} : !pdl.value, !pdl.value, !pdl.value)
// CHECK:         pdl_interp.record_match
module @constraints {
  pdl.pattern : benefit(1) {
    %input0 = operand
    %input1 = operand
    %root = operation(%input0, %input1 : !pdl.value, !pdl.value)
    %result0 = result 0 of %root

    pdl.apply_native_constraint "multi_constraint"(%input0, %input1, %result0 : !pdl.value, !pdl.value, !pdl.value)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @constraint_with_result
// CHECK:         %[[C:.*]] = pdl_interp.apply_constraint "check_op_and_get_attr_constr"(%arg0 : !pdl.operation) : !pdl.attribute
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%arg0, %[[C]] : !pdl.operation, !pdl.attribute)
module @constraint_with_result {
  pdl.pattern : benefit(1) {
    %root = operation
    %attr = pdl.apply_native_constraint "check_op_and_get_attr_constr"(%root : !pdl.operation) : !pdl.attribute
    rewrite %root with "rewriter"(%attr : !pdl.attribute)
  }
}

// -----

// CHECK-LABEL: module @constraint_with_unused_result
// CHECK:         pdl_interp.apply_constraint "check_op_and_get_attr_constr"
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%arg0 : !pdl.operation)
module @constraint_with_unused_result {
  pdl.pattern : benefit(1) {
    %root = operation
    %attr = pdl.apply_native_constraint "check_op_and_get_attr_constr"(%root : !pdl.operation) : !pdl.attribute
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @constraint_with_result_multiple
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter_0
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter
module @constraint_with_result_multiple {
  pdl.pattern : benefit(1) {
    %root = operation
    %attr = pdl.apply_native_constraint "check_op_and_get_attr_constr"(%root : !pdl.operation) : !pdl.attribute
    rewrite %root with "rewriter"(%attr : !pdl.attribute)
  }
  pdl.pattern : benefit(1) {
    %root = operation
    %attr = pdl.apply_native_constraint "check_op_and_get_attr_constr"(%root : !pdl.operation) : !pdl.attribute
    rewrite %root with "rewriter"(%attr : !pdl.attribute)
  }
}

// -----

// CHECK-LABEL: module @negated_constraint
// CHECK:         pdl_interp.apply_constraint "constraint"(%arg0 : !pdl.operation) {isNegated = true}
module @negated_constraint {
  pdl.pattern : benefit(1) {
    %root = operation
    pdl.apply_native_constraint "constraint"(%root : !pdl.operation) {isNegated = true}
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @inputs
// CHECK:         pdl_interp.check_operand_count of %arg0 is 2
// CHECK:         pdl_interp.are_equal
// CHECK:         pdl_interp.record_match
module @inputs {
  pdl.pattern : benefit(1) {
    %type = type : i64
    %input = operand : %type
    %root = operation(%input, %input : !pdl.value, !pdl.value)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @variadic_inputs
// CHECK:         pdl_interp.check_operand_count of %arg0 is at_least 2
// CHECK:         pdl_interp.check_types
// CHECK:         pdl_interp.record_match
module @variadic_inputs {
  pdl.pattern : benefit(1) {
    %types = types : [i64]
    %inputs = operands : %types
    %input = operand
    %root = operation(%input, %inputs, %input : !pdl.value, !pdl.range<value>, !pdl.value)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @single_operand_range
// CHECK:         pdl_interp.get_operands of %arg0 : !pdl.range<value>
// CHECK:         pdl_interp.record_match
module @single_operand_range {
  pdl.pattern : benefit(1) {
    %types = types : [i64]
    %operands = operands : %types
    %root = operation(%operands : !pdl.range<value>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @results
// CHECK:         pdl_interp.check_result_count of %arg0 is 2
// CHECK:         pdl_interp.check_type
// CHECK:         pdl_interp.record_match
module @results {
  pdl.pattern : benefit(1) {
    %type1 = type : i32
    %type2 = type
    %root = operation -> (%type1, %type2 : !pdl.type, !pdl.type)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @variadic_results
// CHECK:         pdl_interp.check_result_count of %arg0 is at_least 2
// CHECK:         pdl_interp.record_match
module @variadic_results {
  pdl.pattern : benefit(1) {
    %types = types : [i64]
    %type = type
    %root = operation -> (%type, %types, %type : !pdl.type, !pdl.range<type>, !pdl.type)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @single_result_range
// CHECK:         pdl_interp.get_results of %arg0 : !pdl.range<value>
// CHECK:         pdl_interp.record_match
module @single_result_range {
  pdl.pattern : benefit(1) {
    %types = types : [i64]
    %root = operation -> (%types : !pdl.range<type>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @results_as_operands
// CHECK:         pdl_interp.get_defining_op of
// CHECK:         pdl_interp.are_equal
// CHECK:         pdl_interp.record_match
module @results_as_operands {
  pdl.pattern : benefit(1) {
    %type1 = type : i32
    %type2 = type
    %inputOp = operation -> (%type1, %type2 : !pdl.type, !pdl.type)
    %result1 = result 0 of %inputOp
    %result2 = result 1 of %inputOp

    %root = operation(%result1, %result2 : !pdl.value, !pdl.value)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @single_result_range_as_operands
// CHECK:         pdl_interp.get_defining_op of
// CHECK:         pdl_interp.record_match
module @single_result_range_as_operands {
  pdl.pattern : benefit(1) {
    %types = types
    %inputOp = operation -> (%types : !pdl.range<type>)
    %results = results of %inputOp

    %root = operation(%results : !pdl.range<value>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @switch_single_result_type
// CHECK:         pdl_interp.switch_type %{{.*}} to [i32, i64]
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter_0
module @switch_single_result_type {
  pdl.pattern : benefit(1) {
    %type = type : i32
    %root = operation -> (%type : !pdl.type)
    rewrite %root with "rewriter"
  }
  pdl.pattern : benefit(1) {
    %type = type : i64
    %root = operation -> (%type : !pdl.type)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @switch_result_types
// CHECK:         pdl_interp.check_types
// CHECK:         pdl_interp.record_match
module @switch_result_types {
  pdl.pattern : benefit(1) {
    %types = types : [i32]
    %root = operation -> (%types : !pdl.range<type>)
    rewrite %root with "rewriter"
  }
  pdl.pattern : benefit(1) {
    %types = types : [i64, i32]
    %root = operation -> (%types : !pdl.range<type>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @switch_operand_count_at_least
// CHECK:         pdl_interp.check_operand_count of %arg0 is at_least
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter
// CHECK:         pdl_interp.record_match @rewriters::@pdl_generated_rewriter_0
module @switch_operand_count_at_least {
  pdl.pattern : benefit(1) {
    %operand = operand
    %operands = operands
    %root = operation(%operand, %operands : !pdl.value, !pdl.range<value>)
    rewrite %root with "rewriter"
  }
  pdl.pattern : benefit(1) {
    %operand = operand
    %operand2 = operand
    %operands = operands
    %root = operation(%operand, %operand2, %operands : !pdl.value, !pdl.value, !pdl.range<value>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @switch_result_count_at_least
// CHECK:         pdl_interp.check_result_count of %arg0 is at_least
// CHECK:         pdl_interp.record_match
// CHECK:         pdl_interp.record_match
module @switch_result_count_at_least {
  pdl.pattern : benefit(1) {
    %type = type
    %types = types
    %root = operation -> (%type, %types : !pdl.type, !pdl.range<type>)
    rewrite %root with "rewriter"
  }
  pdl.pattern : benefit(1) {
    %type = type
    %type2 = type
    %types = types
    %root = operation -> (%type, %type2, %types : !pdl.type, !pdl.type, !pdl.range<type>)
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @predicate_ordering
// CHECK:         pdl_interp.apply_constraint "typeConstraint"
// CHECK:         pdl_interp.record_match
module @predicate_ordering {
  pdl.pattern : benefit(1) {
    %resultType = type
    pdl.apply_native_constraint "typeConstraint"(%resultType : !pdl.type)
    %root = operation -> (%resultType : !pdl.type)
    rewrite %root with "rewriter"
  }

  pdl.pattern : benefit(1) {
    %resultType = type
    %apply = operation -> (%resultType : !pdl.type)
    rewrite %apply with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @multi_root
// CHECK:         pdl_interp.get_users of
// CHECK:         pdl_interp.foreach %[[E:.*]] : !pdl.operation in
// CHECK:         pdl_interp.record_match @rewriters::@rewrite_multi_root(%arg0, %[[E]] : !pdl.operation, !pdl.operation)
module @multi_root {
  pdl.pattern @rewrite_multi_root : benefit(1) {
    %input1 = operand
    %input2 = operand
    %type = type
    %op1 = operation(%input1 : !pdl.value) -> (%type : !pdl.type)
    %val1 = result 0 of %op1
    %root1 = operation(%val1 : !pdl.value)
    %op2 = operation(%input2 : !pdl.value) -> (%type : !pdl.type)
    %val2 = result 0 of %op2
    %root2 = operation(%val1, %val2 : !pdl.value, !pdl.value)
    rewrite %root1 with "rewriter"(%root2 : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @overlapping_roots
// CHECK-NOT:     pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@rewrite_overlapping_roots
module @overlapping_roots {
  pdl.pattern @rewrite_overlapping_roots : benefit(1) {
    %input1 = operand
    %input2 = operand
    %type = type
    %op = operation(%input1, %input2 : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %val = result 0 of %op
    %root = operation(%val : !pdl.value)
    rewrite with "rewriter"(%root : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @force_overlapped_root
// CHECK:         pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@rewrite_forced_overlapped_root
module @force_overlapped_root {
  pdl.pattern @rewrite_forced_overlapped_root : benefit(1) {
    %input1 = operand
    %input2 = operand
    %type = type
    %root = operation(%input1, %input2 : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %val = result 0 of %root
    %op = operation(%val : !pdl.value)
    rewrite %root with "rewriter"(%op : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @variadic_results_all
// CHECK:         pdl_interp.extract 0 of
// CHECK:         pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@variadic_results_all
module @variadic_results_all {
  pdl.pattern @variadic_results_all : benefit(1) {
    %types = types
    %root = operation -> (%types : !pdl.range<type>)
    %vals = results of %root
    %op = operation(%vals : !pdl.range<value>)
    rewrite %root with "rewriter"(%op : !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @variadic_results_at
// CHECK:         pdl_interp.extract 0 of
// CHECK:         pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@variadic_results_at
module @variadic_results_at {
  pdl.pattern @variadic_results_at : benefit(1) {
    %type = type
    %types = types
    %val = operand
    %op = operation -> (%types, %type : !pdl.range<type>, !pdl.type)
    %vals = results 0 of %op -> !pdl.range<value>
    %root1 = operation(%vals, %val : !pdl.range<value>, !pdl.value)
    %root2 = operation(%val, %vals : !pdl.value, !pdl.range<value>)
    rewrite with "rewriter"(%root1, %root2 : !pdl.operation, !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @attribute_literal
// CHECK:         %[[A:.*]] = pdl_interp.create_attribute 10 : i64
// CHECK:         pdl_interp.apply_constraint "constraint"(%[[A]] : !pdl.attribute)
module @attribute_literal {
  pdl.pattern : benefit(1) {
    %attr = attribute = 10
    pdl.apply_native_constraint "constraint"(%attr: !pdl.attribute)

    %root = operation
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @type_literal
// CHECK:         %[[T:.*]] = pdl_interp.create_type i32
// CHECK:         %[[TS:.*]] = pdl_interp.create_types [i32, i64]
// CHECK:         pdl_interp.apply_constraint "constraint"(%[[T]], %[[TS]] : !pdl.type, !pdl.range<type>)
module @type_literal {
  pdl.pattern : benefit(1) {
    %type = type : i32
    %types = types : [i32, i64]
    pdl.apply_native_constraint "constraint"(%type, %types: !pdl.type, !pdl.range<type>)

    %root = operation
    rewrite %root with "rewriter"
  }
}

// -----

// CHECK-LABEL: module @common_connector
// CHECK:         pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@common_connector
module @common_connector {
  pdl.pattern @common_connector : benefit(1) {
      %type = type
      %op = operation -> (%type, %type : !pdl.type, !pdl.type)
      %val0 = result 0 of %op
      %val1 = result 1 of %op
      %rootA = operation (%val0 : !pdl.value)
      %rootB = operation (%val0 : !pdl.value)
      %inter = operation (%val1 : !pdl.value) -> (%type : !pdl.type)
      %val2 = result 0 of %inter
      %rootC = operation (%val2 : !pdl.value)
      rewrite with "rewriter"(%rootA, %rootB, %rootC : !pdl.operation, !pdl.operation, !pdl.operation)
  }
}

// -----

// CHECK-LABEL: module @common_connector_range
// CHECK:         pdl_interp.extract 0 of
// CHECK:         pdl_interp.foreach
// CHECK:         pdl_interp.record_match @rewriters::@common_connector_range
module @common_connector_range {
  pdl.pattern @common_connector_range : benefit(1) {
    %types = types
    %op = operation -> (%types, %types : !pdl.range<type>, !pdl.range<type>)
    %vals0 = results 0 of %op -> !pdl.range<value>
    %vals1 = results 1 of %op -> !pdl.range<value>
    %rootA = operation (%vals0 : !pdl.range<value>)
    %rootB = operation (%vals0 : !pdl.range<value>)
    %inter = operation (%vals1 : !pdl.range<value>) -> (%types : !pdl.range<type>)
    %vals2 = results of %inter
    %rootC = operation (%vals2 : !pdl.range<value>)
    rewrite with "rewriter"(%rootA, %rootB, %rootC : !pdl.operation, !pdl.operation, !pdl.operation)
  }
}
