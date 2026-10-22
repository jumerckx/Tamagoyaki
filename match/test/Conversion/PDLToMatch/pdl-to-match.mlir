// RUN: tamagoyaki-opt -split-input-file -convert-pdl-to-match \
// RUN:   %S/../PDLToPDLInterp/pdl-to-pdl-interp-matcher.mlir | FileCheck %s

// CHECK-LABEL: module @empty_module
// CHECK:         module @rewriters {
// CHECK-NOT:     match.matcher

// CHECK-LABEL: module @simple
// CHECK:       match.matcher root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK-NEXT:    has_name %[[ROOT]], "foo.op"
// CHECK-NEXT:    check_operand_count %[[ROOT]] is 0
// CHECK-NEXT:    check_result_count %[[ROOT]] is 0
// CHECK-NEXT:    success @rewriters::@pdl_generated_rewriter benefit(1) (%[[ROOT]] : !pdl.operation)

// CHECK-LABEL: module @attributes
// CHECK:         %[[A:.*]] = get_attribute "attr" of %{{.*}} : !match.optional<!pdl.attribute>
// CHECK-NEXT:    %[[AV:.*]] = is_not_null %[[A]] : !pdl.attribute
// CHECK-NEXT:    has_attr_value %[[AV]] is 10 : i64
// CHECK:         %[[A1:.*]] = get_attribute "attr1" of %{{.*}} : !match.optional<!pdl.attribute>
// CHECK-NEXT:    %[[AV1:.*]] = is_not_null %[[A1]]
// CHECK-NEXT:    %[[AT:.*]] = get_attribute_type of %[[AV1]]
// CHECK-NEXT:    has_type %[[AT]], i64

// CHECK-LABEL: module @constraints
// CHECK:         apply_native_constraint "multi_constraint"(%{{.*}}, %{{.*}}, %{{.*}} : !pdl.value, !pdl.value, !pdl.value)

// CHECK-LABEL: module @constraint_with_result
// CHECK:         %[[C:.*]] = apply_native_constraint "check_op_and_get_attr_constr"(%[[ROOT:.*]] : !pdl.operation) : !pdl.attribute
// CHECK-NEXT:    success @rewriters::@pdl_generated_rewriter benefit(1) (%[[ROOT]], %[[C]] : !pdl.operation, !pdl.attribute)

// CHECK-LABEL: module @constraint_with_unused_result
// CHECK:         %{{.*}} = apply_native_constraint "check_op_and_get_attr_constr"(%{{.*}} : !pdl.operation) : !pdl.attribute
// CHECK-NEXT:    success @rewriters::@pdl_generated_rewriter benefit(1) (%{{.*}} : !pdl.operation)

// CHECK-LABEL: module @constraint_with_result_multiple
// CHECK:         match.matcher root
// CHECK:           success @rewriters::@pdl_generated_rewriter benefit(1)
// CHECK:         match.matcher root
// CHECK:           success @rewriters::@pdl_generated_rewriter_0 benefit(1)

// CHECK-LABEL: module @negated_constraint
// CHECK:         apply_native_constraint "constraint"(%{{.*}} : !pdl.operation) is_negated = true

// CHECK-LABEL: module @inputs
// CHECK:         check_operand_count %{{.*}} is 2
// CHECK:         %[[O0:.*]] = get_operand 0 of %{{.*}} : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[V0:.*]] = is_not_null %[[O0]]
// CHECK:         %[[O1:.*]] = get_operand 1 of %{{.*}} : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[V1:.*]] = is_not_null %[[O1]]
// CHECK-NEXT:    equal %[[V1]], %[[V0]] : !pdl.value

// CHECK-LABEL: module @variadic_inputs
// CHECK:         check_operand_count %{{.*}} is at_least 2
// CHECK:         %{{.*}} = get_operand 0 of %{{.*}} : !match.optional<!pdl.value>
// CHECK:         %[[OS:.*]] = get_operands 1 of %{{.*}} : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[VS:.*]] = is_not_null %[[OS]] : !pdl.range<value>
// CHECK-NEXT:    %[[TS:.*]] = get_value_type of %[[VS]] : !pdl.range<type>
// CHECK-NEXT:    has_types %[[TS]], [i64]

