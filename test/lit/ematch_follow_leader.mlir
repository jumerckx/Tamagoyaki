// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=1" | FileCheck %s

module @ir {
  func.func @nested(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
      %a = arith.addi %arg0, %arg0 : i32
      %c_a = equivalence.class %a : i32
      %3 = equivalence.graph -> (i32) {
        %b = arith.subi %arg0, %arg0 : i32
        %c_b = equivalence.class %b leader %c_a : i32
        // CHECK:      %[[MULI:.*]] = arith.muli
        %d = math.absi %c_b : i32
        // CHECK-NEXT: %[[ABSI:.*]] = math.absi
        // CHECK-NEXT: %[[EC:.*]] = equivalence.class %[[ABSI]], %[[MULI]] : i32
        equivalence.yield %d : i32
      }
      equivalence.yield %c_a : i32
    }
    return %0 : i32
  }
}

module @patterns {
  // absi(addi x, x) --> muli x, x
  
  //pdl.pattern @absi_addi_xx : benefit(1) {
  //  %type = pdl.type : i32
  //  %x = pdl.operand

  //  %add_op = pdl.operation "arith.addi" (%x, %x : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  //  %add = pdl.result 0 of %add_op

  //  %root = pdl.operation "math.absi" (%add : !pdl.value) -> (%type : !pdl.type)

  //  pdl.rewrite %root {
  //    %newop = pdl.operation "arith.muli" (%x, %x : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  //    %res = pdl.result 0 of %newop
  //    pdl.replace %root with (%res : !pdl.value)
  //  }
  //}

  pdl_interp.func @matcher(%0: !pdl.operation) {
    pdl_interp.check_operation_name of %0 is "math.absi" -> ^bb0, ^bb1
  ^bb1:
    pdl_interp.finalize
  ^bb0:
    pdl_interp.check_operand_count of %0 is 1 -> ^bb2, ^bb1
  ^bb2:
    pdl_interp.check_result_count of %0 is 1 -> ^bb3, ^bb1
  ^bb3:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb4, ^bb1
  ^bb4:
    %2 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb5, ^bb1
  ^bb5:
    %3 = ematch.get_class_result %2
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb6, ^bb1
  ^bb6:
    %4 = ematch.get_class_vals %1
    pdl_interp.foreach %5 : !pdl.value in %4 {
      %6 = pdl_interp.get_defining_op of %5 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %6 : !pdl.operation -> ^bb7, ^bb8
    ^bb8:
      pdl_interp.continue
    ^bb7:
      pdl_interp.check_operation_name of %6 is "arith.addi" -> ^bb9, ^bb8
    ^bb9:
      pdl_interp.check_operand_count of %6 is 2 -> ^bb10, ^bb8
    ^bb10:
      pdl_interp.check_result_count of %6 is 1 -> ^bb11, ^bb8
    ^bb11:
      %7 = pdl_interp.get_operand 0 of %6
      pdl_interp.is_not_null %7 : !pdl.value -> ^bb12, ^bb8
    ^bb12:
      %8 = pdl_interp.get_operand 1 of %6
      pdl_interp.are_equal %7, %8 : !pdl.value -> ^bb13, ^bb8
    ^bb13:
      %9 = pdl_interp.get_result 0 of %6
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb14, ^bb8
    ^bb14:
      %10 = ematch.get_class_result %9
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb15, ^bb8
    ^bb15:
      pdl_interp.are_equal %10, %1 : !pdl.value -> ^bb16, ^bb8
    ^bb16:
      %11 = pdl_interp.get_value_type of %10 : !pdl.type
      %12 = pdl_interp.get_value_type of %3 : !pdl.type
      pdl_interp.are_equal %11, %12 : !pdl.type -> ^bb17, ^bb8
    ^bb17:
      pdl_interp.check_type %11 is i32 -> ^bb18, ^bb8
    ^bb18:
      %13 = ematch.get_class_representative %7
      pdl_interp.record_match @rewriters::@absi_addi_xx(%13, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("math.absi") -> ^bb8
    } -> ^bb1
  }
  builtin.module @rewriters {
    pdl_interp.func @absi_addi_xx(%0: !pdl.value, %1: !pdl.operation) {
      %2 = ematch.get_class_result %0
      %3 = pdl_interp.create_type i32
      %4 = pdl_interp.create_operation "arith.muli"(%2, %2 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %5 = ematch.dedup %4
      %6 = pdl_interp.get_result 0 of %5
      %7 = ematch.get_class_result %6
      %8 = pdl_interp.create_range %7 : !pdl.value
      ematch.union %1 : !pdl.operation, %8 : !pdl.range<value>
      pdl_interp.finalize
    }
  }


}
