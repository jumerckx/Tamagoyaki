// RUN: tamagoyaki-opt -ematch-saturate %s -allow-unregistered-dialect | FileCheck %s
// RUN: tamagoyaki-opt -ematch-convert-pdl-to-pdl-interp %s -allow-unregistered-dialect \
// RUN:   | FileCheck %s --check-prefix=LOWER

// Same as ematch_mul_to_shift.mlir, but with the pattern written in pdl. It is
// lowered to e-matching pdl_interp through the match dialect.

// LOWER-LABEL: module @patterns
// LOWER:         pdl_interp.func @matcher(%[[ROOT:.*]]: !pdl.operation)
// LOWER:           pdl_interp.check_operation_name of %[[ROOT]] is "arith.muli"
// LOWER:           %[[X:.*]] = pdl_interp.get_operand 0 of %[[ROOT]]
// LOWER:           %[[OPERAND:.*]] = pdl_interp.get_operand 1 of %[[ROOT]]
// LOWER:           %[[MEMBERS:.*]] = pdl_interp.apply_rewrite "get_class_vals"(%[[OPERAND]] : !pdl.value) : !pdl.range<value>
// LOWER:           %[[REP:.*]] = pdl_interp.apply_rewrite "get_class_representative"(%[[X]] : !pdl.value) : !pdl.value
// The constant may be any e-node in the e-class of the second operand.
// LOWER:           pdl_interp.foreach %[[MEMBER:.*]] : !pdl.value in %[[MEMBERS]] {
// LOWER-NEXT:        %[[DEF:.*]] = pdl_interp.get_defining_op of %[[MEMBER]] : !pdl.value
// LOWER:             pdl_interp.check_operation_name of %[[DEF]] is "arith.constant"
// LOWER:             %[[RES:.*]] = pdl_interp.get_result 0 of %[[DEF]]
// LOWER:             %[[CLASS:.*]] = pdl_interp.apply_rewrite "get_class_result"(%[[RES]] : !pdl.value) : !pdl.value
// LOWER:             pdl_interp.check_attribute %{{.*}} is 2 : i32
// LOWER:             pdl_interp.apply_constraint "are_equivalent"(%[[CLASS]], %[[OPERAND]] : !pdl.value, !pdl.value)
// LOWER:             pdl_interp.record_match @rewriters::@mul_to_shift(%[[REP]], %[[ROOT]] : !pdl.value, !pdl.operation)
// LOWER:         pdl_interp.func @mul_to_shift(%[[X:.*]]: !pdl.value, %[[MUL:.*]]: !pdl.operation)
// LOWER-NEXT:      %[[XC:.*]] = pdl_interp.apply_rewrite "get_class_result"(%[[X]] : !pdl.value) : !pdl.value
// LOWER:           %[[ONE:.*]] = pdl_interp.create_operation "arith.constant"
// LOWER-NEXT:      %[[ONED:.*]] = pdl_interp.apply_rewrite "dedup"(%[[ONE]] : !pdl.operation) : !pdl.operation
// LOWER-NEXT:      %[[ONER:.*]] = pdl_interp.get_result 0 of %[[ONED]]
// LOWER-NEXT:      %[[ONEC:.*]] = pdl_interp.apply_rewrite "get_class_result"(%[[ONER]] : !pdl.value) : !pdl.value
// LOWER-NEXT:      %[[SHL:.*]] = pdl_interp.create_operation "arith.shli"(%[[XC]], %[[ONEC]] : !pdl.value, !pdl.value)
// LOWER-NEXT:      %[[SHLD:.*]] = pdl_interp.apply_rewrite "dedup"(%[[SHL]] : !pdl.operation) : !pdl.operation
// LOWER-NEXT:      %[[ALL:.*]] = pdl_interp.get_results of %[[SHLD]] : !pdl.range<value>
// LOWER-NEXT:      %[[ALLC:.*]] = pdl_interp.apply_rewrite "get_class_results"(%[[ALL]] : !pdl.range<value>) : !pdl.range<value>
// LOWER-NEXT:      pdl_interp.apply_rewrite "union"(%[[MUL]], %[[ALLC]] : !pdl.operation, !pdl.range<value>)
// LOWER-NEXT:      pdl_interp.finalize
module @patterns {
  pdl.pattern @mul_to_shift : benefit(1) {
    %type = pdl.type : i32
    %x = pdl.operand : %type
    %two_attr = pdl.attribute = 2 : i32
    %two_op = pdl.operation "arith.constant" {"value" = %two_attr} -> (%type : !pdl.type)
    %two = pdl.result 0 of %two_op
    %mul = pdl.operation "arith.muli"(%x, %two : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    pdl.rewrite %mul {
      %one_attr = pdl.attribute = 1 : i32
      %one_op = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
      %one = pdl.result 0 of %one_op
      %shl = pdl.operation "arith.shli"(%x, %one : !pdl.value, !pdl.value) -> (%type : !pdl.type)
      pdl.replace %mul with %shl
    }
  }
}

module @ir {
  // CHECK:      func.func @graph_with_eqs(%arg0: i32) -> i32 {
  // CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
  // CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
  // CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
  // CHECK-NEXT:     %2 = equivalence.class %c2_i32 : i32
  // CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
  // CHECK-NEXT:     %3 = arith.shli %1, %c1_i32 : i32
  // CHECK-NEXT:     %4 = arith.muli %1, %2 : i32
  // CHECK-NEXT:     %5 = "test.op"() : () -> i32
  // CHECK-NEXT:     %6 = equivalence.class %5, %4, %3 : i32
  // CHECK-NEXT:     equivalence.yield %6 : i32
  // CHECK-NEXT:   }
  // CHECK-NEXT:   return %0 : i32
  // CHECK-NEXT: }
  func.func @graph_with_eqs(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
      %1 = equivalence.class %arg0 : i32
      %c2_i32 = arith.constant 2 : i32
      %2 = equivalence.class %c2_i32 : i32
      %3 = arith.muli %1, %2 : i32
      %someotherval = "test.op"() : () -> (i32)
      %4 = equivalence.class %someotherval, %3 : i32
      equivalence.yield %4 : i32
    }
    return %0 : i32
  }

  // CHECK:      func.func @graph_without_eqs(%arg0: i32) -> i32 {
  // CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
  // CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
  // CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
  // CHECK-NEXT:     %1 = arith.shli %arg0, %c1_i32 : i32
  // CHECK-NEXT:     %2 = arith.muli %arg0, %c2_i32 : i32
  // CHECK-NEXT:     %3 = equivalence.class %2, %1 : i32
  // CHECK-NEXT:     equivalence.yield %3 : i32
  // CHECK-NEXT:   }
  // CHECK-NEXT:   return %0 : i32
  // CHECK-NEXT: }
  func.func @graph_without_eqs(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
      %c2_i32 = arith.constant 2 : i32
      %3 = arith.muli %arg0, %c2_i32 : i32
      equivalence.yield %3 : i32
    }
    return %0 : i32
  }
}