// CHECK-LABEL: module @single_operand_range
// CHECK-NOT:     check_operand_count
// CHECK:         %[[OS:.*]] = get_operands of %{{.*}} : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[VS:.*]] = is_not_null %[[OS]]
// CHECK-NEXT:    %[[TS:.*]] = get_value_type of %[[VS]]
// CHECK-NEXT:    has_types %[[TS]], [i64]

// CHECK-LABEL: module @results
// CHECK:         check_result_count %{{.*}} is 2
// CHECK:         %[[R0:.*]] = get_result 0 of %{{.*}} : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[RV0:.*]] = is_not_null %[[R0]]
// CHECK-NEXT:    %[[T0:.*]] = get_value_type of %[[RV0]]
// CHECK-NEXT:    has_type %[[T0]], i32

// CHECK-LABEL: module @variadic_results
// CHECK:         check_result_count %{{.*}} is at_least 2
// CHECK:         %[[RS:.*]] = get_results 1 of %{{.*}} : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[RVS:.*]] = is_not_null %[[RS]]
// CHECK-NEXT:    %[[TS:.*]] = get_value_type of %[[RVS]]
// CHECK-NEXT:    has_types %[[TS]], [i64]
// CHECK:         equal %{{.*}}, %{{.*}} : !pdl.type

// CHECK-LABEL: module @single_result_range
// CHECK-NOT:     check_result_count
// CHECK:         %[[RS:.*]] = get_results of %{{.*}} : !match.optional<!pdl.range<value>>

// CHECK-LABEL: module @results_as_operands
// CHECK:         %[[O0:.*]] = get_operand 0 of %{{.*}} : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[V0:.*]] = is_not_null %[[O0]]
// CHECK-NEXT:    %[[D:.*]] = get_defining_op of %[[V0]] : !pdl.value -> !match.optional<!pdl.operation>
// CHECK-NEXT:    %[[DOP:.*]] = is_not_null %[[D]] : !pdl.operation
// CHECK-NEXT:    %[[DR:.*]] = get_result 0 of %[[DOP]] : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[DRV:.*]] = is_not_null %[[DR]]
// CHECK-NEXT:    equal %[[DRV]], %[[V0]] : !pdl.value
// CHECK:         equal %{{.*}}, %[[DOP]] : !pdl.operation

// CHECK-LABEL: module @single_result_range_as_operands
// CHECK:         %[[OS:.*]] = get_operands of %{{.*}} : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[VS:.*]] = is_not_null %[[OS]]
// CHECK-NEXT:    %[[D:.*]] = get_defining_op of %[[VS]] : !pdl.range<value> -> !match.optional<!pdl.operation>
// CHECK-NEXT:    %[[DOP:.*]] = is_not_null %[[D]]
// CHECK-NEXT:    %[[DRS:.*]] = get_results of %[[DOP]] : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[DRVS:.*]] = is_not_null %[[DRS]]
// CHECK-NEXT:    equal %[[DRVS]], %[[VS]] : !pdl.range<value>

// CHECK-LABEL: module @switch_single_result_type
// CHECK:         match.matcher root
// CHECK:           has_type %{{.*}}, i32
// CHECK:         match.matcher root
// CHECK:           has_type %{{.*}}, i64

// CHECK-LABEL: module @switch_result_types
// CHECK:         match.matcher root
// CHECK:           has_types %{{.*}}, [i32]
// CHECK:         match.matcher root
// CHECK:           has_types %{{.*}}, [i64, i32]

// CHECK-LABEL: module @switch_operand_count_at_least
// CHECK:         match.matcher root
// CHECK:           check_operand_count %{{.*}} is at_least 1
// CHECK:         match.matcher root
// CHECK:           check_operand_count %{{.*}} is at_least 2

// CHECK-LABEL: module @switch_result_count_at_least
// CHECK:         match.matcher root
// CHECK:           check_result_count %{{.*}} is at_least 1
// CHECK:         match.matcher root
// CHECK:           check_result_count %{{.*}} is at_least 2

// CHECK-LABEL: module @predicate_ordering
// CHECK:         match.matcher root
// CHECK:           %[[T:.*]] = get_value_type of %{{.*}} : !pdl.type
// CHECK-NEXT:      apply_native_constraint "typeConstraint"(%[[T]] : !pdl.type)
// CHECK:         match.matcher root
// CHECK-NOT:       apply_native_constraint

