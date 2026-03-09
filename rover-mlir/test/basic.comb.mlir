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
      pdl_interp.check_operation_name of %7 is "comb.add" -> ^bb12, ^bb11
    ^bb12:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb13, ^bb11
    ^bb13:
      pdl_interp.check_result_count of %7 is 1 -> ^bb14, ^bb11
    ^bb14:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb15, ^bb11
    ^bb15:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb16, ^bb11
    ^bb16:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb17, ^bb11
    ^bb17:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb18, ^bb11
    ^bb18:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb19, ^bb11
    ^bb19:
      %12 = pdl_interp.get_value_type of %8 : !pdl.type
      %13 = pdl_interp.get_value_type of %9 : !pdl.type
      pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb20, ^bb11
    ^bb20:
      %14 = pdl_interp.get_value_type of %11 : !pdl.type
      pdl_interp.are_equal %12, %14 : !pdl.type -> ^bb21, ^bb11
    ^bb21:
      %15 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %12, %15 : !pdl.type -> ^bb22, ^bb11
    ^bb22:
      %16 = ematch.get_class_representative %8
      %17 = ematch.get_class_representative %2
      %18 = ematch.get_class_representative %9
      pdl_interp.record_match @rewriters::@AddShlToShlAdd(%16, %17, %12, %18, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb11
    } -> ^bb3
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb23, ^bb3
  ^bb23:
    pdl_interp.check_result_count of %0 is 1 -> ^bb24, ^bb3
  ^bb24:
    %19 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %19 : !pdl.value -> ^bb25, ^bb3
  ^bb25:
    %20 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %20 : !pdl.value -> ^bb26, ^bb3
  ^bb26:
    %21 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %21 : !pdl.value -> ^bb27, ^bb3
  ^bb27:
    %22 = ematch.get_class_result %21
    pdl_interp.is_not_null %22 : !pdl.value -> ^bb28, ^bb3
  ^bb28:
    %23 = ematch.get_class_vals %19
    pdl_interp.foreach %24 : !pdl.value in %23 {
      %25 = pdl_interp.get_defining_op of %24 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %25 : !pdl.operation -> ^bb29, ^bb30
    ^bb30:
      pdl_interp.continue
    ^bb29:
      pdl_interp.check_operation_name of %25 is "comb.add" -> ^bb31, ^bb30
    ^bb31:
      pdl_interp.check_operand_count of %25 is 2 -> ^bb32, ^bb30
    ^bb32:
      pdl_interp.check_result_count of %25 is 1 -> ^bb33, ^bb30
    ^bb33:
      %26 = pdl_interp.get_operand 0 of %25
      pdl_interp.is_not_null %26 : !pdl.value -> ^bb34, ^bb30
    ^bb34:
      %27 = pdl_interp.get_operand 1 of %25
      pdl_interp.is_not_null %27 : !pdl.value -> ^bb35, ^bb30
    ^bb35:
      %28 = pdl_interp.get_result 0 of %25
      pdl_interp.is_not_null %28 : !pdl.value -> ^bb36, ^bb30
    ^bb36:
      %29 = ematch.get_class_result %28
      pdl_interp.is_not_null %29 : !pdl.value -> ^bb37, ^bb30
    ^bb37:
      pdl_interp.are_equal %29, %19 : !pdl.value -> ^bb38, ^bb30
    ^bb38:
      %30 = pdl_interp.get_value_type of %26 : !pdl.type
      %31 = pdl_interp.get_value_type of %27 : !pdl.type
      pdl_interp.are_equal %30, %31 : !pdl.type -> ^bb39, ^bb30
    ^bb39:
      %32 = pdl_interp.get_value_type of %29 : !pdl.type
      pdl_interp.are_equal %30, %32 : !pdl.type -> ^bb40, ^bb30
    ^bb40:
      %33 = pdl_interp.get_value_type of %22 : !pdl.type
      pdl_interp.are_equal %30, %33 : !pdl.type -> ^bb41, ^bb30
    ^bb41:
      %34 = pdl_interp.get_value_type of %20 : !pdl.type
      pdl_interp.are_equal %30, %34 : !pdl.type -> ^bb42, ^bb30
    ^bb42:
      %35 = ematch.get_class_representative %26
      %36 = ematch.get_class_representative %27
      %37 = ematch.get_class_representative %20
      pdl_interp.record_match @rewriters::@AddAddToAdd3(%35, %36, %37, %30, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb30
    } -> ^bb3
  ^bb2:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb43, ^bb3
  ^bb43:
    pdl_interp.check_result_count of %0 is 1 -> ^bb44, ^bb3
  ^bb44:
    %38 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %38 : !pdl.value -> ^bb45, ^bb3
  ^bb45:
    %39 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %39 : !pdl.value -> ^bb46, ^bb3
  ^bb46:
    %40 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %40 : !pdl.value -> ^bb47, ^bb3
  ^bb47:
    %41 = ematch.get_class_result %40
    pdl_interp.is_not_null %41 : !pdl.value -> ^bb48, ^bb3
  ^bb48:
    %42 = pdl_interp.get_value_type of %41 : !pdl.type
    pdl_interp.record_match @rewriters::@MulToPartialProductTree(%0, %42 : !pdl.operation, !pdl.type) : benefit(1), loc([]), root("comb.mul") -> ^bb3
  }
  builtin.module @rewriters {
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
      %deduped = ematch.dedup %9
      %10 = pdl_interp.get_result 0 of %deduped
      %11 = ematch.get_class_result %10
      %12 = pdl_interp.get_result 1 of %deduped
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
      %dedup2 = ematch.dedup %2
      %3 = pdl_interp.get_results of %dedup2 : !pdl.range<value>
      %4 = ematch.get_class_results %3
      %5 = pdl_interp.apply_rewrite "BuildCompress"(%4 : !pdl.range<value>) : !pdl.operation
      %deduped = ematch.dedup %5
      %6 = pdl_interp.get_result 0 of %deduped
      %7 = ematch.get_class_result %6
      %8 = pdl_interp.get_result 1 of %deduped
      %9 = ematch.get_class_result %8
      %10 = pdl_interp.create_operation "comb.add"(%7, %9 : !pdl.value, !pdl.value) -> (%1 : !pdl.type)
      %11 = ematch.dedup %10
      %12 = pdl_interp.get_results of %11 : !pdl.range<value>
      %13 = ematch.get_class_results %12
      ematch.union %0 : !pdl.operation, %13 : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}
