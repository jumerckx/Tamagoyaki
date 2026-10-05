// Generated from patterns.pdl.mlir by xDSL:
//   uv run --with=xdsl xdsl-opt -p 'convert-pdl-to-pdl-interp{optimize_for_eqsat=true}' \
//     patterns.pdl.mlir -o patterns.mlir
// Do not edit by hand; edit patterns.pdl.mlir and regenerate.

// RUN: true

builtin.module {
  pdl_interp.func @matcher(%0: !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["llvm.sub", "llvm.add"](^bb2, ^bb9) -> ^bb1
  ^bb1:
    pdl_interp.finalize
  ^bb2:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb3, ^bb1
  ^bb3:
    pdl_interp.check_result_count of %0 is 1 -> ^bb4, ^bb1
  ^bb4:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb5, ^bb1
  ^bb5:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb6, ^bb1
  ^bb6:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb7, ^bb1
  ^bb7:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb8, ^bb1
  ^bb8:
    %5 = ematch.get_class_vals %1
    pdl_interp.foreach %6 : !pdl.value in %5 {
      %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %7 : !pdl.operation -> ^bb2, ^bb1
    ^bb1:
      pdl_interp.continue
    ^bb2:
      pdl_interp.check_operation_name of %7 is "llvm.sub" -> ^bb3, ^bb1
    ^bb3:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb4, ^bb1
    ^bb4:
      pdl_interp.check_result_count of %7 is 1 -> ^bb5, ^bb1
    ^bb5:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb6, ^bb1
    ^bb6:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb7, ^bb1
    ^bb7:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb8, ^bb1
    ^bb8:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb9, ^bb1
    ^bb9:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb10, ^bb1
    ^bb10:
      %12 = ematch.get_class_vals %2
      pdl_interp.foreach %13 : !pdl.value in %12 {
        %14 = pdl_interp.get_defining_op of %13 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %14 : !pdl.operation -> ^bb2, ^bb1
      ^bb1:
        pdl_interp.continue
      ^bb2:
        pdl_interp.check_operation_name of %14 is "llvm.sub" -> ^bb3, ^bb1
      ^bb3:
        pdl_interp.check_operand_count of %14 is 2 -> ^bb4, ^bb1
      ^bb4:
        pdl_interp.check_result_count of %14 is 1 -> ^bb5, ^bb1
      ^bb5:
        %15 = pdl_interp.get_operand 0 of %14
        pdl_interp.is_not_null %15 : !pdl.value -> ^bb6, ^bb1
      ^bb6:
        %16 = pdl_interp.get_operand 1 of %14
        pdl_interp.is_not_null %16 : !pdl.value -> ^bb7, ^bb1
      ^bb7:
        %17 = pdl_interp.get_result 0 of %14
        pdl_interp.is_not_null %17 : !pdl.value -> ^bb8, ^bb1
      ^bb8:
        %18 = ematch.get_class_result %17
        pdl_interp.is_not_null %18 : !pdl.value -> ^bb9, ^bb1
      ^bb9:
        pdl_interp.are_equal %18, %2 : !pdl.value -> ^bb10, ^bb1
      ^bb10:
        %19 = ematch.get_class_vals %8
        pdl_interp.foreach %20 : !pdl.value in %19 {
          %21 = pdl_interp.get_defining_op of %20 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
          pdl_interp.is_not_null %21 : !pdl.operation -> ^bb2, ^bb1
        ^bb1:
          pdl_interp.continue
        ^bb2:
          pdl_interp.check_operation_name of %21 is "llvm.mlir.constant" -> ^bb3, ^bb1
        ^bb3:
          pdl_interp.check_operand_count of %21 is 0 -> ^bb4, ^bb1
        ^bb4:
          pdl_interp.check_result_count of %21 is 1 -> ^bb5, ^bb1
        ^bb5:
          %22 = pdl_interp.get_attribute "value" of %21
          pdl_interp.is_not_null %22 : !pdl.attribute -> ^bb6, ^bb1
        ^bb6:
          %23 = pdl_interp.get_result 0 of %21
          pdl_interp.is_not_null %23 : !pdl.value -> ^bb7, ^bb1
        ^bb7:
          %24 = ematch.get_class_result %23
          pdl_interp.is_not_null %24 : !pdl.value -> ^bb8, ^bb1
        ^bb8:
          pdl_interp.are_equal %24, %8 : !pdl.value -> ^bb9, ^bb1
        ^bb9:
          %25 = pdl_interp.get_value_type of %24 : !pdl.type
          %26 = pdl_interp.get_value_type of %11 : !pdl.type
          pdl_interp.are_equal %25, %26 : !pdl.type -> ^bb10, ^bb1
        ^bb10:
          %27 = pdl_interp.get_value_type of %18 : !pdl.type
          pdl_interp.are_equal %25, %27 : !pdl.type -> ^bb11, ^bb1
        ^bb11:
          %28 = pdl_interp.get_value_type of %4 : !pdl.type
          pdl_interp.are_equal %25, %28 : !pdl.type -> ^bb12, ^bb1
        ^bb12:
          %29 = ematch.get_class_vals %15
          pdl_interp.foreach %30 : !pdl.value in %29 {
            %31 = pdl_interp.get_defining_op of %30 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
            pdl_interp.is_not_null %31 : !pdl.operation -> ^bb2, ^bb1
          ^bb1:
            pdl_interp.continue
          ^bb2:
            pdl_interp.check_operation_name of %31 is "llvm.mlir.constant" -> ^bb3, ^bb1
          ^bb3:
            pdl_interp.check_operand_count of %31 is 0 -> ^bb4, ^bb1
          ^bb4:
            pdl_interp.check_result_count of %31 is 1 -> ^bb5, ^bb1
          ^bb5:
            %32 = pdl_interp.get_attribute "value" of %31
            pdl_interp.are_equal %22, %32 : !pdl.attribute -> ^bb6, ^bb1
          ^bb6:
            %33 = pdl_interp.get_result 0 of %31
            pdl_interp.is_not_null %33 : !pdl.value -> ^bb7, ^bb1
          ^bb7:
            %34 = ematch.get_class_result %33
            pdl_interp.is_not_null %34 : !pdl.value -> ^bb8, ^bb1
          ^bb8:
            pdl_interp.are_equal %34, %15 : !pdl.value -> ^bb9, ^bb1
          ^bb9:
            %35 = pdl_interp.get_value_type of %34 : !pdl.type
            pdl_interp.are_equal %25, %35 : !pdl.type -> ^bb10, ^bb1
          ^bb10:
            %36 = ematch.get_class_representative %16
            %37 = ematch.get_class_representative %9
            pdl_interp.record_match @rewriters::@neg_sub_neg(%36, %37, %25, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("llvm.sub") -> ^bb1
          } -> ^bb1
        } -> ^bb1
      } -> ^bb1
    } -> ^bb1
  ^bb9:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb10, ^bb1
  ^bb10:
    pdl_interp.check_result_count of %0 is 1 -> ^bb11, ^bb1
  ^bb11:
    %38 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %38 : !pdl.value -> ^bb12, ^bb1
  ^bb12:
    %39 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %39 : !pdl.value -> ^bb13, ^bb1
  ^bb13:
    %40 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %40 : !pdl.value -> ^bb14, ^bb1
  ^bb14:
    %41 = ematch.get_class_result %40
    pdl_interp.is_not_null %41 : !pdl.value -> ^bb15, ^bb1
  ^bb15:
    %42 = ematch.get_class_vals %38
    pdl_interp.foreach %43 : !pdl.value in %42 {
      %44 = pdl_interp.get_defining_op of %43 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %44 : !pdl.operation -> ^bb2, ^bb1
    ^bb1:
      pdl_interp.continue
    ^bb2:
      pdl_interp.check_operation_name of %44 is "llvm.sub" -> ^bb3, ^bb1
    ^bb3:
      pdl_interp.check_operand_count of %44 is 2 -> ^bb4, ^bb1
    ^bb4:
      pdl_interp.check_result_count of %44 is 1 -> ^bb5, ^bb1
    ^bb5:
      %45 = pdl_interp.get_operand 0 of %44
      pdl_interp.is_not_null %45 : !pdl.value -> ^bb6, ^bb1
    ^bb6:
      %46 = pdl_interp.get_operand 1 of %44
      pdl_interp.is_not_null %46 : !pdl.value -> ^bb7, ^bb1
    ^bb7:
      %47 = pdl_interp.get_result 0 of %44
      pdl_interp.is_not_null %47 : !pdl.value -> ^bb8, ^bb1
    ^bb8:
      %48 = ematch.get_class_result %47
      pdl_interp.is_not_null %48 : !pdl.value -> ^bb9, ^bb1
    ^bb9:
      pdl_interp.are_equal %48, %38 : !pdl.value -> ^bb10, ^bb1
    ^bb10:
      %49 = ematch.get_class_vals %39
      pdl_interp.foreach %50 : !pdl.value in %49 {
        %51 = pdl_interp.get_defining_op of %50 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %51 : !pdl.operation -> ^bb2, ^bb1
      ^bb1:
        pdl_interp.continue
      ^bb2:
        pdl_interp.check_operation_name of %51 is "llvm.sub" -> ^bb3, ^bb1
      ^bb3:
        pdl_interp.check_operand_count of %51 is 2 -> ^bb4, ^bb1
      ^bb4:
        pdl_interp.check_result_count of %51 is 1 -> ^bb5, ^bb1
      ^bb5:
        %52 = pdl_interp.get_operand 0 of %51
        pdl_interp.is_not_null %52 : !pdl.value -> ^bb6, ^bb1
      ^bb6:
        %53 = pdl_interp.get_operand 1 of %51
        pdl_interp.is_not_null %53 : !pdl.value -> ^bb7, ^bb1
      ^bb7:
        %54 = pdl_interp.get_result 0 of %51
        pdl_interp.is_not_null %54 : !pdl.value -> ^bb8, ^bb1
      ^bb8:
        %55 = ematch.get_class_result %54
        pdl_interp.is_not_null %55 : !pdl.value -> ^bb9, ^bb1
      ^bb9:
        pdl_interp.are_equal %55, %39 : !pdl.value -> ^bb10, ^bb1
      ^bb10:
        %56 = ematch.get_class_vals %45
        pdl_interp.foreach %57 : !pdl.value in %56 {
          %58 = pdl_interp.get_defining_op of %57 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
          pdl_interp.is_not_null %58 : !pdl.operation -> ^bb2, ^bb1
        ^bb1:
          pdl_interp.continue
        ^bb2:
          pdl_interp.check_operation_name of %58 is "llvm.mlir.constant" -> ^bb3, ^bb1
        ^bb3:
          pdl_interp.check_operand_count of %58 is 0 -> ^bb4, ^bb1
        ^bb4:
          pdl_interp.check_result_count of %58 is 1 -> ^bb5, ^bb1
        ^bb5:
          %59 = pdl_interp.get_attribute "value" of %58
          pdl_interp.is_not_null %59 : !pdl.attribute -> ^bb6, ^bb1
        ^bb6:
          %60 = pdl_interp.get_result 0 of %58
          pdl_interp.is_not_null %60 : !pdl.value -> ^bb7, ^bb1
        ^bb7:
          %61 = ematch.get_class_result %60
          pdl_interp.is_not_null %61 : !pdl.value -> ^bb8, ^bb1
        ^bb8:
          pdl_interp.are_equal %61, %45 : !pdl.value -> ^bb9, ^bb1
        ^bb9:
          %62 = pdl_interp.get_value_type of %61 : !pdl.type
          %63 = pdl_interp.get_value_type of %48 : !pdl.type
          pdl_interp.are_equal %62, %63 : !pdl.type -> ^bb10, ^bb1
        ^bb10:
          %64 = pdl_interp.get_value_type of %55 : !pdl.type
          pdl_interp.are_equal %62, %64 : !pdl.type -> ^bb11, ^bb1
        ^bb11:
          %65 = pdl_interp.get_value_type of %41 : !pdl.type
          pdl_interp.are_equal %62, %65 : !pdl.type -> ^bb12, ^bb1
        ^bb12:
          %66 = ematch.get_class_vals %52
          pdl_interp.foreach %67 : !pdl.value in %66 {
            %68 = pdl_interp.get_defining_op of %67 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
            pdl_interp.is_not_null %68 : !pdl.operation -> ^bb2, ^bb1
          ^bb1:
            pdl_interp.continue
          ^bb2:
            pdl_interp.check_operation_name of %68 is "llvm.mlir.constant" -> ^bb3, ^bb1
          ^bb3:
            pdl_interp.check_operand_count of %68 is 0 -> ^bb4, ^bb1
          ^bb4:
            pdl_interp.check_result_count of %68 is 1 -> ^bb5, ^bb1
          ^bb5:
            %69 = pdl_interp.get_attribute "value" of %68
            pdl_interp.are_equal %59, %69 : !pdl.attribute -> ^bb6, ^bb1
          ^bb6:
            %70 = pdl_interp.get_result 0 of %68
            pdl_interp.is_not_null %70 : !pdl.value -> ^bb7, ^bb1
          ^bb7:
            %71 = ematch.get_class_result %70
            pdl_interp.is_not_null %71 : !pdl.value -> ^bb8, ^bb1
          ^bb8:
            pdl_interp.are_equal %71, %52 : !pdl.value -> ^bb9, ^bb1
          ^bb9:
            %72 = pdl_interp.get_value_type of %71 : !pdl.type
            pdl_interp.are_equal %62, %72 : !pdl.type -> ^bb10, ^bb1
          ^bb10:
            %73 = ematch.get_class_representative %46
            %74 = ematch.get_class_representative %53
            pdl_interp.record_match @rewriters::@neg_add_neg(%73, %74, %62, %59, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.attribute, !pdl.operation) : benefit(1), loc([]), root("llvm.add") -> ^bb1
          } -> ^bb1
        } -> ^bb1
      } -> ^bb1
    } -> ^bb1
  }
  builtin.module @rewriters {
    pdl_interp.func @neg_sub_neg(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.operation) {
      %4 = ematch.get_class_result %0
      %5 = ematch.get_class_result %1
      %6 = pdl_interp.create_operation "llvm.sub"(%4, %5 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %7 = ematch.dedup %6
      %8 = pdl_interp.get_result 0 of %7
      %9 = ematch.get_class_result %8
      %10 = pdl_interp.create_range %9 : !pdl.value
      ematch.union %3 : !pdl.operation, %10 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @neg_add_neg(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.attribute, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "llvm.add"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = pdl_interp.create_operation "llvm.mlir.constant" {"value" = %3} -> (%2 : !pdl.type)
      %12 = ematch.dedup %11
      %13 = pdl_interp.get_result 0 of %12
      %14 = ematch.get_class_result %13
      %15 = pdl_interp.create_operation "llvm.sub"(%14, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %16 = ematch.dedup %15
      %17 = pdl_interp.get_result 0 of %16
      %18 = ematch.get_class_result %17
      %19 = pdl_interp.create_range %18 : !pdl.value
      ematch.union %4 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}

