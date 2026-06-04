// // Matches:  (ah * bl) + (al * bh)
// pdl.pattern @CrossTermToKaratsuba : benefit(1) {
//   %i8 = pdl.type : i8
//   %ah = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_0"(%ah : !pdl.value)
//   %al = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_1"(%al : !pdl.value)
  
//   %bh = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_2"(%bh: !pdl.value)
  
//   %bl = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_3"(%bl : !pdl.value)

//   %ahbl = pdl.operation "arith.muli"(%ah, %bl : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %ahblRes = pdl.result 0 of %ahbl
//   %albh = pdl.operation "arith.muli"(%al, %bh : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %albhRes = pdl.result 0 of %albh
//   %add = pdl.operation "arith.addi"(%ahblRes, %albhRes : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %add with "rewriter"
// }

// // Matches:  ((ah + al) * (bh + bl)) - (ah * bh) - (al * bl)
// pdl.pattern @KaratsubaToCrossTerm : benefit(1) {
//   %i8 = pdl.type : i8
//   %ah = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_0"(%ah : !pdl.value)
//   %al = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_1"(%al : !pdl.value)

//   %bh = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_2"(%bh : !pdl.value)

//   %bl = pdl.operand : %i8
//   pdl.apply_native_constraint "is_arg_3"(%bl : !pdl.value)

//   // (ah + al)
//   %ahPlusAl = pdl.operation "arith.addi"(%ah, %al : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//   %ahPlusAlRes = pdl.result 0 of %ahPlusAl

//   // (bh + bl)
//   %bhPlusBl = pdl.operation "arith.addi"(%bh, %bl : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//   %bhPlusBlRes = pdl.result 0 of %bhPlusBl

//   // (ah + al) * (bh + bl)
//   %prod = pdl.operation "arith.muli"(%ahPlusAlRes, %bhPlusBlRes : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %prodRes = pdl.result 0 of %prod

//   // ah * bh
//   %ahbh = pdl.operation "arith.muli"(%ah, %bh : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %ahbhRes = pdl.result 0 of %ahbh

//   // al * bl
//   %albl = pdl.operation "arith.muli"(%al, %bl : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %alblRes = pdl.result 0 of %albl

//   // ((ah+al)*(bh+bl)) - ah*bh
//   %sub1 = pdl.operation "arith.subi"(%prodRes, %ahbhRes : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %sub1Res = pdl.result 0 of %sub1

//   // (... - ah*bh) - al*bl
//   %sub2 = pdl.operation "arith.subi"(%sub1Res, %alblRes : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)

//   pdl.rewrite %sub2 with "rewriter"
// }


