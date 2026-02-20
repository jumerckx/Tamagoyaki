builtin.module @patterns {
  pdl_interp.func @matcher(%0 : !pdl.operation) {
    pdl_interp.check_operation_name of %0 is "comb.shl" -> ^bb0, ^bb1
  ^bb1:
    pdl_interp.finalize
  ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb2, ^bb1
  ^bb2:
    pdl_interp.check_result_count of %0 is 1 -> ^bb3, ^bb1
  ^bb3:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb4, ^bb1
  ^bb4:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb5, ^bb1
  ^bb5:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb6, ^bb1
  ^bb6:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb7, ^bb1
  ^bb7:
    %5 = ematch.get_class_vals %1
    pdl_interp.foreach %6 : !pdl.value in %5 {
      %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %7 : !pdl.operation -> ^bb8, ^bb9
    ^bb9:
      pdl_interp.continue
    ^bb8:
      pdl_interp.check_operation_name of %7 is "comb.mul" -> ^bb10, ^bb9
    ^bb10:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb11, ^bb9
    ^bb11:
      pdl_interp.check_result_count of %7 is 1 -> ^bb12, ^bb9
    ^bb12:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb13, ^bb9
    ^bb13:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb14, ^bb9
    ^bb14:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb15, ^bb9
    ^bb15:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb16, ^bb9
    ^bb16:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb17, ^bb9
    ^bb17:
      %12 = pdl_interp.get_value_type of %8 : !pdl.type
      %13 = pdl_interp.get_value_type of %9 : !pdl.type
      pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb18, ^bb9
    ^bb18:
      %14 = pdl_interp.get_value_type of %11 : !pdl.type
      pdl_interp.are_equal %12, %14 : !pdl.type -> ^bb19, ^bb9
    ^bb19:
      %15 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %12, %15 : !pdl.type -> ^bb20, ^bb9
    ^bb20:
      %16 = ematch.get_class_representative %8
      %17 = ematch.get_class_representative %2
      %18 = ematch.get_class_representative %9
      pdl_interp.record_match @rewriters::@MulShlToShlMul(%16, %17, %12, %18, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb9
    } -> ^bb1
  }
  builtin.module @rewriters {
    pdl_interp.func @MulShlToShlMul(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.shl"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.mul"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}

module @ir {
func.func @ShiftedFma(%a : i8, %b : i8, %s : i3, %c : i16) -> i17 {
  %false = hw.constant false
  %c0_i14 = hw.constant 0 : i14
  %c0_i9 = hw.constant 0 : i9
  %0 = comb.concat %c0_i9, %a : i9, i8
  %1 = comb.concat %c0_i9, %b : i9, i8
  %2 = comb.mul %0, %1 : i17
  %3 = comb.concat %c0_i14, %s : i14, i3
  %4 = comb.shl %2, %3 : i17
  %5 = comb.concat %false, %c : i1, i16
  %6 = comb.add %4, %5 : i17
  return %6 : i17
}
}
