// RUN: tamagoyaki-opt -split-input-file -convert-pdl-to-match \
// RUN:   %S/../PDLToPDLInterp/pdl-to-pdl-interp-rewriter.mlir | FileCheck %s

// CHECK-LABEL: module @external
// CHECK:       module @rewriters
// CHECK:         match.rewriter @pdl_generated_rewriter(%[[ROOT:.*]]: !pdl.operation, %[[INPUT:.*]]: !pdl.value) {
// CHECK-NEXT:      apply_native_rewrite "rewriter"(%[[ROOT]], %[[INPUT]] : !pdl.operation, !pdl.value)
// CHECK-NEXT:    }
// CHECK:       success @rewriters::@pdl_generated_rewriter benefit(1) (%{{.*}}, %{{.*}} : !pdl.operation, !pdl.value)

// CHECK-LABEL: module @erase
// CHECK:         match.rewriter @pdl_generated_rewriter(%[[ROOT:.*]]: !pdl.operation) {
// CHECK-NEXT:      erase %[[ROOT]]
// CHECK-NEXT:    }

// CHECK-LABEL: module @operation_attributes
// CHECK:         match.rewriter @pdl_generated_rewriter(%[[ATTR:.*]]: !pdl.attribute, %[[ROOT:.*]]: !pdl.operation) {
// CHECK-NEXT:      %[[ATTR1:.*]] = constant_attribute true
// CHECK-NEXT:      create_operation "foo.op" {"attr" = %[[ATTR]], "attr1" = %[[ATTR1]]}
// CHECK-NEXT:      erase %[[ROOT]]

// CHECK-LABEL: module @operation_operands
// CHECK:         match.rewriter @pdl_generated_rewriter(%[[OPERAND:.*]]: !pdl.value, %[[ROOT:.*]]: !pdl.operation) {
// CHECK-NEXT:      %[[TYPE:.*]] = constant_type i32
// CHECK-NEXT:      %[[NEWOP:.*]] = create_operation "foo.op"(%[[OPERAND]] : !pdl.value) -> (%[[TYPE]] : !pdl.type)
// CHECK-NEXT:      %[[RESULT:.*]] = pdl.result 0 of %[[NEWOP]]
// CHECK-NEXT:      create_operation "foo.op2"(%[[RESULT]] : !pdl.value)

// CHECK-LABEL: module @operation_infer_types_from_replaceop
// CHECK:         match.rewriter @pdl_generated_rewriter(%[[ROOT:.*]]: !pdl.operation) {
// CHECK-NEXT:      %[[RESULTS:.*]] = pdl.results of %[[ROOT]]
// CHECK-NEXT:      %[[TYPES:.*]] = get_value_type of %[[RESULTS]] : !pdl.range<type>
// CHECK-NEXT:      %[[NEWOP:.*]] = create_operation "foo.op" -> (%[[TYPES]] : !pdl.range<type>)
// CHECK-NEXT:      %[[NEWRESULTS:.*]] = pdl.results of %[[NEWOP]]
// CHECK-NEXT:      replace %[[ROOT]] with (%[[NEWRESULTS]] : !pdl.range<value>)

// CHECK-LABEL: module @operation_infer_types_from_interface
// CHECK:         %[[CST:.*]] = create_operation "arith.constant" -> <inferred>
// CHECK-NEXT:    %[[CST_RES:.*]] = pdl.results of %[[CST]]
// CHECK-NEXT:    %[[CST_TYPE:.*]] = get_value_type of %[[CST_RES]] : !pdl.range<type>
// CHECK-NEXT:    create_operation "foo.op" -> (%[[CST_TYPE]] : !pdl.range<type>)
