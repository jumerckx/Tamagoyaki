// RUN: true

pdl_interp.func @matcher(%0: !pdl.operation) {
pdl_interp.check_operation_name of %0 is "arith.addf" -> ^bb0, ^bb1
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
    pdl_interp.check_operation_name of %7 is "arith.mulf" -> ^bb10, ^bb9
^bb10:
    pdl_interp.check_operand_count of %7 is 2 -> ^bb11, ^bb9
^bb11:
    pdl_interp.check_result_count of %7 is 1 -> ^bb12, ^bb9
^bb12:
    %8 = pdl_interp.get_operand 0 of %7
    pdl_interp.is_not_null %8 : !pdl.value -> ^bb13, ^bb9
^bb13:
    %9 = pdl_interp.get_result 0 of %7
    pdl_interp.is_not_null %9 : !pdl.value -> ^bb14, ^bb9
^bb14:
    %10 = ematch.get_class_result %9
    pdl_interp.is_not_null %10 : !pdl.value -> ^bb15, ^bb9
^bb15:
    pdl_interp.are_equal %10, %1 : !pdl.value -> ^bb16, ^bb9
^bb16:
    %11 = ematch.get_class_vals %2
    pdl_interp.foreach %12 : !pdl.value in %11 {
    %13 = pdl_interp.get_defining_op of %12 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %13 : !pdl.operation -> ^bb17, ^bb18
    ^bb18:
    pdl_interp.continue
    ^bb17:
    pdl_interp.check_operation_name of %13 is "arith.mulf" -> ^bb19, ^bb18
    ^bb19:
    pdl_interp.check_operand_count of %13 is 2 -> ^bb20, ^bb18
    ^bb20:
    pdl_interp.check_result_count of %13 is 1 -> ^bb21, ^bb18
    ^bb21:
    %14 = pdl_interp.get_operand 0 of %13
    pdl_interp.is_not_null %14 : !pdl.value -> ^bb22, ^bb18
    ^bb22:
    %15 = pdl_interp.get_result 0 of %13
    pdl_interp.is_not_null %15 : !pdl.value -> ^bb23, ^bb18
    ^bb23:
    %16 = ematch.get_class_result %15
    pdl_interp.is_not_null %16 : !pdl.value -> ^bb24, ^bb18
    ^bb24:
    pdl_interp.are_equal %16, %2 : !pdl.value -> ^bb25, ^bb18
    ^bb25:
    %17 = ematch.get_class_vals %8
    pdl_interp.foreach %18 : !pdl.value in %17 {
        %19 = pdl_interp.get_defining_op of %18 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
        pdl_interp.is_not_null %19 : !pdl.operation -> ^bb26, ^bb27
    ^bb27:
        pdl_interp.continue
    ^bb26:
        pdl_interp.check_operation_name of %19 is "math.sin" -> ^bb28, ^bb27
    ^bb28:
        pdl_interp.check_operand_count of %19 is 1 -> ^bb29, ^bb27
    ^bb29:
        pdl_interp.check_result_count of %19 is 1 -> ^bb30, ^bb27
    ^bb30:
        %20 = pdl_interp.get_operand 0 of %19
        pdl_interp.is_not_null %20 : !pdl.value -> ^bb31, ^bb27
    ^bb31:
        %21 = pdl_interp.get_result 0 of %19
        pdl_interp.is_not_null %21 : !pdl.value -> ^bb32, ^bb27
    ^bb32:
        %22 = ematch.get_class_result %21
        pdl_interp.is_not_null %22 : !pdl.value -> ^bb33, ^bb27
    ^bb33:
        pdl_interp.are_equal %22, %8 : !pdl.value -> ^bb34, ^bb27
    ^bb34:
        %23 = pdl_interp.get_value_type of %20 : !pdl.type
        %24 = pdl_interp.get_value_type of %22 : !pdl.type
        pdl_interp.are_equal %23, %24 : !pdl.type -> ^bb35, ^bb27
    ^bb35:
        %25 = pdl_interp.get_value_type of %10 : !pdl.type
        pdl_interp.are_equal %23, %25 : !pdl.type -> ^bb36, ^bb27
    ^bb36:
        %26 = pdl_interp.get_value_type of %16 : !pdl.type
        pdl_interp.are_equal %23, %26 : !pdl.type -> ^bb37, ^bb27
    ^bb37:
        %27 = pdl_interp.get_value_type of %4 : !pdl.type
        pdl_interp.are_equal %23, %27 : !pdl.type -> ^bb38, ^bb27
    ^bb38:
        pdl_interp.check_type %23 is f32 -> ^bb39, ^bb27
    ^bb39:
        %28 = ematch.get_class_vals %14
        pdl_interp.foreach %29 : !pdl.value in %28 {
        %30 = pdl_interp.get_defining_op of %29 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
        pdl_interp.is_not_null %30 : !pdl.operation -> ^bb40, ^bb41
        ^bb41:
        pdl_interp.continue
        ^bb40:
        pdl_interp.check_operation_name of %30 is "math.cos" -> ^bb42, ^bb41
        ^bb42:
        pdl_interp.check_operand_count of %30 is 1 -> ^bb43, ^bb41
        ^bb43:
        pdl_interp.check_result_count of %30 is 1 -> ^bb44, ^bb41
        ^bb44:
        %31 = pdl_interp.get_operand 0 of %30
        pdl_interp.are_equal %20, %31 : !pdl.value -> ^bb45, ^bb41
        ^bb45:
        %32 = pdl_interp.get_result 0 of %30
        pdl_interp.is_not_null %32 : !pdl.value -> ^bb46, ^bb41
        ^bb46:
        %33 = ematch.get_class_result %32
        pdl_interp.is_not_null %33 : !pdl.value -> ^bb47, ^bb41
        ^bb47:
        pdl_interp.are_equal %33, %14 : !pdl.value -> ^bb48, ^bb41
        ^bb48:
        %34 = pdl_interp.get_value_type of %33 : !pdl.type
        pdl_interp.are_equal %23, %34 : !pdl.type -> ^bb49, ^bb41
        ^bb49:
        pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%0 : !pdl.operation) : benefit(1), loc([]), root("arith.addf") -> ^bb41
        } -> ^bb27
    } -> ^bb18
    } -> ^bb9
} -> ^bb1
}
builtin.module @rewriters {
pdl_interp.func @pdl_generated_rewriter(%0: !pdl.operation) {
    %1 = pdl_interp.create_attribute 1.000000e+00 : f32
    %2 = pdl_interp.create_type f32
    %3 = pdl_interp.create_operation "arith.constant" {"value" = %1} -> (%2 : !pdl.type)
    %4 = ematch.dedup %3
    %5 = pdl_interp.get_results of %4 : !pdl.range<value>
    %6 = ematch.get_class_results %5
    ematch.union %0 : !pdl.operation, %6 : !pdl.range<value>
    pdl_interp.finalize
}
}
