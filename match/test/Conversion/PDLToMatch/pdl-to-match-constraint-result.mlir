// RUN: tamagoyaki-opt -split-input-file -convert-pdl-to-match \
// RUN:   %S/../PDLToPDLInterp/use-constraint-result.mlir | FileCheck %s

// CHECK:         %[[SHIFT:.*]] = get_attribute "shift" of %{{.*}} : !match.optional<!pdl.attribute>
// CHECK-NEXT:    %[[SHIFTV:.*]] = is_not_null %[[SHIFT]]
// CHECK:         %[[C0:.*]] = constant_attribute 0 : i32
// CHECK-NEXT:    %[[C1:.*]] = constant_attribute 1 : i32
// CHECK-NEXT:    %[[RES:.*]] = apply_native_constraint "return_attr_constraint"(%[[C0]], %[[C1]] : !pdl.attribute, !pdl.attribute) : !pdl.attribute
// CHECK-NEXT:    apply_native_constraint "use_attr_constraint"(%[[SHIFTV]], %[[RES]] : !pdl.attribute, !pdl.attribute)

// CHECK:         %[[ATTR:.*]] = get_attribute "attr" of %{{.*}} : !match.optional<!pdl.attribute>
// CHECK-NEXT:    %[[ATTRV:.*]] = is_not_null %[[ATTR]]
// CHECK:         %[[DOP:.*]] = is_not_null %{{.*}} : !pdl.operation
// CHECK:         %[[RES:.*]] = apply_native_constraint "return_attr_constraint"(%[[DOP]] : !pdl.operation) : !pdl.attribute
// CHECK-NEXT:    equal %[[RES]], %[[ATTRV]] : !pdl.attribute
// CHECK-NEXT:    success @rewriters::@pdl_generated_rewriter benefit(1) (%{{.*}}, %[[ATTRV]] : !pdl.operation, !pdl.attribute)

// CHECK:         %[[O0:.*]] = get_operand 0 of %{{.*}} : !match.optional<!pdl.value>
// CHECK-NEXT:    %[[V0:.*]] = is_not_null %[[O0]]
// CHECK-NEXT:    %[[C:.*]] = constant_attribute 10 : i64
// CHECK-NEXT:    %[[RES:.*]] = apply_native_constraint "return_value_constr"(%[[C]] : !pdl.attribute) : !pdl.value
// CHECK-NEXT:    equal %[[RES]], %[[V0]] : !pdl.value

// CHECK:         %[[T:.*]] = get_value_type of %{{.*}} : !pdl.type
// CHECK-NEXT:    %[[C:.*]] = constant_attribute 10 : i64
// CHECK-NEXT:    %[[RES:.*]] = apply_native_constraint "return_type_constr"(%[[C]] : !pdl.attribute) : !pdl.type
// CHECK-NEXT:    equal %[[RES]], %[[T]] : !pdl.type

// CHECK:         %[[RS:.*]] = get_results of %{{.*}} : !match.optional<!pdl.range<value>>
// CHECK-NEXT:    %[[RVS:.*]] = is_not_null %[[RS]]
// CHECK-NEXT:    %[[TS:.*]] = get_value_type of %[[RVS]] : !pdl.range<type>
// CHECK-NEXT:    %[[C:.*]] = constant_attribute 10 : i64
// CHECK-NEXT:    %[[RES:.*]] = apply_native_constraint "return_type_range_constr"(%[[C]] : !pdl.attribute) : !pdl.range<type>
// CHECK-NEXT:    equal %[[RES]], %[[TS]] : !pdl.range<type>
