builtin.module @patterns {
pdl_interp.func @matcher(%0 : !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["comb.shl", "comb.add", "comb.mul"](^bb0, ^bb1, ^bb2) -> ^bb3
  ^bb3:
    pdl_interp.finalize
  ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb4, ^bb3
  ^bb4:
    pdl_interp.check_result_count of %0 is 1 -> ^bb5, ^bb3
  ^bb5:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb6, ^bb3
  ^bb6:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb7, ^bb3
  ^bb7:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb8, ^bb3
  ^bb8:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb9, ^bb3
  ^bb9:
    %5 = ematch.get_class_vals %1
    pdl_interp.foreach %6 : !pdl.value in %5 {
      %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %7 : !pdl.operation -> ^bb10, ^bb11
    ^bb11:
      pdl_interp.continue
    ^bb10:
      pdl_interp.switch_operation_name of %7 to ["comb.mul", "comb.add"](^bb12, ^bb13) -> ^bb11
    ^bb12:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb14, ^bb11
    ^bb14:
      pdl_interp.check_result_count of %7 is 1 -> ^bb15, ^bb11
    ^bb15:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb16, ^bb11
    ^bb16:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb17, ^bb11
    ^bb17:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb18, ^bb11
    ^bb18:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb19, ^bb11
    ^bb19:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb20, ^bb11
    ^bb20:
      %12 = pdl_interp.get_value_type of %8 : !pdl.type
      %13 = pdl_interp.get_value_type of %9 : !pdl.type
      pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb21, ^bb11
    ^bb21:
      %14 = pdl_interp.get_value_type of %11 : !pdl.type
      pdl_interp.are_equal %12, %14 : !pdl.type -> ^bb22, ^bb11
    ^bb22:
      %15 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %12, %15 : !pdl.type -> ^bb23, ^bb11
    ^bb23:
      %16 = ematch.get_class_representative %8
      %17 = ematch.get_class_representative %2
      %18 = ematch.get_class_representative %9
      pdl_interp.record_match @rewriters::@MulShlToShlMul(%16, %17, %12, %18, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb11
    ^bb13:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb24, ^bb11
    ^bb24:
      pdl_interp.check_result_count of %7 is 1 -> ^bb25, ^bb11
    ^bb25:
      %19 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %19 : !pdl.value -> ^bb26, ^bb11
    ^bb26:
      %20 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %20 : !pdl.value -> ^bb27, ^bb11
    ^bb27:
      %21 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %21 : !pdl.value -> ^bb28, ^bb11
    ^bb28:
      %22 = ematch.get_class_result %21
      pdl_interp.is_not_null %22 : !pdl.value -> ^bb29, ^bb11
    ^bb29:
      pdl_interp.are_equal %22, %1 : !pdl.value -> ^bb30, ^bb11
    ^bb30:
      %23 = pdl_interp.get_value_type of %19 : !pdl.type
      %24 = pdl_interp.get_value_type of %20 : !pdl.type
      pdl_interp.are_equal %23, %24 : !pdl.type -> ^bb31, ^bb11
    ^bb31:
      %25 = pdl_interp.get_value_type of %22 : !pdl.type
      pdl_interp.are_equal %23, %25 : !pdl.type -> ^bb32, ^bb11
    ^bb32:
      %26 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %23, %26 : !pdl.type -> ^bb33, ^bb11
    ^bb33:
      %27 = ematch.get_class_representative %19
      %28 = ematch.get_class_representative %2
      %29 = ematch.get_class_representative %20
      pdl_interp.record_match @rewriters::@AddShlToShlAdd(%27, %28, %23, %29, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb11
    } -> ^bb3
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb34, ^bb3
  ^bb34:
    pdl_interp.check_result_count of %0 is 1 -> ^bb35, ^bb3
  ^bb35:
    %30 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %30 : !pdl.value -> ^bb36, ^bb3
  ^bb36:
    %31 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %31 : !pdl.value -> ^bb37, ^bb3
  ^bb37:
    %32 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %32 : !pdl.value -> ^bb38, ^bb3
  ^bb38:
    %33 = ematch.get_class_result %32
    pdl_interp.is_not_null %33 : !pdl.value -> ^bb39, ^bb3
  ^bb39:
    %34 = ematch.get_class_vals %30
    pdl_interp.foreach %35 : !pdl.value in %34 {
      %36 = pdl_interp.get_defining_op of %35 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %36 : !pdl.operation -> ^bb40, ^bb41
    ^bb41:
      pdl_interp.continue
    ^bb40:
      pdl_interp.check_operation_name of %36 is "comb.add" -> ^bb42, ^bb41
    ^bb42:
      pdl_interp.check_operand_count of %36 is 2 -> ^bb43, ^bb41
    ^bb43:
      pdl_interp.check_result_count of %36 is 1 -> ^bb44, ^bb41
    ^bb44:
      %37 = pdl_interp.get_operand 0 of %36
      pdl_interp.is_not_null %37 : !pdl.value -> ^bb45, ^bb41
    ^bb45:
      %38 = pdl_interp.get_operand 1 of %36
      pdl_interp.is_not_null %38 : !pdl.value -> ^bb46, ^bb41
    ^bb46:
      %39 = pdl_interp.get_result 0 of %36
      pdl_interp.is_not_null %39 : !pdl.value -> ^bb47, ^bb41
    ^bb47:
      %40 = ematch.get_class_result %39
      pdl_interp.is_not_null %40 : !pdl.value -> ^bb48, ^bb41
    ^bb48:
      pdl_interp.are_equal %40, %30 : !pdl.value -> ^bb49, ^bb41
    ^bb49:
      %41 = pdl_interp.get_value_type of %37 : !pdl.type
      %42 = pdl_interp.get_value_type of %38 : !pdl.type
      pdl_interp.are_equal %41, %42 : !pdl.type -> ^bb50, ^bb41
    ^bb50:
      %43 = pdl_interp.get_value_type of %40 : !pdl.type
      pdl_interp.are_equal %41, %43 : !pdl.type -> ^bb51, ^bb41
    ^bb51:
      %44 = pdl_interp.get_value_type of %33 : !pdl.type
      pdl_interp.are_equal %41, %44 : !pdl.type -> ^bb52, ^bb41
    ^bb52:
      %45 = pdl_interp.get_value_type of %31 : !pdl.type
      pdl_interp.are_equal %41, %45 : !pdl.type -> ^bb53, ^bb41
    ^bb53:
      %46 = ematch.get_class_representative %37
      %47 = ematch.get_class_representative %38
      %48 = ematch.get_class_representative %31
      pdl_interp.record_match @rewriters::@AddAddToAdd3(%46, %47, %48, %41, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb41
    } -> ^bb3
  ^bb2:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb54, ^bb3
  ^bb54:
    pdl_interp.check_result_count of %0 is 1 -> ^bb55, ^bb3
  ^bb55:
    %49 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %49 : !pdl.value -> ^bb56, ^bb3
  ^bb56:
    %50 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %50 : !pdl.value -> ^bb57, ^bb3
  ^bb57:
    %51 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %51 : !pdl.value -> ^bb58, ^bb3
  ^bb58:
    %52 = ematch.get_class_result %51
    pdl_interp.is_not_null %52 : !pdl.value -> ^bb59, ^bb3
  ^bb59:
    %53 = pdl_interp.get_value_type of %52 : !pdl.type
    pdl_interp.record_match @rewriters::@MulToPartialProductTree(%0, %53 : !pdl.operation, !pdl.type) : benefit(1), loc([]), root("comb.mul") -> ^bb3
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
    pdl_interp.func @AddShlToShlAdd(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.shl"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.shl"(%11, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_result 0 of %13
      %15 = ematch.get_class_result %14
      %16 = pdl_interp.create_operation "comb.add"(%10, %15 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %17 = ematch.dedup %16
      %18 = pdl_interp.get_results of %17 : !pdl.range<value>
      %19 = ematch.get_class_results %18
      ematch.union %4 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AddAddToAdd3(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.type, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = ematch.get_class_result %2
      %8 = pdl_interp.create_range %5, %6, %7 : !pdl.value, !pdl.value, !pdl.value
      %9 = pdl_interp.apply_rewrite "BuildCompress"(%8 : !pdl.range<value>) : !pdl.operation
      %10 = pdl_interp.get_result 0 of %9
      %11 = ematch.get_class_result %10
      %12 = pdl_interp.get_result 1 of %9
      %13 = ematch.get_class_result %12
      %14 = pdl_interp.create_operation "comb.add"(%11, %13 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %15 = ematch.dedup %14
      %16 = pdl_interp.get_results of %15 : !pdl.range<value>
      %17 = ematch.get_class_results %16
      ematch.union %4 : !pdl.operation, %17 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MulToPartialProductTree(%0 : !pdl.operation, %1 : !pdl.type) {
      %2 = pdl_interp.apply_rewrite "BuildPartialProduct"(%0 : !pdl.operation) : !pdl.operation
      %3 = ematch.dedup %2
      %4 = pdl_interp.get_results of %3 : !pdl.range<value>
      %5 = ematch.get_class_results %4
      %6 = pdl_interp.apply_rewrite "BuildCompress"(%5 : !pdl.range<value>) : !pdl.operation
      %7 = ematch.dedup %6
      %8 = pdl_interp.get_result 0 of %7
      %9 = ematch.get_class_result %8
      %10= pdl_interp.get_result 1 of %7
      %11= ematch.get_class_result %10
      %12 = pdl_interp.create_operation "comb.add"(%9, %11 : !pdl.value, !pdl.value) -> (%1 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %0 : !pdl.operation, %15 : !pdl.range<value>
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


    func.func @Mul(%a : i8, %b : i8) -> i8 {
      %0 = comb.mul %a, %b : i8
      return %0 : i8
    }
}