pdl_interp.func @matcher(%0: !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["arith.addi", "arith.subi"](^bb0, ^bb1) -> ^bb2
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
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb8, ^bb2
  ^bb8:
    %5 = ematch.get_class_vals %1
    pdl_interp.foreach %6 : !pdl.value in %5 {
      %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %7 : !pdl.operation -> ^bb9, ^bb10
    ^bb10:
      pdl_interp.continue
    ^bb9:
      pdl_interp.check_operation_name of %7 is "arith.muli" -> ^bb11, ^bb10
    ^bb11:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb12, ^bb10
    ^bb12:
      pdl_interp.check_result_count of %7 is 1 -> ^bb13, ^bb10
    ^bb13:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb14, ^bb10
    ^bb14:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb15, ^bb10
    ^bb15:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb16, ^bb10
    ^bb16:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb17, ^bb10
    ^bb17:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb18, ^bb10
    ^bb18:
      pdl_interp.apply_constraint "is_arg_0"(%8 : !pdl.value) -> ^bb19, ^bb10
    ^bb19:
      pdl_interp.apply_constraint "is_arg_3"(%9 : !pdl.value) -> ^bb20, ^bb10
    ^bb20:
      %12 = pdl_interp.get_value_type of %8 : !pdl.type
      %13 = pdl_interp.get_value_type of %9 : !pdl.type
      pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb21, ^bb10
    ^bb21:
      %14 = pdl_interp.get_value_type of %11 : !pdl.type
      pdl_interp.are_equal %12, %14 : !pdl.type -> ^bb22, ^bb10
    ^bb22:
      %15 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %12, %15 : !pdl.type -> ^bb23, ^bb10
    ^bb23:
      pdl_interp.check_type %12 is i8 -> ^bb24, ^bb10
    ^bb24:
      %16 = ematch.get_class_vals %2
      pdl_interp.foreach %17 : !pdl.value in %16 {
        %18 = pdl_interp.get_defining_op of %17 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %18 : !pdl.operation -> ^bb25, ^bb26
      ^bb26:
        pdl_interp.continue
      ^bb25:
        pdl_interp.check_operation_name of %18 is "arith.muli" -> ^bb27, ^bb26
      ^bb27:
        pdl_interp.check_operand_count of %18 is 2 -> ^bb28, ^bb26
      ^bb28:
        pdl_interp.check_result_count of %18 is 1 -> ^bb29, ^bb26
      ^bb29:
        %19 = pdl_interp.get_result 0 of %18
        pdl_interp.is_not_null %19 : !pdl.value -> ^bb30, ^bb26
      ^bb30:
        %20 = ematch.get_class_result %19
        pdl_interp.is_not_null %20 : !pdl.value -> ^bb31, ^bb26
      ^bb31:
        pdl_interp.are_equal %20, %2 : !pdl.value -> ^bb32, ^bb26
      ^bb32:
        %21 = pdl_interp.get_operand 0 of %18
        pdl_interp.is_not_null %21 : !pdl.value -> ^bb33, ^bb26
      ^bb33:
        %22 = pdl_interp.get_operand 1 of %18
        pdl_interp.is_not_null %22 : !pdl.value -> ^bb34, ^bb26
      ^bb34:
        pdl_interp.apply_constraint "is_arg_1"(%21 : !pdl.value) -> ^bb35, ^bb26
      ^bb35:
        pdl_interp.apply_constraint "is_arg_2"(%22 : !pdl.value) -> ^bb36, ^bb26
      ^bb36:
        %23 = pdl_interp.get_value_type of %21 : !pdl.type
        pdl_interp.are_equal %12, %23 : !pdl.type -> ^bb37, ^bb26
      ^bb37:
        %24 = pdl_interp.get_value_type of %22 : !pdl.type
        pdl_interp.are_equal %12, %24 : !pdl.type -> ^bb38, ^bb26
      ^bb38:
        %25 = pdl_interp.get_value_type of %20 : !pdl.type
        pdl_interp.are_equal %12, %25 : !pdl.type -> ^bb39, ^bb26
      ^bb39:
        pdl_interp.record_match @rewriters::@CrossTermToKaratsuba(%0 : !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb26
      } -> ^bb10
    } -> ^bb2
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb40, ^bb2
  ^bb40:
    pdl_interp.check_result_count of %0 is 1 -> ^bb41, ^bb2
  ^bb41:
    %26 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %26 : !pdl.value -> ^bb42, ^bb2
  ^bb42:
    %27 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %27 : !pdl.value -> ^bb43, ^bb2
  ^bb43:
    %28 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %28 : !pdl.value -> ^bb44, ^bb2
  ^bb44:
    %29 = ematch.get_class_result %28
    pdl_interp.is_not_null %29 : !pdl.value -> ^bb45, ^bb2
  ^bb45:
    %30 = ematch.get_class_vals %26
    pdl_interp.foreach %31 : !pdl.value in %30 {
      %32 = pdl_interp.get_defining_op of %31 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %32 : !pdl.operation -> ^bb46, ^bb47
    ^bb47:
      pdl_interp.continue
    ^bb46:
      pdl_interp.check_operation_name of %32 is "arith.subi" -> ^bb48, ^bb47
    ^bb48:
      pdl_interp.check_operand_count of %32 is 2 -> ^bb49, ^bb47
    ^bb49:
      pdl_interp.check_result_count of %32 is 1 -> ^bb50, ^bb47
    ^bb50:
      %33 = pdl_interp.get_operand 0 of %32
      pdl_interp.is_not_null %33 : !pdl.value -> ^bb51, ^bb47
    ^bb51:
      %34 = pdl_interp.get_operand 1 of %32
      pdl_interp.is_not_null %34 : !pdl.value -> ^bb52, ^bb47
    ^bb52:
      %35 = pdl_interp.get_result 0 of %32
      pdl_interp.is_not_null %35 : !pdl.value -> ^bb53, ^bb47
    ^bb53:
      %36 = ematch.get_class_result %35
      pdl_interp.is_not_null %36 : !pdl.value -> ^bb54, ^bb47
    ^bb54:
      pdl_interp.are_equal %36, %26 : !pdl.value -> ^bb55, ^bb47
    ^bb55:
      %37 = ematch.get_class_vals %27
      pdl_interp.foreach %38 : !pdl.value in %37 {
        %39 = pdl_interp.get_defining_op of %38 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %39 : !pdl.operation -> ^bb56, ^bb57
      ^bb57:
        pdl_interp.continue
      ^bb56:
        pdl_interp.check_operation_name of %39 is "arith.muli" -> ^bb58, ^bb57
      ^bb58:
        pdl_interp.check_operand_count of %39 is 2 -> ^bb59, ^bb57
      ^bb59:
        pdl_interp.check_result_count of %39 is 1 -> ^bb60, ^bb57
      ^bb60:
        %40 = pdl_interp.get_result 0 of %39
        pdl_interp.is_not_null %40 : !pdl.value -> ^bb61, ^bb57
      ^bb61:
        %41 = ematch.get_class_result %40
        pdl_interp.is_not_null %41 : !pdl.value -> ^bb62, ^bb57
      ^bb62:
        pdl_interp.are_equal %41, %27 : !pdl.value -> ^bb63, ^bb57
      ^bb63:
        %42 = ematch.get_class_vals %34
        pdl_interp.foreach %43 : !pdl.value in %42 {
          %44 = pdl_interp.get_defining_op of %43 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op"}
          pdl_interp.is_not_null %44 : !pdl.operation -> ^bb64, ^bb65
        ^bb65:
          pdl_interp.continue
        ^bb64:
          pdl_interp.check_operation_name of %44 is "arith.muli" -> ^bb66, ^bb65
        ^bb66:
          pdl_interp.check_operand_count of %44 is 2 -> ^bb67, ^bb65
        ^bb67:
          pdl_interp.check_result_count of %44 is 1 -> ^bb68, ^bb65
        ^bb68:
          %45 = pdl_interp.get_result 0 of %44
          pdl_interp.is_not_null %45 : !pdl.value -> ^bb69, ^bb65
        ^bb69:
          %46 = ematch.get_class_result %45
          pdl_interp.is_not_null %46 : !pdl.value -> ^bb70, ^bb65
        ^bb70:
          pdl_interp.are_equal %46, %34 : !pdl.value -> ^bb71, ^bb65
        ^bb71:
          %47 = ematch.get_class_vals %33
          pdl_interp.foreach %48 : !pdl.value in %47 {
            %49 = pdl_interp.get_defining_op of %48 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
            pdl_interp.is_not_null %49 : !pdl.operation -> ^bb72, ^bb73
          ^bb73:
            pdl_interp.continue
          ^bb72:
            pdl_interp.check_operation_name of %49 is "arith.muli" -> ^bb74, ^bb73
          ^bb74:
            pdl_interp.check_operand_count of %49 is 2 -> ^bb75, ^bb73
          ^bb75:
            pdl_interp.check_result_count of %49 is 1 -> ^bb76, ^bb73
          ^bb76:
            %50 = pdl_interp.get_operand 0 of %49
            pdl_interp.is_not_null %50 : !pdl.value -> ^bb77, ^bb73
          ^bb77:
            %51 = pdl_interp.get_operand 1 of %49
            pdl_interp.is_not_null %51 : !pdl.value -> ^bb78, ^bb73
          ^bb78:
            %52 = pdl_interp.get_result 0 of %49
            pdl_interp.is_not_null %52 : !pdl.value -> ^bb79, ^bb73
          ^bb79:
            %53 = ematch.get_class_result %52
            pdl_interp.is_not_null %53 : !pdl.value -> ^bb80, ^bb73
          ^bb80:
            pdl_interp.are_equal %53, %33 : !pdl.value -> ^bb81, ^bb73
          ^bb81:
            %54 = ematch.get_class_vals %50
            pdl_interp.foreach %55 : !pdl.value in %54 {
              %56 = pdl_interp.get_defining_op of %55 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
              pdl_interp.is_not_null %56 : !pdl.operation -> ^bb82, ^bb83
            ^bb83:
              pdl_interp.continue
            ^bb82:
              pdl_interp.check_operation_name of %56 is "arith.addi" -> ^bb84, ^bb83
            ^bb84:
              pdl_interp.check_operand_count of %56 is 2 -> ^bb85, ^bb83
            ^bb85:
              pdl_interp.check_result_count of %56 is 1 -> ^bb86, ^bb83
            ^bb86:
              %57 = pdl_interp.get_operand 0 of %56
              pdl_interp.is_not_null %57 : !pdl.value -> ^bb87, ^bb83
            ^bb87:
              %58 = pdl_interp.get_operand 1 of %56
              pdl_interp.is_not_null %58 : !pdl.value -> ^bb88, ^bb83
            ^bb88:
              %59 = pdl_interp.get_operand 0 of %44
              pdl_interp.are_equal %57, %59 : !pdl.value -> ^bb89, ^bb83
            ^bb89:
              %60 = pdl_interp.get_operand 0 of %39
              pdl_interp.are_equal %58, %60 : !pdl.value -> ^bb90, ^bb83
            ^bb90:
              pdl_interp.apply_constraint "is_arg_0"(%57 : !pdl.value) -> ^bb91, ^bb83
            ^bb91:
              pdl_interp.apply_constraint "is_arg_1"(%58 : !pdl.value) -> ^bb92, ^bb83
            ^bb92:
              %61 = pdl_interp.get_result 0 of %56
              pdl_interp.is_not_null %61 : !pdl.value -> ^bb93, ^bb83
            ^bb93:
              %62 = ematch.get_class_result %61
              pdl_interp.is_not_null %62 : !pdl.value -> ^bb94, ^bb83
            ^bb94:
              pdl_interp.are_equal %62, %50 : !pdl.value -> ^bb95, ^bb83
            ^bb95:
              %63 = pdl_interp.get_value_type of %57 : !pdl.type
              %64 = pdl_interp.get_value_type of %58 : !pdl.type
              pdl_interp.are_equal %63, %64 : !pdl.type -> ^bb96, ^bb83
            ^bb96:
              %65 = pdl_interp.get_value_type of %62 : !pdl.type
              pdl_interp.are_equal %63, %65 : !pdl.type -> ^bb97, ^bb83
            ^bb97:
              %66 = pdl_interp.get_value_type of %53 : !pdl.type
              pdl_interp.are_equal %63, %66 : !pdl.type -> ^bb98, ^bb83
            ^bb98:
              %67 = pdl_interp.get_value_type of %46 : !pdl.type
              pdl_interp.are_equal %63, %67 : !pdl.type -> ^bb99, ^bb83
            ^bb99:
              %68 = pdl_interp.get_value_type of %36 : !pdl.type
              pdl_interp.are_equal %63, %68 : !pdl.type -> ^bb100, ^bb83
            ^bb100:
              %69 = pdl_interp.get_value_type of %41 : !pdl.type
              pdl_interp.are_equal %63, %69 : !pdl.type -> ^bb101, ^bb83
            ^bb101:
              %70 = pdl_interp.get_value_type of %29 : !pdl.type
              pdl_interp.are_equal %63, %70 : !pdl.type -> ^bb102, ^bb83
            ^bb102:
              pdl_interp.check_type %63 is i8 -> ^bb103, ^bb83
            ^bb103:
              %71 = ematch.get_class_vals %51
              pdl_interp.foreach %72 : !pdl.value in %71 {
                %73 = pdl_interp.get_defining_op of %72 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op"}
                pdl_interp.is_not_null %73 : !pdl.operation -> ^bb104, ^bb105
              ^bb105:
                pdl_interp.continue
              ^bb104:
                pdl_interp.check_operation_name of %73 is "arith.addi" -> ^bb106, ^bb105
              ^bb106:
                pdl_interp.check_operand_count of %73 is 2 -> ^bb107, ^bb105
              ^bb107:
                pdl_interp.check_result_count of %73 is 1 -> ^bb108, ^bb105
              ^bb108:
                %74 = pdl_interp.get_operand 0 of %73
                pdl_interp.is_not_null %74 : !pdl.value -> ^bb109, ^bb105
              ^bb109:
                %75 = pdl_interp.get_operand 1 of %73
                pdl_interp.is_not_null %75 : !pdl.value -> ^bb110, ^bb105
              ^bb110:
                %76 = pdl_interp.get_operand 1 of %44
                pdl_interp.are_equal %74, %76 : !pdl.value -> ^bb111, ^bb105
              ^bb111:
                %77 = pdl_interp.get_operand 1 of %39
                pdl_interp.are_equal %75, %77 : !pdl.value -> ^bb112, ^bb105
              ^bb112:
                pdl_interp.apply_constraint "is_arg_2"(%74 : !pdl.value) -> ^bb113, ^bb105
              ^bb113:
                pdl_interp.apply_constraint "is_arg_3"(%75 : !pdl.value) -> ^bb114, ^bb105
              ^bb114:
                %78 = pdl_interp.get_result 0 of %73
                pdl_interp.is_not_null %78 : !pdl.value -> ^bb115, ^bb105
              ^bb115:
                %79 = ematch.get_class_result %78
                pdl_interp.is_not_null %79 : !pdl.value -> ^bb116, ^bb105
              ^bb116:
                pdl_interp.are_equal %79, %51 : !pdl.value -> ^bb117, ^bb105
              ^bb117:
                %80 = pdl_interp.get_value_type of %74 : !pdl.type
                pdl_interp.are_equal %63, %80 : !pdl.type -> ^bb118, ^bb105
              ^bb118:
                %81 = pdl_interp.get_value_type of %75 : !pdl.type
                pdl_interp.are_equal %63, %81 : !pdl.type -> ^bb119, ^bb105
              ^bb119:
                %82 = pdl_interp.get_value_type of %79 : !pdl.type
                pdl_interp.are_equal %63, %82 : !pdl.type -> ^bb120, ^bb105
              ^bb120:
                pdl_interp.record_match @rewriters::@KaratsubaToCrossTerm(%0 : !pdl.operation) : benefit(1), loc([]), root("arith.subi") -> ^bb105
              } -> ^bb83
            } -> ^bb73
          } -> ^bb65
        } -> ^bb57
      } -> ^bb47
    } -> ^bb2
  }
  builtin.module @rewriters {
    pdl_interp.func @CrossTermToKaratsuba(%0: !pdl.operation) {
      pdl_interp.apply_rewrite "rewriter"(%0 : !pdl.operation)
      pdl_interp.finalize
    }
    pdl_interp.func @KaratsubaToCrossTerm(%0: !pdl.operation) {
      pdl_interp.apply_rewrite "rewriter"(%0 : !pdl.operation)
      pdl_interp.finalize
    }
  }