// CHECK-LABEL: module @multi_root
// CHECK:       match.matcher @rewrite_multi_root root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK:         %[[USERS:.*]] = get_users of %[[V:.*]]
// CHECK-NEXT:    foreach %[[EACH:.*]] in %[[USERS]] : !pdl.range<operation> {
// CHECK-NEXT:      %[[EO:.*]] = get_operand 0 of %[[EACH]] : !match.optional<!pdl.value>
// CHECK-NEXT:      %[[EOV:.*]] = is_not_null %[[EO]]
// CHECK-NEXT:      equal %[[EOV]], %[[V]] : !pdl.value
// CHECK:           success @rewriters::@rewrite_multi_root benefit(1) (%[[ROOT]], %[[EACH]] : !pdl.operation, !pdl.operation)

// CHECK-LABEL: module @overlapping_roots
// CHECK:       match.matcher @rewrite_overlapping_roots root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK-NOT:     get_users
// CHECK-NOT:     foreach
// CHECK:         success @rewriters::@rewrite_overlapping_roots benefit(1) (%[[ROOT]] : !pdl.operation)

// CHECK-LABEL: module @force_overlapped_root
// CHECK:       match.matcher @rewrite_forced_overlapped_root root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK:         %[[USERS:.*]] = get_users of %{{.*}}
// CHECK-NEXT:    foreach %[[EACH:.*]] in %[[USERS]]
// CHECK:         success @rewriters::@rewrite_forced_overlapped_root benefit(1) (%[[ROOT]], %[[EACH]] : !pdl.operation, !pdl.operation)

// CHECK-LABEL: module @variadic_results_all
// CHECK:         %[[EX:.*]] = extract 0 of %[[RVS:.*]] : !pdl.value
// CHECK-NEXT:    %[[USERS:.*]] = get_users of %[[EX]]
// CHECK-NEXT:    foreach %[[EACH:.*]] in %[[USERS]] : !pdl.range<operation> {
// CHECK:           equal %{{.*}}, %[[RVS]] : !pdl.range<value>

// CHECK-LABEL: module @variadic_results_at
// CHECK:         %[[EX:.*]] = extract 0 of %{{.*}} : !pdl.value
// CHECK-NEXT:    %[[USERS:.*]] = get_users of %[[EX]]
// CHECK-NEXT:    foreach %[[EACH:.*]] in %[[USERS]]

// CHECK-LABEL: module @attribute_literal
// CHECK:         %[[A:.*]] = constant_attribute 10 : i64
// CHECK-NEXT:    apply_native_constraint "constraint"(%[[A]] : !pdl.attribute)

// CHECK-LABEL: module @type_literal
// CHECK:         %[[T:.*]] = constant_type i32
// CHECK-NEXT:    %[[TS:.*]] = constant_types [i32, i64]
// CHECK-NEXT:    apply_native_constraint "constraint"(%[[T]], %[[TS]] : !pdl.type, !pdl.range<type>)

// CHECK-LABEL: module @common_connector
// CHECK:       match.matcher @common_connector root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK:         %[[USERS:.*]] = get_users of %[[V:.*]]
// CHECK-NEXT:    foreach %[[E1:.*]] in %[[USERS]] : !pdl.range<operation> {
// CHECK:           %[[USERS2:.*]] = get_users of %[[V]]
// CHECK-NEXT:      foreach %[[E2:.*]] in %[[USERS2]] : !pdl.range<operation> {
// CHECK:             success @rewriters::@common_connector benefit(1) (%[[E1]], %[[E2]], %[[ROOT]] : !pdl.operation, !pdl.operation, !pdl.operation)

// CHECK-LABEL: module @common_connector_range
// CHECK:       match.matcher @common_connector_range root(%[[ROOT:.*]]: !pdl.operation) {
// CHECK:         %[[EX:.*]] = extract 0 of %{{.*}} : !pdl.value
// CHECK-NEXT:    %[[USERS:.*]] = get_users of %[[EX]]
// CHECK-NEXT:    foreach %[[E1:.*]] in %[[USERS]]
// CHECK:         success @rewriters::@common_connector_range benefit(1) (%[[E1]], %{{.*}}, %[[ROOT]] : !pdl.operation, !pdl.operation, !pdl.operation)
