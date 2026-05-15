builtin.module {
  pdl_interp.func @matcher(%0 : !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["comb.shl", "comb.mul", "comb.mux", "comb.add", "comb.shru"](^bb0, ^bb1, ^bb2, ^bb3, ^bb4) -> ^bb5
  ^bb5:
    pdl_interp.finalize
  ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb6, ^bb5
  ^bb6:
    pdl_interp.check_result_count of %0 is 1 -> ^bb7, ^bb5
  ^bb7:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb8, ^bb5
  ^bb8:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb9, ^bb5
  ^bb9:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb10, ^bb5
  ^bb10:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb11, ^bb5
  ^bb11:
    %5 = ematch.get_class_vals %1
    pdl_interp.foreach %6 : !pdl.value in %5 {
      %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %7 : !pdl.operation -> ^bb12, ^bb13
    ^bb13:
      pdl_interp.continue
    ^bb12:
      pdl_interp.switch_operation_name of %7 to ["comb.mul", "comb.add", "comb.shl"](^bb14, ^bb15, ^bb16) -> ^bb13
    ^bb14:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb17, ^bb13
    ^bb17:
      pdl_interp.check_result_count of %7 is 1 -> ^bb18, ^bb13
    ^bb18:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb19, ^bb13
    ^bb19:
      %9 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb20, ^bb13
    ^bb20:
      %10 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb21, ^bb13
    ^bb21:
      %11 = ematch.get_class_result %10
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb22, ^bb13
    ^bb22:
      pdl_interp.are_equal %11, %1 : !pdl.value -> ^bb23, ^bb13
    ^bb23:
      %12 = pdl_interp.get_value_type of %8 : !pdl.type
      %13 = pdl_interp.get_value_type of %11 : !pdl.type
      pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb24, ^bb13
    ^bb24:
      %14 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %12, %14 : !pdl.type -> ^bb25, ^bb13
    ^bb25:
      %15 = pdl_interp.get_value_type of %9 : !pdl.type
      pdl_interp.are_equal %12, %15 : !pdl.type -> ^bb26, ^bb13
    ^bb26:
      %16 = ematch.get_class_representative %8
      %17 = ematch.get_class_representative %2
      %18 = ematch.get_class_representative %9
      pdl_interp.record_match @rewriters::@LeftShiftMult(%16, %17, %12, %18, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb13
    ^bb15:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb27, ^bb13
    ^bb27:
      pdl_interp.check_result_count of %7 is 1 -> ^bb28, ^bb13
    ^bb28:
      %19 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %19 : !pdl.value -> ^bb29, ^bb13
    ^bb29:
      %20 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %20 : !pdl.value -> ^bb30, ^bb13
    ^bb30:
      %21 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %21 : !pdl.value -> ^bb31, ^bb13
    ^bb31:
      %22 = ematch.get_class_result %21
      pdl_interp.is_not_null %22 : !pdl.value -> ^bb32, ^bb13
    ^bb32:
      pdl_interp.are_equal %22, %1 : !pdl.value -> ^bb33, ^bb13
    ^bb33:
      %23 = pdl_interp.get_value_type of %19 : !pdl.type
      %24 = pdl_interp.get_value_type of %22 : !pdl.type
      pdl_interp.are_equal %23, %24 : !pdl.type -> ^bb34, ^bb13
    ^bb34:
      %25 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %23, %25 : !pdl.type -> ^bb35, ^bb13
    ^bb35:
      %26 = pdl_interp.get_value_type of %20 : !pdl.type
      pdl_interp.are_equal %23, %26 : !pdl.type -> ^bb36, ^bb13
    ^bb36:
      %27 = ematch.get_class_representative %19
      %28 = ematch.get_class_representative %2
      %29 = ematch.get_class_representative %20
      pdl_interp.record_match @rewriters::@LeftShiftAdd(%27, %28, %23, %29, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb13
    ^bb16:
      pdl_interp.check_operand_count of %7 is 2 -> ^bb37, ^bb13
    ^bb37:
      pdl_interp.check_result_count of %7 is 1 -> ^bb38, ^bb13
    ^bb38:
      %30 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %30 : !pdl.value -> ^bb39, ^bb13
    ^bb39:
      %31 = pdl_interp.get_operand 1 of %7
      pdl_interp.is_not_null %31 : !pdl.value -> ^bb40, ^bb13
    ^bb40:
      %32 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %32 : !pdl.value -> ^bb41, ^bb13
    ^bb41:
      %33 = ematch.get_class_result %32
      pdl_interp.is_not_null %33 : !pdl.value -> ^bb42, ^bb13
    ^bb42:
      pdl_interp.are_equal %33, %1 : !pdl.value -> ^bb43, ^bb13
    ^bb43:
      %34 = pdl_interp.get_value_type of %30 : !pdl.type
      %35 = pdl_interp.get_value_type of %33 : !pdl.type
      pdl_interp.are_equal %34, %35 : !pdl.type -> ^bb44, ^bb13
    ^bb44:
      %36 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %34, %36 : !pdl.type -> ^bb45, ^bb13
    ^bb45:
      %37 = ematch.get_class_representative %31
      %38 = ematch.get_class_representative %2
      %39 = ematch.get_class_representative %30
      pdl_interp.record_match @rewriters::@MergeLeftShift(%37, %38, %34, %39, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shl") -> ^bb13
    } -> ^bb5
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb46, ^bb5
  ^bb46:
    pdl_interp.check_result_count of %0 is 1 -> ^bb47, ^bb5
  ^bb47:
    %40 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %40 : !pdl.value -> ^bb48, ^bb5
  ^bb48:
    %41 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %41 : !pdl.value -> ^bb49, ^bb5
  ^bb49:
    %42 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %42 : !pdl.value -> ^bb50, ^bb5
  ^bb50:
    %43 = ematch.get_class_result %42
    pdl_interp.is_not_null %43 : !pdl.value -> ^bb51, ^bb5
  ^bb51:
    %44 = pdl_interp.get_value_type of %40 : !pdl.type
    %45 = pdl_interp.get_value_type of %43 : !pdl.type
    pdl_interp.are_equal %44, %45 : !pdl.type -> ^bb52, ^bb53
  ^bb53:
    %46 = ematch.get_class_vals %40
    pdl_interp.foreach %47 : !pdl.value in %46 {
      %48 = pdl_interp.get_defining_op of %47 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %48 : !pdl.operation -> ^bb54, ^bb55
    ^bb55:
      pdl_interp.continue
    ^bb54:
      pdl_interp.check_operation_name of %48 is "comb.shl" -> ^bb56, ^bb55
    ^bb56:
      pdl_interp.check_operand_count of %48 is 2 -> ^bb57, ^bb55
    ^bb57:
      pdl_interp.check_result_count of %48 is 1 -> ^bb58, ^bb55
    ^bb58:
      %49 = pdl_interp.get_operand 0 of %48
      pdl_interp.is_not_null %49 : !pdl.value -> ^bb59, ^bb55
    ^bb59:
      %50 = pdl_interp.get_operand 1 of %48
      pdl_interp.is_not_null %50 : !pdl.value -> ^bb60, ^bb55
    ^bb60:
      %51 = pdl_interp.get_result 0 of %48
      pdl_interp.is_not_null %51 : !pdl.value -> ^bb61, ^bb55
    ^bb61:
      %52 = ematch.get_class_result %51
      pdl_interp.is_not_null %52 : !pdl.value -> ^bb62, ^bb55
    ^bb62:
      pdl_interp.are_equal %52, %40 : !pdl.value -> ^bb63, ^bb55
    ^bb63:
      %53 = pdl_interp.get_value_type of %49 : !pdl.type
      %54 = pdl_interp.get_value_type of %52 : !pdl.type
      pdl_interp.are_equal %53, %54 : !pdl.type -> ^bb64, ^bb55
    ^bb64:
      %55 = pdl_interp.get_value_type of %43 : !pdl.type
      pdl_interp.are_equal %53, %55 : !pdl.type -> ^bb65, ^bb55
    ^bb65:
      %56 = pdl_interp.get_value_type of %41 : !pdl.type
      pdl_interp.are_equal %53, %56 : !pdl.type -> ^bb66, ^bb55
    ^bb66:
      %57 = ematch.get_class_representative %49
      %58 = ematch.get_class_representative %41
      %59 = ematch.get_class_representative %50
      pdl_interp.record_match @rewriters::@LeftShiftMult1(%57, %58, %53, %59, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb55
    } -> ^bb5
  ^bb52:
    %60 = ematch.get_class_vals %41
    pdl_interp.foreach %61 : !pdl.value in %60 {
      %62 = pdl_interp.get_defining_op of %61 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %62 : !pdl.operation -> ^bb67, ^bb68
    ^bb68:
      pdl_interp.continue
    ^bb67:
      pdl_interp.check_operation_name of %62 is "comb.shl" -> ^bb69, ^bb68
    ^bb69:
      pdl_interp.check_operand_count of %62 is 2 -> ^bb70, ^bb68
    ^bb70:
      pdl_interp.check_result_count of %62 is 1 -> ^bb71, ^bb68
    ^bb71:
      %63 = pdl_interp.get_operand 0 of %62
      pdl_interp.is_not_null %63 : !pdl.value -> ^bb72, ^bb68
    ^bb72:
      %64 = pdl_interp.get_operand 1 of %62
      pdl_interp.is_not_null %64 : !pdl.value -> ^bb73, ^bb68
    ^bb73:
      %65 = pdl_interp.get_result 0 of %62
      pdl_interp.is_not_null %65 : !pdl.value -> ^bb74, ^bb68
    ^bb74:
      %66 = ematch.get_class_result %65
      pdl_interp.is_not_null %66 : !pdl.value -> ^bb75, ^bb68
    ^bb75:
      pdl_interp.are_equal %66, %41 : !pdl.value -> ^bb76, ^bb68
    ^bb76:
      %67 = pdl_interp.get_value_type of %63 : !pdl.type
      pdl_interp.are_equal %67, %44 : !pdl.type -> ^bb77, ^bb68
    ^bb77:
      %68 = pdl_interp.get_value_type of %66 : !pdl.type
      pdl_interp.are_equal %68, %44 : !pdl.type -> ^bb78, ^bb68
    ^bb78:
      %69 = ematch.get_class_representative %40
      %70 = ematch.get_class_representative %63
      %71 = ematch.get_class_representative %64
      pdl_interp.record_match @rewriters::@LeftShiftMult2(%69, %70, %44, %71, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb68
    } -> ^bb53
  ^bb2:
    pdl_interp.check_operand_count of %0 is 3 -> ^bb79, ^bb5
  ^bb79:
    pdl_interp.check_result_count of %0 is 1 -> ^bb80, ^bb5
  ^bb80:
    %72 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %72 : !pdl.value -> ^bb81, ^bb5
  ^bb81:
    %73 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %73 : !pdl.value -> ^bb82, ^bb5
  ^bb82:
    %74 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %74 : !pdl.value -> ^bb83, ^bb5
  ^bb83:
    %75 = ematch.get_class_result %74
    pdl_interp.is_not_null %75 : !pdl.value -> ^bb84, ^bb5
  ^bb84:
    %76 = pdl_interp.get_operand 2 of %0
    pdl_interp.is_not_null %76 : !pdl.value -> ^bb85, ^bb86
  ^bb86:
    %77 = pdl_interp.get_operand 2 of %0
    pdl_interp.are_equal %73, %77 : !pdl.value -> ^bb87, ^bb88
  ^bb88:
    %78 = ematch.get_class_vals %73
    pdl_interp.foreach %79 : !pdl.value in %78 {
      %80 = pdl_interp.get_defining_op of %79 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %80 : !pdl.operation -> ^bb89, ^bb90
    ^bb90:
      pdl_interp.continue
    ^bb89:
      pdl_interp.check_operation_name of %80 is "comb.add" -> ^bb91, ^bb90
    ^bb91:
      pdl_interp.check_operand_count of %80 is 2 -> ^bb92, ^bb90
    ^bb92:
      pdl_interp.check_result_count of %80 is 1 -> ^bb93, ^bb90
    ^bb93:
      %81 = pdl_interp.get_operand 0 of %80
      pdl_interp.is_not_null %81 : !pdl.value -> ^bb94, ^bb90
    ^bb94:
      %82 = pdl_interp.get_operand 1 of %80
      pdl_interp.is_not_null %82 : !pdl.value -> ^bb95, ^bb90
    ^bb95:
      %83 = pdl_interp.get_result 0 of %80
      pdl_interp.is_not_null %83 : !pdl.value -> ^bb96, ^bb90
    ^bb96:
      %84 = ematch.get_class_result %83
      pdl_interp.is_not_null %84 : !pdl.value -> ^bb97, ^bb90
    ^bb97:
      pdl_interp.are_equal %84, %73 : !pdl.value -> ^bb98, ^bb90
    ^bb98:
      %85 = pdl_interp.get_value_type of %84 : !pdl.type
      %86 = pdl_interp.get_value_type of %75 : !pdl.type
      pdl_interp.are_equal %85, %86 : !pdl.type -> ^bb99, ^bb90
    ^bb99:
      %87 = pdl_interp.get_operand 2 of %0
      pdl_interp.are_equal %81, %87 : !pdl.value -> ^bb100, ^bb90
    ^bb100:
      %88 = ematch.get_class_representative %72
      %89 = ematch.get_class_representative %82
      %90 = ematch.get_class_representative %81
      pdl_interp.record_match @rewriters::@SelAddLeft(%0, %88, %89, %85, %90 : !pdl.operation, !pdl.value, !pdl.value, !pdl.type, !pdl.value) : benefit(1), loc([]), root("comb.mux") -> ^bb90
    } -> ^bb5
  ^bb87:
    %91 = ematch.get_class_representative %73
    pdl_interp.record_match @rewriters::@SelSame(%91, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb88
  ^bb85:
    %92 = ematch.get_class_vals %73
    pdl_interp.foreach %93 : !pdl.value in %92 {
      %94 = pdl_interp.get_defining_op of %93 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %94 : !pdl.operation -> ^bb101, ^bb102
    ^bb102:
      pdl_interp.continue
    ^bb101:
      pdl_interp.switch_operation_name of %94 to ["comb.mul", "comb.add"](^bb103, ^bb104) -> ^bb102
    ^bb103:
      pdl_interp.check_operand_count of %94 is 2 -> ^bb105, ^bb102
    ^bb105:
      pdl_interp.check_result_count of %94 is 1 -> ^bb106, ^bb102
    ^bb106:
      %95 = pdl_interp.get_operand 0 of %94
      pdl_interp.is_not_null %95 : !pdl.value -> ^bb107, ^bb102
    ^bb107:
      %96 = pdl_interp.get_operand 1 of %94
      pdl_interp.is_not_null %96 : !pdl.value -> ^bb108, ^bb102
    ^bb108:
      %97 = pdl_interp.get_result 0 of %94
      pdl_interp.is_not_null %97 : !pdl.value -> ^bb109, ^bb102
    ^bb109:
      %98 = ematch.get_class_result %97
      pdl_interp.is_not_null %98 : !pdl.value -> ^bb110, ^bb102
    ^bb110:
      pdl_interp.are_equal %98, %73 : !pdl.value -> ^bb111, ^bb102
    ^bb111:
      %99 = pdl_interp.get_value_type of %98 : !pdl.type
      %100 = pdl_interp.get_value_type of %75 : !pdl.type
      pdl_interp.are_equal %99, %100 : !pdl.type -> ^bb112, ^bb102
    ^bb112:
      %101 = ematch.get_class_vals %76
      pdl_interp.foreach %102 : !pdl.value in %101 {
        %103 = pdl_interp.get_defining_op of %102 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %103 : !pdl.operation -> ^bb113, ^bb114
      ^bb114:
        pdl_interp.continue
      ^bb113:
        pdl_interp.check_operation_name of %103 is "comb.mul" -> ^bb115, ^bb114
      ^bb115:
        pdl_interp.check_operand_count of %103 is 2 -> ^bb116, ^bb114
      ^bb116:
        pdl_interp.check_result_count of %103 is 1 -> ^bb117, ^bb114
      ^bb117:
        %104 = pdl_interp.get_operand 1 of %103
        pdl_interp.is_not_null %104 : !pdl.value -> ^bb118, ^bb114
      ^bb118:
        %105 = pdl_interp.get_result 0 of %103
        pdl_interp.is_not_null %105 : !pdl.value -> ^bb119, ^bb114
      ^bb119:
        %106 = ematch.get_class_result %105
        pdl_interp.is_not_null %106 : !pdl.value -> ^bb120, ^bb114
      ^bb120:
        pdl_interp.are_equal %106, %76 : !pdl.value -> ^bb121, ^bb114
      ^bb121:
        %107 = pdl_interp.get_value_type of %106 : !pdl.type
        pdl_interp.are_equal %99, %107 : !pdl.type -> ^bb122, ^bb114
      ^bb122:
        %108 = pdl_interp.get_operand 0 of %103
        pdl_interp.are_equal %95, %108 : !pdl.value -> ^bb123, ^bb114
      ^bb123:
        %109 = ematch.get_class_representative %72
        %110 = ematch.get_class_representative %96
        %111 = ematch.get_class_representative %104
        %112 = ematch.get_class_representative %95
        pdl_interp.record_match @rewriters::@SelMul(%109, %110, %111, %99, %112, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb114
      } -> ^bb102
    ^bb104:
      pdl_interp.check_operand_count of %94 is 2 -> ^bb124, ^bb102
    ^bb124:
      pdl_interp.check_result_count of %94 is 1 -> ^bb125, ^bb102
    ^bb125:
      %113 = pdl_interp.get_operand 0 of %94
      pdl_interp.is_not_null %113 : !pdl.value -> ^bb126, ^bb102
    ^bb126:
      %114 = pdl_interp.get_operand 1 of %94
      pdl_interp.is_not_null %114 : !pdl.value -> ^bb127, ^bb102
    ^bb127:
      %115 = pdl_interp.get_result 0 of %94
      pdl_interp.is_not_null %115 : !pdl.value -> ^bb128, ^bb102
    ^bb128:
      %116 = ematch.get_class_result %115
      pdl_interp.is_not_null %116 : !pdl.value -> ^bb129, ^bb102
    ^bb129:
      pdl_interp.are_equal %116, %73 : !pdl.value -> ^bb130, ^bb102
    ^bb130:
      %117 = pdl_interp.get_value_type of %116 : !pdl.type
      %118 = pdl_interp.get_value_type of %75 : !pdl.type
      pdl_interp.are_equal %117, %118 : !pdl.type -> ^bb131, ^bb102
    ^bb131:
      %119 = ematch.get_class_vals %76
      pdl_interp.foreach %120 : !pdl.value in %119 {
        %121 = pdl_interp.get_defining_op of %120 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %121 : !pdl.operation -> ^bb132, ^bb133
      ^bb133:
        pdl_interp.continue
      ^bb132:
        pdl_interp.check_operation_name of %121 is "comb.add" -> ^bb134, ^bb133
      ^bb134:
        pdl_interp.check_operand_count of %121 is 2 -> ^bb135, ^bb133
      ^bb135:
        pdl_interp.check_result_count of %121 is 1 -> ^bb136, ^bb133
      ^bb136:
        %122 = pdl_interp.get_operand 1 of %121
        pdl_interp.is_not_null %122 : !pdl.value -> ^bb137, ^bb133
      ^bb137:
        %123 = pdl_interp.get_result 0 of %121
        pdl_interp.is_not_null %123 : !pdl.value -> ^bb138, ^bb133
      ^bb138:
        %124 = ematch.get_class_result %123
        pdl_interp.is_not_null %124 : !pdl.value -> ^bb139, ^bb133
      ^bb139:
        pdl_interp.are_equal %124, %76 : !pdl.value -> ^bb140, ^bb133
      ^bb140:
        %125 = pdl_interp.get_value_type of %124 : !pdl.type
        pdl_interp.are_equal %117, %125 : !pdl.type -> ^bb141, ^bb133
      ^bb141:
        %126 = pdl_interp.get_operand 0 of %121
        pdl_interp.is_not_null %126 : !pdl.value -> ^bb142, ^bb133
      ^bb142:
        %127 = ematch.get_class_representative %72
        %128 = ematch.get_class_representative %113
        %129 = ematch.get_class_representative %126
        %130 = ematch.get_class_representative %114
        %131 = ematch.get_class_representative %122
        pdl_interp.record_match @rewriters::@SelAdd(%127, %128, %129, %117, %130, %131, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb133
      } -> ^bb102
    } -> ^bb86
  ^bb3:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb143, ^bb5
  ^bb143:
    pdl_interp.check_result_count of %0 is 1 -> ^bb144, ^bb5
  ^bb144:
    %132 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %132 : !pdl.value -> ^bb145, ^bb5
  ^bb145:
    %133 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %133 : !pdl.value -> ^bb146, ^bb5
  ^bb146:
    %134 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %134 : !pdl.value -> ^bb147, ^bb5
  ^bb147:
    %135 = ematch.get_class_result %134
    pdl_interp.is_not_null %135 : !pdl.value -> ^bb148, ^bb5
  ^bb148:
    %136 = ematch.get_class_vals %132
    pdl_interp.foreach %137 : !pdl.value in %136 {
      %138 = pdl_interp.get_defining_op of %137 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %138 : !pdl.operation -> ^bb149, ^bb150
    ^bb150:
      pdl_interp.continue
    ^bb149:
      pdl_interp.switch_operation_name of %138 to ["comb.shru", "comb.add"](^bb151, ^bb152) -> ^bb150
    ^bb151:
      pdl_interp.check_operand_count of %138 is 2 -> ^bb153, ^bb150
    ^bb153:
      pdl_interp.check_result_count of %138 is 1 -> ^bb154, ^bb150
    ^bb154:
      %139 = pdl_interp.get_operand 0 of %138
      pdl_interp.is_not_null %139 : !pdl.value -> ^bb155, ^bb150
    ^bb155:
      %140 = pdl_interp.get_operand 1 of %138
      pdl_interp.is_not_null %140 : !pdl.value -> ^bb156, ^bb150
    ^bb156:
      %141 = pdl_interp.get_result 0 of %138
      pdl_interp.is_not_null %141 : !pdl.value -> ^bb157, ^bb150
    ^bb157:
      %142 = ematch.get_class_result %141
      pdl_interp.is_not_null %142 : !pdl.value -> ^bb158, ^bb150
    ^bb158:
      pdl_interp.are_equal %142, %132 : !pdl.value -> ^bb159, ^bb150
    ^bb159:
      %143 = pdl_interp.get_value_type of %139 : !pdl.type
      %144 = pdl_interp.get_value_type of %142 : !pdl.type
      pdl_interp.are_equal %143, %144 : !pdl.type -> ^bb160, ^bb150
    ^bb160:
      %145 = pdl_interp.get_value_type of %135 : !pdl.type
      pdl_interp.are_equal %143, %145 : !pdl.type -> ^bb161, ^bb150
    ^bb161:
      %146 = pdl_interp.get_value_type of %133 : !pdl.type
      pdl_interp.are_equal %143, %146 : !pdl.type -> ^bb162, ^bb150
    ^bb162:
      %147 = ematch.get_class_representative %133
      %148 = ematch.get_class_representative %140
      %149 = ematch.get_class_representative %139
      pdl_interp.record_match @rewriters::@AddRightShift(%147, %148, %143, %149, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    ^bb152:
      pdl_interp.switch_operand_count of %138 to dense<[2, 3]> : vector<2xi32>(^bb163, ^bb164) -> ^bb150
    ^bb163:
      pdl_interp.check_result_count of %138 is 1 -> ^bb165, ^bb150
    ^bb165:
      %150 = pdl_interp.get_operand 0 of %138
      pdl_interp.is_not_null %150 : !pdl.value -> ^bb166, ^bb150
    ^bb166:
      %151 = pdl_interp.get_operand 1 of %138
      pdl_interp.is_not_null %151 : !pdl.value -> ^bb167, ^bb150
    ^bb167:
      %152 = pdl_interp.get_result 0 of %138
      pdl_interp.is_not_null %152 : !pdl.value -> ^bb168, ^bb150
    ^bb168:
      %153 = ematch.get_class_result %152
      pdl_interp.is_not_null %153 : !pdl.value -> ^bb169, ^bb150
    ^bb169:
      pdl_interp.are_equal %153, %132 : !pdl.value -> ^bb170, ^bb150
    ^bb170:
      %154 = pdl_interp.get_value_type of %150 : !pdl.type
      %155 = pdl_interp.get_value_type of %153 : !pdl.type
      pdl_interp.are_equal %154, %155 : !pdl.type -> ^bb171, ^bb150
    ^bb171:
      %156 = pdl_interp.get_value_type of %135 : !pdl.type
      pdl_interp.are_equal %154, %156 : !pdl.type -> ^bb172, ^bb150
    ^bb172:
      %157 = pdl_interp.get_value_type of %151 : !pdl.type
      pdl_interp.are_equal %154, %157 : !pdl.type -> ^bb173, ^bb150
    ^bb173:
      %158 = pdl_interp.get_value_type of %133 : !pdl.type
      pdl_interp.are_equal %154, %158 : !pdl.type -> ^bb174, ^bb150
    ^bb174:
      %159 = ematch.get_class_representative %150
      %160 = ematch.get_class_representative %151
      %161 = ematch.get_class_representative %133
      pdl_interp.record_match @rewriters::@MergeAdd3(%159, %160, %161, %154, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    ^bb164:
      pdl_interp.check_result_count of %138 is 1 -> ^bb175, ^bb150
    ^bb175:
      %162 = pdl_interp.get_operand 0 of %138
      pdl_interp.is_not_null %162 : !pdl.value -> ^bb176, ^bb150
    ^bb176:
      %163 = pdl_interp.get_operand 1 of %138
      pdl_interp.is_not_null %163 : !pdl.value -> ^bb177, ^bb150
    ^bb177:
      %164 = pdl_interp.get_result 0 of %138
      pdl_interp.is_not_null %164 : !pdl.value -> ^bb178, ^bb150
    ^bb178:
      %165 = ematch.get_class_result %164
      pdl_interp.is_not_null %165 : !pdl.value -> ^bb179, ^bb150
    ^bb179:
      pdl_interp.are_equal %165, %132 : !pdl.value -> ^bb180, ^bb150
    ^bb180:
      %166 = pdl_interp.get_value_type of %162 : !pdl.type
      %167 = pdl_interp.get_value_type of %165 : !pdl.type
      pdl_interp.are_equal %166, %167 : !pdl.type -> ^bb181, ^bb150
    ^bb181:
      %168 = pdl_interp.get_value_type of %135 : !pdl.type
      pdl_interp.are_equal %166, %168 : !pdl.type -> ^bb182, ^bb150
    ^bb182:
      %169 = pdl_interp.get_value_type of %163 : !pdl.type
      pdl_interp.are_equal %166, %169 : !pdl.type -> ^bb183, ^bb150
    ^bb183:
      %170 = pdl_interp.get_value_type of %133 : !pdl.type
      pdl_interp.are_equal %166, %170 : !pdl.type -> ^bb184, ^bb150
    ^bb184:
      %171 = pdl_interp.get_operand 2 of %138
      pdl_interp.is_not_null %171 : !pdl.value -> ^bb185, ^bb150
    ^bb185:
      %172 = pdl_interp.get_value_type of %171 : !pdl.type
      pdl_interp.are_equal %166, %172 : !pdl.type -> ^bb186, ^bb150
    ^bb186:
      %173 = ematch.get_class_representative %162
      %174 = ematch.get_class_representative %163
      %175 = ematch.get_class_representative %171
      %176 = ematch.get_class_representative %133
      pdl_interp.record_match @rewriters::@MergeAdd4(%173, %174, %175, %176, %166, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    } -> ^bb5
  ^bb4:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb187, ^bb5
  ^bb187:
    pdl_interp.check_result_count of %0 is 1 -> ^bb188, ^bb5
  ^bb188:
    %177 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %177 : !pdl.value -> ^bb189, ^bb5
  ^bb189:
    %178 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %178 : !pdl.value -> ^bb190, ^bb5
  ^bb190:
    %179 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %179 : !pdl.value -> ^bb191, ^bb5
  ^bb191:
    %180 = ematch.get_class_result %179
    pdl_interp.is_not_null %180 : !pdl.value -> ^bb192, ^bb5
  ^bb192:
    %181 = ematch.get_class_vals %177
    pdl_interp.foreach %182 : !pdl.value in %181 {
      %183 = pdl_interp.get_defining_op of %182 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %183 : !pdl.operation -> ^bb193, ^bb194
    ^bb194:
      pdl_interp.continue
    ^bb193:
      pdl_interp.check_operation_name of %183 is "comb.shru" -> ^bb195, ^bb194
    ^bb195:
      pdl_interp.check_operand_count of %183 is 2 -> ^bb196, ^bb194
    ^bb196:
      pdl_interp.check_result_count of %183 is 1 -> ^bb197, ^bb194
    ^bb197:
      %184 = pdl_interp.get_operand 0 of %183
      pdl_interp.is_not_null %184 : !pdl.value -> ^bb198, ^bb194
    ^bb198:
      %185 = pdl_interp.get_operand 1 of %183
      pdl_interp.is_not_null %185 : !pdl.value -> ^bb199, ^bb194
    ^bb199:
      %186 = pdl_interp.get_result 0 of %183
      pdl_interp.is_not_null %186 : !pdl.value -> ^bb200, ^bb194
    ^bb200:
      %187 = ematch.get_class_result %186
      pdl_interp.is_not_null %187 : !pdl.value -> ^bb201, ^bb194
    ^bb201:
      pdl_interp.are_equal %187, %177 : !pdl.value -> ^bb202, ^bb194
    ^bb202:
      %188 = pdl_interp.get_value_type of %184 : !pdl.type
      %189 = pdl_interp.get_value_type of %187 : !pdl.type
      pdl_interp.are_equal %188, %189 : !pdl.type -> ^bb203, ^bb194
    ^bb203:
      %190 = pdl_interp.get_value_type of %180 : !pdl.type
      pdl_interp.are_equal %188, %190 : !pdl.type -> ^bb204, ^bb194
    ^bb204:
      %191 = ematch.get_class_representative %185
      %192 = ematch.get_class_representative %178
      %193 = ematch.get_class_representative %184
      pdl_interp.record_match @rewriters::@MergeRightShift(%191, %192, %188, %193, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shru") -> ^bb194
    } -> ^bb5
  }
  builtin.module @rewriters {
    pdl_interp.func @LeftShiftMult(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
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
    pdl_interp.func @LeftShiftAdd(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
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
    pdl_interp.func @MergeLeftShift(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.add"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.shl"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @LeftShiftMult1(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.mul"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.shl"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @LeftShiftMult2(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.mul"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.shl"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelAddLeft(%0 : !pdl.operation, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.type, %4 : !pdl.value) {
      %5 = pdl_interp.apply_rewrite "BuildZero"(%0 : !pdl.operation) : !pdl.operation
      %6 = ematch.dedup %5
      %7 = pdl_interp.get_result 0 of %6
      %8 = ematch.get_class_result %7
      %9 = ematch.get_class_result %1
      %10 = ematch.get_class_result %2
      %11 = pdl_interp.create_operation "comb.mux"(%9, %10, %8 : !pdl.value, !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %12 = ematch.dedup %11
      %13 = pdl_interp.get_result 0 of %12
      %14 = ematch.get_class_result %13
      %15 = ematch.get_class_result %4
      %16 = pdl_interp.create_operation "comb.add"(%15, %14 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %17 = ematch.dedup %16
      %18 = pdl_interp.get_results of %17 : !pdl.range<value>
      %19 = ematch.get_class_results %18
      ematch.union %0 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelSame(%0 : !pdl.value, %1 : !pdl.operation) {
      %2 = ematch.get_class_result %0
      %3 = pdl_interp.create_range %2 : !pdl.value
      ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelMul(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.type, %4 : !pdl.value, %5 : !pdl.operation) {
      %6 = ematch.get_class_result %0
      %7 = ematch.get_class_result %1
      %8 = ematch.get_class_result %2
      %9 = pdl_interp.create_operation "comb.mux"(%6, %7, %8 : !pdl.value, !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %10 = ematch.dedup %9
      %11 = pdl_interp.get_result 0 of %10
      %12 = ematch.get_class_result %11
      %13 = ematch.get_class_result %4
      %14 = pdl_interp.create_operation "comb.mul"(%13, %12 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %15 = ematch.dedup %14
      %16 = pdl_interp.get_results of %15 : !pdl.range<value>
      %17 = ematch.get_class_results %16
      ematch.union %5 : !pdl.operation, %17 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelAdd(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.type, %4 : !pdl.value, %5 : !pdl.value, %6 : !pdl.operation) {
      %7 = ematch.get_class_result %0
      %8 = ematch.get_class_result %1
      %9 = ematch.get_class_result %2
      %10 = pdl_interp.create_operation "comb.mux"(%7, %8, %9 : !pdl.value, !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %11 = ematch.dedup %10
      %12 = ematch.get_class_result %4
      %13 = ematch.get_class_result %5
      %14 = pdl_interp.create_operation "comb.mux"(%7, %12, %13 : !pdl.value, !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %15 = ematch.dedup %14
      %16 = pdl_interp.get_result 0 of %11
      %17 = ematch.get_class_result %16
      %18 = pdl_interp.get_result 0 of %15
      %19 = ematch.get_class_result %18
      %20 = pdl_interp.create_operation "comb.add"(%17, %19 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %21 = ematch.dedup %20
      %22 = pdl_interp.get_results of %21 : !pdl.range<value>
      %23 = ematch.get_class_results %22
      ematch.union %6 : !pdl.operation, %23 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AddRightShift(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.shl"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.add"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_result 0 of %13
      %15 = ematch.get_class_result %14
      %16 = pdl_interp.create_operation "comb.shru"(%15, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %17 = ematch.dedup %16
      %18 = pdl_interp.get_results of %17 : !pdl.range<value>
      %19 = ematch.get_class_results %18
      ematch.union %4 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MergeAdd3(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.type, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = ematch.get_class_result %2
      %8 = pdl_interp.create_operation "comb.add"(%5, %6, %7 : !pdl.value, !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %9 = ematch.dedup %8
      %10 = pdl_interp.get_results of %9 : !pdl.range<value>
      %11 = ematch.get_class_results %10
      ematch.union %4 : !pdl.operation, %11 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MergeAdd4(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.value, %3 : !pdl.value, %4 : !pdl.type, %5 : !pdl.operation) {
      %6 = ematch.get_class_result %0
      %7 = ematch.get_class_result %1
      %8 = ematch.get_class_result %2
      %9 = ematch.get_class_result %3
      %10 = pdl_interp.create_operation "comb.add"(%6, %7, %8, %9 : !pdl.value, !pdl.value, !pdl.value, !pdl.value) -> (%4 : !pdl.type)
      %11 = ematch.dedup %10
      %12 = pdl_interp.get_results of %11 : !pdl.range<value>
      %13 = ematch.get_class_results %12
      ematch.union %5 : !pdl.operation, %13 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MergeRightShift(%0 : !pdl.value, %1 : !pdl.value, %2 : !pdl.type, %3 : !pdl.value, %4 : !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "comb.add"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "comb.shru"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}

