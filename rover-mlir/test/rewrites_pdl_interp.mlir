builtin.module {
  pdl_interp.func @matcher(%0: !pdl.operation) {
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
    %44 = pdl_interp.get_value_type of %43 : !pdl.type
    pdl_interp.record_match @rewriters::@MulToPartialProductTree(%0, %44 : !pdl.operation, !pdl.type) : benefit(1), loc([]), root("comb.mul") -> ^bb52
  ^bb52:
    %45 = pdl_interp.get_value_type of %40 : !pdl.type
    %46 = pdl_interp.get_value_type of %43 : !pdl.type
    pdl_interp.are_equal %45, %46 : !pdl.type -> ^bb53, ^bb54
  ^bb54:
    %47 = ematch.get_class_vals %40
    pdl_interp.foreach %48 : !pdl.value in %47 {
      %49 = pdl_interp.get_defining_op of %48 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %49 : !pdl.operation -> ^bb55, ^bb56
    ^bb56:
      pdl_interp.continue
    ^bb55:
      pdl_interp.check_operation_name of %49 is "comb.shl" -> ^bb57, ^bb56
    ^bb57:
      pdl_interp.check_operand_count of %49 is 2 -> ^bb58, ^bb56
    ^bb58:
      pdl_interp.check_result_count of %49 is 1 -> ^bb59, ^bb56
    ^bb59:
      %50 = pdl_interp.get_operand 0 of %49
      pdl_interp.is_not_null %50 : !pdl.value -> ^bb60, ^bb56
    ^bb60:
      %51 = pdl_interp.get_operand 1 of %49
      pdl_interp.is_not_null %51 : !pdl.value -> ^bb61, ^bb56
    ^bb61:
      %52 = pdl_interp.get_result 0 of %49
      pdl_interp.is_not_null %52 : !pdl.value -> ^bb62, ^bb56
    ^bb62:
      %53 = ematch.get_class_result %52
      pdl_interp.is_not_null %53 : !pdl.value -> ^bb63, ^bb56
    ^bb63:
      pdl_interp.are_equal %53, %40 : !pdl.value -> ^bb64, ^bb56
    ^bb64:
      %54 = pdl_interp.get_value_type of %50 : !pdl.type
      %55 = pdl_interp.get_value_type of %53 : !pdl.type
      pdl_interp.are_equal %54, %55 : !pdl.type -> ^bb65, ^bb56
    ^bb65:
      %56 = pdl_interp.get_value_type of %43 : !pdl.type
      pdl_interp.are_equal %54, %56 : !pdl.type -> ^bb66, ^bb56
    ^bb66:
      %57 = pdl_interp.get_value_type of %41 : !pdl.type
      pdl_interp.are_equal %54, %57 : !pdl.type -> ^bb67, ^bb56
    ^bb67:
      %58 = ematch.get_class_representative %50
      %59 = ematch.get_class_representative %41
      %60 = ematch.get_class_representative %51
      pdl_interp.record_match @rewriters::@LeftShiftMult1(%58, %59, %54, %60, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb56
    } -> ^bb5
  ^bb53:
    %61 = ematch.get_class_vals %41
    pdl_interp.foreach %62 : !pdl.value in %61 {
      %63 = pdl_interp.get_defining_op of %62 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %63 : !pdl.operation -> ^bb68, ^bb69
    ^bb69:
      pdl_interp.continue
    ^bb68:
      pdl_interp.check_operation_name of %63 is "comb.shl" -> ^bb70, ^bb69
    ^bb70:
      pdl_interp.check_operand_count of %63 is 2 -> ^bb71, ^bb69
    ^bb71:
      pdl_interp.check_result_count of %63 is 1 -> ^bb72, ^bb69
    ^bb72:
      %64 = pdl_interp.get_operand 0 of %63
      pdl_interp.is_not_null %64 : !pdl.value -> ^bb73, ^bb69
    ^bb73:
      %65 = pdl_interp.get_operand 1 of %63
      pdl_interp.is_not_null %65 : !pdl.value -> ^bb74, ^bb69
    ^bb74:
      %66 = pdl_interp.get_result 0 of %63
      pdl_interp.is_not_null %66 : !pdl.value -> ^bb75, ^bb69
    ^bb75:
      %67 = ematch.get_class_result %66
      pdl_interp.is_not_null %67 : !pdl.value -> ^bb76, ^bb69
    ^bb76:
      pdl_interp.are_equal %67, %41 : !pdl.value -> ^bb77, ^bb69
    ^bb77:
      %68 = pdl_interp.get_value_type of %64 : !pdl.type
      pdl_interp.are_equal %68, %45 : !pdl.type -> ^bb78, ^bb69
    ^bb78:
      %69 = pdl_interp.get_value_type of %67 : !pdl.type
      pdl_interp.are_equal %69, %45 : !pdl.type -> ^bb79, ^bb69
    ^bb79:
      %70 = ematch.get_class_representative %40
      %71 = ematch.get_class_representative %64
      %72 = ematch.get_class_representative %65
      pdl_interp.record_match @rewriters::@LeftShiftMult2(%70, %71, %45, %72, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mul") -> ^bb69
    } -> ^bb54
  ^bb2:
    pdl_interp.check_operand_count of %0 is 3 -> ^bb80, ^bb5
  ^bb80:
    pdl_interp.check_result_count of %0 is 1 -> ^bb81, ^bb5
  ^bb81:
    %73 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %73 : !pdl.value -> ^bb82, ^bb5
  ^bb82:
    %74 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %74 : !pdl.value -> ^bb83, ^bb5
  ^bb83:
    %75 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %75 : !pdl.value -> ^bb84, ^bb5
  ^bb84:
    %76 = ematch.get_class_result %75
    pdl_interp.is_not_null %76 : !pdl.value -> ^bb85, ^bb5
  ^bb85:
    %77 = pdl_interp.get_operand 2 of %0
    pdl_interp.is_not_null %77 : !pdl.value -> ^bb86, ^bb87
  ^bb87:
    %78 = pdl_interp.get_operand 2 of %0
    pdl_interp.are_equal %74, %78 : !pdl.value -> ^bb88, ^bb89
  ^bb89:
    %79 = ematch.get_class_vals %74
    pdl_interp.foreach %80 : !pdl.value in %79 {
      %81 = pdl_interp.get_defining_op of %80 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %81 : !pdl.operation -> ^bb90, ^bb91
    ^bb91:
      pdl_interp.continue
    ^bb90:
      pdl_interp.check_operation_name of %81 is "comb.add" -> ^bb92, ^bb91
    ^bb92:
      pdl_interp.check_operand_count of %81 is 2 -> ^bb93, ^bb91
    ^bb93:
      pdl_interp.check_result_count of %81 is 1 -> ^bb94, ^bb91
    ^bb94:
      %82 = pdl_interp.get_operand 0 of %81
      pdl_interp.is_not_null %82 : !pdl.value -> ^bb95, ^bb91
    ^bb95:
      %83 = pdl_interp.get_operand 1 of %81
      pdl_interp.is_not_null %83 : !pdl.value -> ^bb96, ^bb91
    ^bb96:
      %84 = pdl_interp.get_result 0 of %81
      pdl_interp.is_not_null %84 : !pdl.value -> ^bb97, ^bb91
    ^bb97:
      %85 = ematch.get_class_result %84
      pdl_interp.is_not_null %85 : !pdl.value -> ^bb98, ^bb91
    ^bb98:
      pdl_interp.are_equal %85, %74 : !pdl.value -> ^bb99, ^bb91
    ^bb99:
      %86 = pdl_interp.get_value_type of %85 : !pdl.type
      %87 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %86, %87 : !pdl.type -> ^bb100, ^bb91
    ^bb100:
      %88 = pdl_interp.get_operand 2 of %0
      pdl_interp.are_equal %82, %88 : !pdl.value -> ^bb101, ^bb91
    ^bb101:
      %89 = ematch.get_class_representative %73
      %90 = ematch.get_class_representative %83
      %91 = ematch.get_class_representative %82
      pdl_interp.record_match @rewriters::@SelAddLeft(%0, %89, %90, %86, %91 : !pdl.operation, !pdl.value, !pdl.value, !pdl.type, !pdl.value) : benefit(1), loc([]), root("comb.mux") -> ^bb91
    } -> ^bb5
  ^bb88:
    %92 = ematch.get_class_representative %74
    pdl_interp.record_match @rewriters::@SelSame(%92, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb89
  ^bb86:
    %93 = ematch.get_class_vals %74
    pdl_interp.foreach %94 : !pdl.value in %93 {
      %95 = pdl_interp.get_defining_op of %94 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %95 : !pdl.operation -> ^bb102, ^bb103
    ^bb103:
      pdl_interp.continue
    ^bb102:
      pdl_interp.switch_operation_name of %95 to ["comb.mul", "comb.add"](^bb104, ^bb105) -> ^bb103
    ^bb104:
      pdl_interp.check_operand_count of %95 is 2 -> ^bb106, ^bb103
    ^bb106:
      pdl_interp.check_result_count of %95 is 1 -> ^bb107, ^bb103
    ^bb107:
      %96 = pdl_interp.get_operand 0 of %95
      pdl_interp.is_not_null %96 : !pdl.value -> ^bb108, ^bb103
    ^bb108:
      %97 = pdl_interp.get_operand 1 of %95
      pdl_interp.is_not_null %97 : !pdl.value -> ^bb109, ^bb103
    ^bb109:
      %98 = pdl_interp.get_result 0 of %95
      pdl_interp.is_not_null %98 : !pdl.value -> ^bb110, ^bb103
    ^bb110:
      %99 = ematch.get_class_result %98
      pdl_interp.is_not_null %99 : !pdl.value -> ^bb111, ^bb103
    ^bb111:
      pdl_interp.are_equal %99, %74 : !pdl.value -> ^bb112, ^bb103
    ^bb112:
      %100 = pdl_interp.get_value_type of %99 : !pdl.type
      %101 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %100, %101 : !pdl.type -> ^bb113, ^bb103
    ^bb113:
      %102 = ematch.get_class_vals %77
      pdl_interp.foreach %103 : !pdl.value in %102 {
        %104 = pdl_interp.get_defining_op of %103 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %104 : !pdl.operation -> ^bb114, ^bb115
      ^bb115:
        pdl_interp.continue
      ^bb114:
        pdl_interp.check_operation_name of %104 is "comb.mul" -> ^bb116, ^bb115
      ^bb116:
        pdl_interp.check_operand_count of %104 is 2 -> ^bb117, ^bb115
      ^bb117:
        pdl_interp.check_result_count of %104 is 1 -> ^bb118, ^bb115
      ^bb118:
        %105 = pdl_interp.get_operand 1 of %104
        pdl_interp.is_not_null %105 : !pdl.value -> ^bb119, ^bb115
      ^bb119:
        %106 = pdl_interp.get_result 0 of %104
        pdl_interp.is_not_null %106 : !pdl.value -> ^bb120, ^bb115
      ^bb120:
        %107 = ematch.get_class_result %106
        pdl_interp.is_not_null %107 : !pdl.value -> ^bb121, ^bb115
      ^bb121:
        pdl_interp.are_equal %107, %77 : !pdl.value -> ^bb122, ^bb115
      ^bb122:
        %108 = pdl_interp.get_value_type of %107 : !pdl.type
        pdl_interp.are_equal %100, %108 : !pdl.type -> ^bb123, ^bb115
      ^bb123:
        %109 = pdl_interp.get_operand 0 of %104
        pdl_interp.are_equal %96, %109 : !pdl.value -> ^bb124, ^bb115
      ^bb124:
        %110 = ematch.get_class_representative %73
        %111 = ematch.get_class_representative %97
        %112 = ematch.get_class_representative %105
        %113 = ematch.get_class_representative %96
        pdl_interp.record_match @rewriters::@SelMul(%110, %111, %112, %100, %113, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb115
      } -> ^bb103
    ^bb105:
      pdl_interp.check_operand_count of %95 is 2 -> ^bb125, ^bb103
    ^bb125:
      pdl_interp.check_result_count of %95 is 1 -> ^bb126, ^bb103
    ^bb126:
      %114 = pdl_interp.get_operand 0 of %95
      pdl_interp.is_not_null %114 : !pdl.value -> ^bb127, ^bb103
    ^bb127:
      %115 = pdl_interp.get_operand 1 of %95
      pdl_interp.is_not_null %115 : !pdl.value -> ^bb128, ^bb103
    ^bb128:
      %116 = pdl_interp.get_result 0 of %95
      pdl_interp.is_not_null %116 : !pdl.value -> ^bb129, ^bb103
    ^bb129:
      %117 = ematch.get_class_result %116
      pdl_interp.is_not_null %117 : !pdl.value -> ^bb130, ^bb103
    ^bb130:
      pdl_interp.are_equal %117, %74 : !pdl.value -> ^bb131, ^bb103
    ^bb131:
      %118 = pdl_interp.get_value_type of %117 : !pdl.type
      %119 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %118, %119 : !pdl.type -> ^bb132, ^bb103
    ^bb132:
      %120 = ematch.get_class_vals %77
      pdl_interp.foreach %121 : !pdl.value in %120 {
        %122 = pdl_interp.get_defining_op of %121 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %122 : !pdl.operation -> ^bb133, ^bb134
      ^bb134:
        pdl_interp.continue
      ^bb133:
        pdl_interp.check_operation_name of %122 is "comb.add" -> ^bb135, ^bb134
      ^bb135:
        pdl_interp.check_operand_count of %122 is 2 -> ^bb136, ^bb134
      ^bb136:
        pdl_interp.check_result_count of %122 is 1 -> ^bb137, ^bb134
      ^bb137:
        %123 = pdl_interp.get_operand 1 of %122
        pdl_interp.is_not_null %123 : !pdl.value -> ^bb138, ^bb134
      ^bb138:
        %124 = pdl_interp.get_result 0 of %122
        pdl_interp.is_not_null %124 : !pdl.value -> ^bb139, ^bb134
      ^bb139:
        %125 = ematch.get_class_result %124
        pdl_interp.is_not_null %125 : !pdl.value -> ^bb140, ^bb134
      ^bb140:
        pdl_interp.are_equal %125, %77 : !pdl.value -> ^bb141, ^bb134
      ^bb141:
        %126 = pdl_interp.get_value_type of %125 : !pdl.type
        pdl_interp.are_equal %118, %126 : !pdl.type -> ^bb142, ^bb134
      ^bb142:
        %127 = pdl_interp.get_operand 0 of %122
        pdl_interp.is_not_null %127 : !pdl.value -> ^bb143, ^bb134
      ^bb143:
        %128 = ematch.get_class_representative %73
        %129 = ematch.get_class_representative %114
        %130 = ematch.get_class_representative %127
        %131 = ematch.get_class_representative %115
        %132 = ematch.get_class_representative %123
        pdl_interp.record_match @rewriters::@SelAdd(%128, %129, %130, %118, %131, %132, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb134
      } -> ^bb103
    } -> ^bb87
  ^bb3:
    pdl_interp.switch_operand_count of %0 to dense<[2, 3]> : vector<2xi32>(^bb144, ^bb145) -> ^bb5
  ^bb144:
    pdl_interp.check_result_count of %0 is 1 -> ^bb146, ^bb5
  ^bb146:
    %133 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %133 : !pdl.value -> ^bb147, ^bb5
  ^bb147:
    %134 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %134 : !pdl.value -> ^bb148, ^bb5
  ^bb148:
    %135 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %135 : !pdl.value -> ^bb149, ^bb5
  ^bb149:
    %136 = ematch.get_class_result %135
    pdl_interp.is_not_null %136 : !pdl.value -> ^bb150, ^bb5
  ^bb150:
    %137 = ematch.get_class_vals %133
    pdl_interp.foreach %138 : !pdl.value in %137 {
      %139 = pdl_interp.get_defining_op of %138 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %139 : !pdl.operation -> ^bb151, ^bb152
    ^bb152:
      pdl_interp.continue
    ^bb151:
      pdl_interp.switch_operation_name of %139 to ["comb.shru", "comb.add"](^bb153, ^bb154) -> ^bb152
    ^bb153:
      pdl_interp.check_operand_count of %139 is 2 -> ^bb155, ^bb152
    ^bb155:
      pdl_interp.check_result_count of %139 is 1 -> ^bb156, ^bb152
    ^bb156:
      %140 = pdl_interp.get_operand 0 of %139
      pdl_interp.is_not_null %140 : !pdl.value -> ^bb157, ^bb152
    ^bb157:
      %141 = pdl_interp.get_operand 1 of %139
      pdl_interp.is_not_null %141 : !pdl.value -> ^bb158, ^bb152
    ^bb158:
      %142 = pdl_interp.get_result 0 of %139
      pdl_interp.is_not_null %142 : !pdl.value -> ^bb159, ^bb152
    ^bb159:
      %143 = ematch.get_class_result %142
      pdl_interp.is_not_null %143 : !pdl.value -> ^bb160, ^bb152
    ^bb160:
      pdl_interp.are_equal %143, %133 : !pdl.value -> ^bb161, ^bb152
    ^bb161:
      %144 = pdl_interp.get_value_type of %140 : !pdl.type
      %145 = pdl_interp.get_value_type of %143 : !pdl.type
      pdl_interp.are_equal %144, %145 : !pdl.type -> ^bb162, ^bb152
    ^bb162:
      %146 = pdl_interp.get_value_type of %136 : !pdl.type
      pdl_interp.are_equal %144, %146 : !pdl.type -> ^bb163, ^bb152
    ^bb163:
      %147 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %144, %147 : !pdl.type -> ^bb164, ^bb152
    ^bb164:
      %148 = ematch.get_class_representative %134
      %149 = ematch.get_class_representative %141
      %150 = ematch.get_class_representative %140
      pdl_interp.record_match @rewriters::@AddRightShift(%148, %149, %144, %150, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb152
    ^bb154:
      pdl_interp.switch_operand_count of %139 to dense<[2, 3]> : vector<2xi32>(^bb165, ^bb166) -> ^bb152
    ^bb165:
      pdl_interp.check_result_count of %139 is 1 -> ^bb167, ^bb152
    ^bb167:
      %151 = pdl_interp.get_operand 0 of %139
      pdl_interp.is_not_null %151 : !pdl.value -> ^bb168, ^bb152
    ^bb168:
      %152 = pdl_interp.get_operand 1 of %139
      pdl_interp.is_not_null %152 : !pdl.value -> ^bb169, ^bb152
    ^bb169:
      %153 = pdl_interp.get_result 0 of %139
      pdl_interp.is_not_null %153 : !pdl.value -> ^bb170, ^bb152
    ^bb170:
      %154 = ematch.get_class_result %153
      pdl_interp.is_not_null %154 : !pdl.value -> ^bb171, ^bb152
    ^bb171:
      pdl_interp.are_equal %154, %133 : !pdl.value -> ^bb172, ^bb152
    ^bb172:
      %155 = pdl_interp.get_value_type of %151 : !pdl.type
      %156 = pdl_interp.get_value_type of %154 : !pdl.type
      pdl_interp.are_equal %155, %156 : !pdl.type -> ^bb173, ^bb152
    ^bb173:
      %157 = pdl_interp.get_value_type of %136 : !pdl.type
      pdl_interp.are_equal %155, %157 : !pdl.type -> ^bb174, ^bb152
    ^bb174:
      %158 = pdl_interp.get_value_type of %152 : !pdl.type
      pdl_interp.are_equal %155, %158 : !pdl.type -> ^bb175, ^bb152
    ^bb175:
      %159 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %155, %159 : !pdl.type -> ^bb176, ^bb152
    ^bb176:
      %160 = ematch.get_class_representative %151
      %161 = ematch.get_class_representative %152
      %162 = ematch.get_class_representative %134
      pdl_interp.record_match @rewriters::@MergeAdd3(%160, %161, %162, %155, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb152
    ^bb166:
      pdl_interp.check_result_count of %139 is 1 -> ^bb177, ^bb152
    ^bb177:
      %163 = pdl_interp.get_operand 0 of %139
      pdl_interp.is_not_null %163 : !pdl.value -> ^bb178, ^bb152
    ^bb178:
      %164 = pdl_interp.get_operand 1 of %139
      pdl_interp.is_not_null %164 : !pdl.value -> ^bb179, ^bb152
    ^bb179:
      %165 = pdl_interp.get_result 0 of %139
      pdl_interp.is_not_null %165 : !pdl.value -> ^bb180, ^bb152
    ^bb180:
      %166 = ematch.get_class_result %165
      pdl_interp.is_not_null %166 : !pdl.value -> ^bb181, ^bb152
    ^bb181:
      pdl_interp.are_equal %166, %133 : !pdl.value -> ^bb182, ^bb152
    ^bb182:
      %167 = pdl_interp.get_value_type of %163 : !pdl.type
      %168 = pdl_interp.get_value_type of %166 : !pdl.type
      pdl_interp.are_equal %167, %168 : !pdl.type -> ^bb183, ^bb152
    ^bb183:
      %169 = pdl_interp.get_value_type of %136 : !pdl.type
      pdl_interp.are_equal %167, %169 : !pdl.type -> ^bb184, ^bb152
    ^bb184:
      %170 = pdl_interp.get_value_type of %164 : !pdl.type
      pdl_interp.are_equal %167, %170 : !pdl.type -> ^bb185, ^bb152
    ^bb185:
      %171 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %167, %171 : !pdl.type -> ^bb186, ^bb152
    ^bb186:
      %172 = pdl_interp.get_operand 2 of %139
      pdl_interp.is_not_null %172 : !pdl.value -> ^bb187, ^bb152
    ^bb187:
      %173 = pdl_interp.get_value_type of %172 : !pdl.type
      pdl_interp.are_equal %167, %173 : !pdl.type -> ^bb188, ^bb152
    ^bb188:
      %174 = ematch.get_class_representative %163
      %175 = ematch.get_class_representative %164
      %176 = ematch.get_class_representative %172
      %177 = ematch.get_class_representative %134
      pdl_interp.record_match @rewriters::@MergeAdd4(%174, %175, %176, %177, %167, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb152
    } -> ^bb5
  ^bb145:
    pdl_interp.check_result_count of %0 is 1 -> ^bb189, ^bb5
  ^bb189:
    %178 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %178 : !pdl.value -> ^bb190, ^bb5
  ^bb190:
    %179 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %179 : !pdl.value -> ^bb191, ^bb5
  ^bb191:
    %180 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %180 : !pdl.value -> ^bb192, ^bb5
  ^bb192:
    %181 = ematch.get_class_result %180
    pdl_interp.is_not_null %181 : !pdl.value -> ^bb193, ^bb5
  ^bb193:
    %182 = pdl_interp.get_operand 2 of %0
    pdl_interp.is_not_null %182 : !pdl.value -> ^bb194, ^bb5
  ^bb194:
    %183 = pdl_interp.get_value_type of %178 : !pdl.type
    %184 = pdl_interp.get_value_type of %181 : !pdl.type
    pdl_interp.are_equal %183, %184 : !pdl.type -> ^bb195, ^bb5
  ^bb195:
    %185 = pdl_interp.get_value_type of %179 : !pdl.type
    pdl_interp.are_equal %183, %185 : !pdl.type -> ^bb196, ^bb5
  ^bb196:
    %186 = pdl_interp.get_value_type of %182 : !pdl.type
    pdl_interp.are_equal %183, %186 : !pdl.type -> ^bb197, ^bb5
  ^bb197:
    %187 = ematch.get_class_representative %178
    %188 = ematch.get_class_representative %179
    %189 = ematch.get_class_representative %182
    pdl_interp.record_match @rewriters::@AddAddToCompress(%187, %188, %189, %183, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb5
  ^bb4:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb198, ^bb5
  ^bb198:
    pdl_interp.check_result_count of %0 is 1 -> ^bb199, ^bb5
  ^bb199:
    %190 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %190 : !pdl.value -> ^bb200, ^bb5
  ^bb200:
    %191 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %191 : !pdl.value -> ^bb201, ^bb5
  ^bb201:
    %192 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %192 : !pdl.value -> ^bb202, ^bb5
  ^bb202:
    %193 = ematch.get_class_result %192
    pdl_interp.is_not_null %193 : !pdl.value -> ^bb203, ^bb5
  ^bb203:
    %194 = ematch.get_class_vals %190
    pdl_interp.foreach %195 : !pdl.value in %194 {
      %196 = pdl_interp.get_defining_op of %195 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %196 : !pdl.operation -> ^bb204, ^bb205
    ^bb205:
      pdl_interp.continue
    ^bb204:
      pdl_interp.check_operation_name of %196 is "comb.shru" -> ^bb206, ^bb205
    ^bb206:
      pdl_interp.check_operand_count of %196 is 2 -> ^bb207, ^bb205
    ^bb207:
      pdl_interp.check_result_count of %196 is 1 -> ^bb208, ^bb205
    ^bb208:
      %197 = pdl_interp.get_operand 0 of %196
      pdl_interp.is_not_null %197 : !pdl.value -> ^bb209, ^bb205
    ^bb209:
      %198 = pdl_interp.get_operand 1 of %196
      pdl_interp.is_not_null %198 : !pdl.value -> ^bb210, ^bb205
    ^bb210:
      %199 = pdl_interp.get_result 0 of %196
      pdl_interp.is_not_null %199 : !pdl.value -> ^bb211, ^bb205
    ^bb211:
      %200 = ematch.get_class_result %199
      pdl_interp.is_not_null %200 : !pdl.value -> ^bb212, ^bb205
    ^bb212:
      pdl_interp.are_equal %200, %190 : !pdl.value -> ^bb213, ^bb205
    ^bb213:
      %201 = pdl_interp.get_value_type of %197 : !pdl.type
      %202 = pdl_interp.get_value_type of %200 : !pdl.type
      pdl_interp.are_equal %201, %202 : !pdl.type -> ^bb214, ^bb205
    ^bb214:
      %203 = pdl_interp.get_value_type of %193 : !pdl.type
      pdl_interp.are_equal %201, %203 : !pdl.type -> ^bb215, ^bb205
    ^bb215:
      %204 = ematch.get_class_representative %198
      %205 = ematch.get_class_representative %191
      %206 = ematch.get_class_representative %197
      pdl_interp.record_match @rewriters::@MergeRightShift(%204, %205, %201, %206, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shru") -> ^bb205
    } -> ^bb5
  }
  builtin.module @rewriters {
    pdl_interp.func @LeftShiftMult(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @LeftShiftAdd(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @MergeLeftShift(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @LeftShiftMult1(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @LeftShiftMult2(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @MulToPartialProductTree(%0: !pdl.operation, %1: !pdl.type) {
      %2 = pdl_interp.apply_rewrite "BuildPartialProduct"(%0 : !pdl.operation) : !pdl.operation
      %3 = ematch.dedup %2
      %4 = pdl_interp.get_results of %3 : !pdl.range<value>
      %5 = ematch.get_class_results %4
      %6 = pdl_interp.apply_rewrite "BuildCompress"(%5 : !pdl.range<value>) : !pdl.operation
      %7 = ematch.dedup %6
      %8 = pdl_interp.get_result 0 of %7
      %9 = ematch.get_class_result %8
      %10 = pdl_interp.get_result 1 of %7
      %11 = ematch.get_class_result %10
      %12 = pdl_interp.create_operation "comb.add"(%9, %11 : !pdl.value, !pdl.value) -> (%1 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %0 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelAddLeft(%0: !pdl.operation, %1: !pdl.value, %2: !pdl.value, %3: !pdl.type, %4: !pdl.value) {
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
    pdl_interp.func @SelSame(%0: !pdl.value, %1: !pdl.operation) {
      %2 = ematch.get_class_result %0
      %3 = pdl_interp.create_range %2 : !pdl.value
      ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SelMul(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.type, %4: !pdl.value, %5: !pdl.operation) {
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
    pdl_interp.func @SelAdd(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.type, %4: !pdl.value, %5: !pdl.value, %6: !pdl.operation) {
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
    pdl_interp.func @AddRightShift(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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
    pdl_interp.func @MergeAdd3(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.type, %4: !pdl.operation) {
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
    pdl_interp.func @MergeAdd4(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.value, %4: !pdl.type, %5: !pdl.operation) {
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
    pdl_interp.func @AddAddToCompress(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.type, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = ematch.get_class_result %2
      %8 = pdl_interp.create_range %5, %6, %7 : !pdl.value, !pdl.value, !pdl.value
      %9 = pdl_interp.apply_rewrite "BuildCompress"(%8 : !pdl.range<value>) : !pdl.operation
      %10 = ematch.dedup %9
      %11 = pdl_interp.get_result 0 of %10
      %12 = ematch.get_class_result %11
      %13 = pdl_interp.get_result 1 of %10
      %14 = ematch.get_class_result %13
      %15 = pdl_interp.create_operation "comb.add"(%12, %14 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %16 = ematch.dedup %15
      %17 = pdl_interp.get_results of %16 : !pdl.range<value>
      %18 = ematch.get_class_results %17
      ematch.union %4 : !pdl.operation, %18 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MergeRightShift(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
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

