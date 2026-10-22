// RUN: tamagoyaki-opt -ematch-convert-pdl-to-pdl-interp %s | FileCheck %s

// The are_equivalent checks are placed by the combined matcher like any other
// predicate, i.e. right after their operands, instead of after everything that
// preceded them in their pattern. Here, the check on the second operand of the
// root comes before the loop over the e-class of `neg(a)`'s operand, which the
// pattern happens to navigate first.

// CHECK-LABEL: pdl_interp.func @matcher
// CHECK-SAME:    (%[[ROOT:.*]]: !pdl.operation)
// CHECK:         %[[OP1:.*]] = pdl_interp.get_operand 1 of %[[ROOT]]
// CHECK:         %[[OP1_CLASS:.*]] = pdl_interp.apply_rewrite "get_class_vals"(%[[OP1]] : !pdl.value)
// CHECK-NEXT:    %[[OP0_CLASS:.*]] = pdl_interp.apply_rewrite "get_class_vals"
// CHECK-NEXT:    pdl_interp.foreach %{{.*}} : !pdl.value in %[[OP0_CLASS]] {
// CHECK:           pdl_interp.foreach %[[M1:.*]] : !pdl.value in %[[OP1_CLASS]] {
// CHECK-NEXT:        %[[DEF1:.*]] = pdl_interp.get_defining_op of %[[M1]]
// CHECK:             %[[RES1:.*]] = pdl_interp.get_result 0 of %[[DEF1]]
// CHECK:             %[[CLASS1:.*]] = pdl_interp.apply_rewrite "get_class_result"(%[[RES1]] : !pdl.value)
// CHECK-NEXT:        pdl_interp.apply_constraint "are_equivalent"(%[[CLASS1]], %[[OP1]] : !pdl.value, !pdl.value)
// CHECK-NOT:         pdl_interp.foreach
// CHECK:             pdl_interp.foreach
// CHECK:               pdl_interp.record_match @rewriters::@add_neg_neg_neg
pdl.pattern @add_neg_neg_neg : benefit(1) {
  %type = pdl.type
  %a = pdl.operand
  %b = pdl.operand
  %neg_a_op = pdl.operation "arith.negf"(%a : !pdl.value) -> (%type : !pdl.type)
  %neg_a = pdl.result 0 of %neg_a_op
  %neg_neg_a_op = pdl.operation "arith.negf"(%neg_a : !pdl.value) -> (%type : !pdl.type)
  %neg_neg_a = pdl.result 0 of %neg_neg_a_op
  %neg_b_op = pdl.operation "arith.negf"(%b : !pdl.value) -> (%type : !pdl.type)
  %neg_b = pdl.result 0 of %neg_b_op
  %add = pdl.operation "arith.addf"(%neg_neg_a, %neg_b : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  pdl.rewrite %add {
    %sub = pdl.operation "arith.subf"(%a, %b : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    pdl.replace %add with %sub
  }
}
