builtin.module @patterns {
  pdl_interp.func @matcher(%0 : !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["comb.shl", "comb.mul"](^bb0, ^bb1) -> ^bb2
  ^bb2:
    pdl_interp.finalize
  ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb3, ^bb2
  ^bb3:
    pdl_interp.check_result_count of %0 is 1 -> ^bb4, ^bb2
  ^bb4:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb5, ^bb2
  ^bb5:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb6, ^bb2
  ^bb6:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb7, ^bb2
  ^bb7:
    %4 = pdl_interp.get_defining_op of %1 : !pdl.value {position = "root.operand[0].defining_op"}
    pdl_interp.is_not_null %4 : !pdl.operation -> ^bb8, ^bb2
  ^bb8:
    pdl_interp.check_operation_name of %4 is "comb.mul" -> ^bb9, ^bb2
  ^bb9:
    pdl_interp.check_operand_count of %4 is 2 -> ^bb10, ^bb2
  ^bb10:
    pdl_interp.check_result_count of %4 is 1 -> ^bb11, ^bb2
  ^bb11:
    %5 = pdl_interp.get_operand 0 of %4
    pdl_interp.is_not_null %5 : !pdl.value -> ^bb12, ^bb2
  ^bb12:
    %6 = pdl_interp.get_operand 1 of %4
    pdl_interp.is_not_null %6 : !pdl.value -> ^bb13, ^bb2
  ^bb13:
    %7 = pdl_interp.get_result 0 of %4
    pdl_interp.is_not_null %7 : !pdl.value -> ^bb14, ^bb2
  ^bb14:
    pdl_interp.are_equal %7, %1 : !pdl.value -> ^bb15, ^bb2
  ^bb15:
    %8 = pdl_interp.get_value_type of %5 : !pdl.type
    %9 = pdl_interp.get_value_type of %6 : !pdl.type
    pdl_interp.are_equal %8, %9 : !pdl.type -> ^bb16, ^bb2
  ^bb16:
    %10 = pdl_interp.get_value_type of %7 : !pdl.type
    pdl_interp.are_equal %8, %10 : !pdl.type -> ^bb17, ^bb2
  ^bb17:
    %11 = pdl_interp.get_value_type of %3 : !pdl.type
    pdl_interp.are_equal %8, %11 : !pdl.type -> ^bb18, ^bb2
  ^bb18:
    pdl_interp.record_match @rewriters::@MulShlToShlMul(%5, %2, %8, %6, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb2
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb19, ^bb2
  ^bb19:
    pdl_interp.check_result_count of %0 is 1 -> ^bb20, ^bb2
  ^bb20:
    %12 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %12 : !pdl.value -> ^bb21, ^bb2
  ^bb21:
    %13 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %13 : !pdl.value -> ^bb22, ^bb2
  ^bb22:
    %14 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %14 : !pdl.value -> ^bb23, ^bb2
  ^bb23:
    pdl_interp.record_match @rewriters::@MulToPartialProductTree(%0 : !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb24
  ^bb24:
    %15 = pdl_interp.get_value_type of %12 : !pdl.type
    %16 = pdl_interp.get_value_type of %13 : !pdl.type
    pdl_interp.are_equal %15, %16 : !pdl.type -> ^bb25, ^bb2
  ^bb25:
    %17 = pdl_interp.get_value_type of %14 : !pdl.type
    pdl_interp.are_equal %15, %17 : !pdl.type -> ^bb26, ^bb2
  ^bb26:
    pdl_interp.check_type %15 is i8 -> ^bb27, ^bb2
  ^bb27:
    pdl_interp.record_match @rewriters::@MulToDatapath8(%12, %13, %0 : !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb2
  }
  builtin.module @rewriters {
    pdl_interp.func @MulShlToShlMul(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = pdl_interp.create_operation "comb.shl"(%0, %1 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %6 = pdl_interp.get_result 0 of %5
      %7 = pdl_interp.create_operation "comb.mul"(%6, %3 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = pdl_interp.get_results of %7 : !pdl.range<value>
      pdl_interp.replace %4 with (%8 : !pdl.range<value>)
      pdl_interp.finalize
    }
    pdl_interp.func @MulToDatapath8(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.operation) {
      %3 = pdl_interp.create_type i8
      %4 = pdl_interp.create_operation "datapath.partial_product"(%0, %1 : !pdl.value, !pdl.value) -> (%3, %3, %3, %3, %3, %3, %3, %3 : !pdl.type, !pdl.type, !pdl.type, !pdl.type, !pdl.type, !pdl.type, !pdl.type, !pdl.type)
      %5 = pdl_interp.get_result 0 of %4
      %6 = pdl_interp.get_result 1 of %4
      %7 = pdl_interp.get_result 2 of %4
      %8 = pdl_interp.get_result 3 of %4
      %9 = pdl_interp.get_result 4 of %4
      %10 = pdl_interp.get_result 5 of %4
      %11 = pdl_interp.get_result 6 of %4
      %12 = pdl_interp.get_result 7 of %4
      %13 = pdl_interp.create_operation "datapath.compress"(%5, %6, %7, %8, %9, %10, %11, %12 : !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.value) -> (%3, %3 : !pdl.type, !pdl.type)
      %14 = pdl_interp.get_result 0 of %13
      %15 = pdl_interp.get_result 1 of %13
      %16 = pdl_interp.create_operation "comb.add"(%14, %15 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %17 = pdl_interp.get_results of %16 : !pdl.range<value>
      pdl_interp.replace %2 with (%17 : !pdl.range<value>)
      pdl_interp.finalize
    }
    pdl_interp.func @MulToPartialProductTree(%0 : !pdl.operation) {
      %1 = pdl_interp.apply_rewrite "BuildPartialProduct"(%0 : !pdl.operation) : !pdl.operation
      %2 = pdl_interp.get_results of %1 : !pdl.range<value>
      pdl_interp.replace %0 with (%2 : !pdl.range<value>)
      pdl_interp.finalize
    }
  }
}

module @ir {
    // func.func @ShiftedFma(%a : i8, %b : i8, %s : i3, %c : i16) -> i17 {
    //   %false = hw.constant false
    //   %c0_i14 = hw.constant 0 : i14
    //   %c0_i9 = hw.constant 0 : i9
    //   %0 = comb.concat %c0_i9, %a : i9, i8
    //   %1 = comb.concat %c0_i9, %b : i9, i8
    //   %2 = comb.mul %0, %1 : i17
    //   %3 = comb.concat %c0_i14, %s : i14, i3
    //   %4 = comb.shl %2, %3 : i17
    //   %5 = comb.concat %false, %c : i1, i16
    //   %6 = comb.add %4, %5 : i17
    //   return %6 : i17
    // }


    func.func @Mul(%a : i8, %b : i8) -> i8 {
      %0 = comb.mul %a, %b : i8
      return %0 : i8
    }
}
