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
    %78 = ematch.get_class_vals %74
    pdl_interp.foreach %79 : !pdl.value in %78 {
      %80 = pdl_interp.get_defining_op of %79 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %80 : !pdl.operation -> ^bb88, ^bb89
    ^bb89:
      pdl_interp.continue
    ^bb88:
      pdl_interp.check_operation_name of %80 is "comb.add" -> ^bb90, ^bb89
    ^bb90:
      pdl_interp.check_operand_count of %80 is 2 -> ^bb91, ^bb89
    ^bb91:
      pdl_interp.check_result_count of %80 is 1 -> ^bb92, ^bb89
    ^bb92:
      %81 = pdl_interp.get_operand 0 of %80
      pdl_interp.is_not_null %81 : !pdl.value -> ^bb93, ^bb89
    ^bb93:
      %82 = pdl_interp.get_operand 1 of %80
      pdl_interp.is_not_null %82 : !pdl.value -> ^bb94, ^bb89
    ^bb94:
      %83 = pdl_interp.get_result 0 of %80
      pdl_interp.is_not_null %83 : !pdl.value -> ^bb95, ^bb89
    ^bb95:
      %84 = ematch.get_class_result %83
      pdl_interp.is_not_null %84 : !pdl.value -> ^bb96, ^bb89
    ^bb96:
      pdl_interp.are_equal %84, %74 : !pdl.value -> ^bb97, ^bb89
    ^bb97:
      %85 = pdl_interp.get_value_type of %84 : !pdl.type
      %86 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %85, %86 : !pdl.type -> ^bb98, ^bb89
    ^bb98:
      %87 = pdl_interp.get_operand 2 of %0
      pdl_interp.are_equal %81, %87 : !pdl.value -> ^bb99, ^bb89
    ^bb99:
      %88 = ematch.get_class_representative %73
      %89 = ematch.get_class_representative %82
      %90 = ematch.get_class_representative %81
      pdl_interp.record_match @rewriters::@SelAddLeft(%0, %88, %89, %85, %90 : !pdl.operation, !pdl.value, !pdl.value, !pdl.type, !pdl.value) : benefit(1), loc([]), root("comb.mux") -> ^bb89
    } -> ^bb5
  ^bb86:
    %91 = ematch.get_class_vals %74
    pdl_interp.foreach %92 : !pdl.value in %91 {
      %93 = pdl_interp.get_defining_op of %92 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %93 : !pdl.operation -> ^bb100, ^bb101
    ^bb101:
      pdl_interp.continue
    ^bb100:
      pdl_interp.switch_operation_name of %93 to ["comb.mul", "comb.add"](^bb102, ^bb103) -> ^bb101
    ^bb102:
      pdl_interp.check_operand_count of %93 is 2 -> ^bb104, ^bb101
    ^bb104:
      pdl_interp.check_result_count of %93 is 1 -> ^bb105, ^bb101
    ^bb105:
      %94 = pdl_interp.get_operand 0 of %93
      pdl_interp.is_not_null %94 : !pdl.value -> ^bb106, ^bb101
    ^bb106:
      %95 = pdl_interp.get_operand 1 of %93
      pdl_interp.is_not_null %95 : !pdl.value -> ^bb107, ^bb101
    ^bb107:
      %96 = pdl_interp.get_result 0 of %93
      pdl_interp.is_not_null %96 : !pdl.value -> ^bb108, ^bb101
    ^bb108:
      %97 = ematch.get_class_result %96
      pdl_interp.is_not_null %97 : !pdl.value -> ^bb109, ^bb101
    ^bb109:
      pdl_interp.are_equal %97, %74 : !pdl.value -> ^bb110, ^bb101
    ^bb110:
      %98 = pdl_interp.get_value_type of %97 : !pdl.type
      %99 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %98, %99 : !pdl.type -> ^bb111, ^bb101
    ^bb111:
      %100 = ematch.get_class_vals %77
      pdl_interp.foreach %101 : !pdl.value in %100 {
        %102 = pdl_interp.get_defining_op of %101 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %102 : !pdl.operation -> ^bb112, ^bb113
      ^bb113:
        pdl_interp.continue
      ^bb112:
        pdl_interp.check_operation_name of %102 is "comb.mul" -> ^bb114, ^bb113
      ^bb114:
        pdl_interp.check_operand_count of %102 is 2 -> ^bb115, ^bb113
      ^bb115:
        pdl_interp.check_result_count of %102 is 1 -> ^bb116, ^bb113
      ^bb116:
        %103 = pdl_interp.get_operand 1 of %102
        pdl_interp.is_not_null %103 : !pdl.value -> ^bb117, ^bb113
      ^bb117:
        %104 = pdl_interp.get_result 0 of %102
        pdl_interp.is_not_null %104 : !pdl.value -> ^bb118, ^bb113
      ^bb118:
        %105 = ematch.get_class_result %104
        pdl_interp.is_not_null %105 : !pdl.value -> ^bb119, ^bb113
      ^bb119:
        pdl_interp.are_equal %105, %77 : !pdl.value -> ^bb120, ^bb113
      ^bb120:
        %106 = pdl_interp.get_value_type of %105 : !pdl.type
        pdl_interp.are_equal %98, %106 : !pdl.type -> ^bb121, ^bb113
      ^bb121:
        %107 = pdl_interp.get_operand 0 of %102
        pdl_interp.are_equal %94, %107 : !pdl.value -> ^bb122, ^bb113
      ^bb122:
        %108 = ematch.get_class_representative %73
        %109 = ematch.get_class_representative %95
        %110 = ematch.get_class_representative %103
        %111 = ematch.get_class_representative %94
        pdl_interp.record_match @rewriters::@SelMul(%108, %109, %110, %98, %111, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb113
      } -> ^bb101
    ^bb103:
      pdl_interp.check_operand_count of %93 is 2 -> ^bb123, ^bb101
    ^bb123:
      pdl_interp.check_result_count of %93 is 1 -> ^bb124, ^bb101
    ^bb124:
      %112 = pdl_interp.get_operand 0 of %93
      pdl_interp.is_not_null %112 : !pdl.value -> ^bb125, ^bb101
    ^bb125:
      %113 = pdl_interp.get_operand 1 of %93
      pdl_interp.is_not_null %113 : !pdl.value -> ^bb126, ^bb101
    ^bb126:
      %114 = pdl_interp.get_result 0 of %93
      pdl_interp.is_not_null %114 : !pdl.value -> ^bb127, ^bb101
    ^bb127:
      %115 = ematch.get_class_result %114
      pdl_interp.is_not_null %115 : !pdl.value -> ^bb128, ^bb101
    ^bb128:
      pdl_interp.are_equal %115, %74 : !pdl.value -> ^bb129, ^bb101
    ^bb129:
      %116 = pdl_interp.get_value_type of %115 : !pdl.type
      %117 = pdl_interp.get_value_type of %76 : !pdl.type
      pdl_interp.are_equal %116, %117 : !pdl.type -> ^bb130, ^bb101
    ^bb130:
      %118 = ematch.get_class_vals %77
      pdl_interp.foreach %119 : !pdl.value in %118 {
        %120 = pdl_interp.get_defining_op of %119 : !pdl.value {position = "root.operand[2].defining_op"}
        pdl_interp.is_not_null %120 : !pdl.operation -> ^bb131, ^bb132
      ^bb132:
        pdl_interp.continue
      ^bb131:
        pdl_interp.check_operation_name of %120 is "comb.add" -> ^bb133, ^bb132
      ^bb133:
        pdl_interp.check_operand_count of %120 is 2 -> ^bb134, ^bb132
      ^bb134:
        pdl_interp.check_result_count of %120 is 1 -> ^bb135, ^bb132
      ^bb135:
        %121 = pdl_interp.get_operand 1 of %120
        pdl_interp.is_not_null %121 : !pdl.value -> ^bb136, ^bb132
      ^bb136:
        %122 = pdl_interp.get_result 0 of %120
        pdl_interp.is_not_null %122 : !pdl.value -> ^bb137, ^bb132
      ^bb137:
        %123 = ematch.get_class_result %122
        pdl_interp.is_not_null %123 : !pdl.value -> ^bb138, ^bb132
      ^bb138:
        pdl_interp.are_equal %123, %77 : !pdl.value -> ^bb139, ^bb132
      ^bb139:
        %124 = pdl_interp.get_value_type of %123 : !pdl.type
        pdl_interp.are_equal %116, %124 : !pdl.type -> ^bb140, ^bb132
      ^bb140:
        %125 = pdl_interp.get_operand 0 of %120
        pdl_interp.is_not_null %125 : !pdl.value -> ^bb141, ^bb132
      ^bb141:
        %126 = ematch.get_class_representative %73
        %127 = ematch.get_class_representative %112
        %128 = ematch.get_class_representative %125
        %129 = ematch.get_class_representative %113
        %130 = ematch.get_class_representative %121
        pdl_interp.record_match @rewriters::@SelAdd(%126, %127, %128, %116, %129, %130, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.mux") -> ^bb132
      } -> ^bb101
    } -> ^bb87
  ^bb3:
    pdl_interp.switch_operand_count of %0 to dense<[2, 3]> : vector<2xi32>(^bb142, ^bb143) -> ^bb5
  ^bb142:
    pdl_interp.check_result_count of %0 is 1 -> ^bb144, ^bb5
  ^bb144:
    %131 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %131 : !pdl.value -> ^bb145, ^bb5
  ^bb145:
    %132 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %132 : !pdl.value -> ^bb146, ^bb5
  ^bb146:
    %133 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %133 : !pdl.value -> ^bb147, ^bb5
  ^bb147:
    %134 = ematch.get_class_result %133
    pdl_interp.is_not_null %134 : !pdl.value -> ^bb148, ^bb5
  ^bb148:
    %135 = ematch.get_class_vals %131
    pdl_interp.foreach %136 : !pdl.value in %135 {
      %137 = pdl_interp.get_defining_op of %136 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %137 : !pdl.operation -> ^bb149, ^bb150
    ^bb150:
      pdl_interp.continue
    ^bb149:
      pdl_interp.switch_operation_name of %137 to ["comb.shru", "comb.add"](^bb151, ^bb152) -> ^bb150
    ^bb151:
      pdl_interp.check_operand_count of %137 is 2 -> ^bb153, ^bb150
    ^bb153:
      pdl_interp.check_result_count of %137 is 1 -> ^bb154, ^bb150
    ^bb154:
      %138 = pdl_interp.get_operand 0 of %137
      pdl_interp.is_not_null %138 : !pdl.value -> ^bb155, ^bb150
    ^bb155:
      %139 = pdl_interp.get_operand 1 of %137
      pdl_interp.is_not_null %139 : !pdl.value -> ^bb156, ^bb150
    ^bb156:
      %140 = pdl_interp.get_result 0 of %137
      pdl_interp.is_not_null %140 : !pdl.value -> ^bb157, ^bb150
    ^bb157:
      %141 = ematch.get_class_result %140
      pdl_interp.is_not_null %141 : !pdl.value -> ^bb158, ^bb150
    ^bb158:
      pdl_interp.are_equal %141, %131 : !pdl.value -> ^bb159, ^bb150
    ^bb159:
      %142 = pdl_interp.get_value_type of %138 : !pdl.type
      %143 = pdl_interp.get_value_type of %141 : !pdl.type
      pdl_interp.are_equal %142, %143 : !pdl.type -> ^bb160, ^bb150
    ^bb160:
      %144 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %142, %144 : !pdl.type -> ^bb161, ^bb150
    ^bb161:
      %145 = pdl_interp.get_value_type of %132 : !pdl.type
      pdl_interp.are_equal %142, %145 : !pdl.type -> ^bb162, ^bb150
    ^bb162:
      %146 = ematch.get_class_representative %132
      %147 = ematch.get_class_representative %139
      %148 = ematch.get_class_representative %138
      pdl_interp.record_match @rewriters::@AddRightShift(%146, %147, %142, %148, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    ^bb152:
      pdl_interp.switch_operand_count of %137 to dense<[2, 3]> : vector<2xi32>(^bb163, ^bb164) -> ^bb150
    ^bb163:
      pdl_interp.check_result_count of %137 is 1 -> ^bb165, ^bb150
    ^bb165:
      %149 = pdl_interp.get_operand 0 of %137
      pdl_interp.is_not_null %149 : !pdl.value -> ^bb166, ^bb150
    ^bb166:
      %150 = pdl_interp.get_operand 1 of %137
      pdl_interp.is_not_null %150 : !pdl.value -> ^bb167, ^bb150
    ^bb167:
      %151 = pdl_interp.get_result 0 of %137
      pdl_interp.is_not_null %151 : !pdl.value -> ^bb168, ^bb150
    ^bb168:
      %152 = ematch.get_class_result %151
      pdl_interp.is_not_null %152 : !pdl.value -> ^bb169, ^bb150
    ^bb169:
      pdl_interp.are_equal %152, %131 : !pdl.value -> ^bb170, ^bb150
    ^bb170:
      %153 = pdl_interp.get_value_type of %149 : !pdl.type
      %154 = pdl_interp.get_value_type of %152 : !pdl.type
      pdl_interp.are_equal %153, %154 : !pdl.type -> ^bb171, ^bb150
    ^bb171:
      %155 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %153, %155 : !pdl.type -> ^bb172, ^bb150
    ^bb172:
      %156 = pdl_interp.get_value_type of %150 : !pdl.type
      pdl_interp.are_equal %153, %156 : !pdl.type -> ^bb173, ^bb150
    ^bb173:
      %157 = pdl_interp.get_value_type of %132 : !pdl.type
      pdl_interp.are_equal %153, %157 : !pdl.type -> ^bb174, ^bb150
    ^bb174:
      %158 = ematch.get_class_representative %149
      %159 = ematch.get_class_representative %150
      %160 = ematch.get_class_representative %132
      pdl_interp.record_match @rewriters::@MergeAdd3(%158, %159, %160, %153, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    ^bb164:
      pdl_interp.check_result_count of %137 is 1 -> ^bb175, ^bb150
    ^bb175:
      %161 = pdl_interp.get_operand 0 of %137
      pdl_interp.is_not_null %161 : !pdl.value -> ^bb176, ^bb150
    ^bb176:
      %162 = pdl_interp.get_operand 1 of %137
      pdl_interp.is_not_null %162 : !pdl.value -> ^bb177, ^bb150
    ^bb177:
      %163 = pdl_interp.get_result 0 of %137
      pdl_interp.is_not_null %163 : !pdl.value -> ^bb178, ^bb150
    ^bb178:
      %164 = ematch.get_class_result %163
      pdl_interp.is_not_null %164 : !pdl.value -> ^bb179, ^bb150
    ^bb179:
      pdl_interp.are_equal %164, %131 : !pdl.value -> ^bb180, ^bb150
    ^bb180:
      %165 = pdl_interp.get_value_type of %161 : !pdl.type
      %166 = pdl_interp.get_value_type of %164 : !pdl.type
      pdl_interp.are_equal %165, %166 : !pdl.type -> ^bb181, ^bb150
    ^bb181:
      %167 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %165, %167 : !pdl.type -> ^bb182, ^bb150
    ^bb182:
      %168 = pdl_interp.get_value_type of %162 : !pdl.type
      pdl_interp.are_equal %165, %168 : !pdl.type -> ^bb183, ^bb150
    ^bb183:
      %169 = pdl_interp.get_value_type of %132 : !pdl.type
      pdl_interp.are_equal %165, %169 : !pdl.type -> ^bb184, ^bb150
    ^bb184:
      %170 = pdl_interp.get_operand 2 of %137
      pdl_interp.is_not_null %170 : !pdl.value -> ^bb185, ^bb150
    ^bb185:
      %171 = pdl_interp.get_value_type of %170 : !pdl.type
      pdl_interp.are_equal %165, %171 : !pdl.type -> ^bb186, ^bb150
    ^bb186:
      %172 = ematch.get_class_representative %161
      %173 = ematch.get_class_representative %162
      %174 = ematch.get_class_representative %170
      %175 = ematch.get_class_representative %132
      pdl_interp.record_match @rewriters::@MergeAdd4(%172, %173, %174, %175, %165, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb150
    } -> ^bb5
  ^bb143:
    pdl_interp.check_result_count of %0 is 1 -> ^bb187, ^bb5
  ^bb187:
    %176 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %176 : !pdl.value -> ^bb188, ^bb5
  ^bb188:
    %177 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %177 : !pdl.value -> ^bb189, ^bb5
  ^bb189:
    %178 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %178 : !pdl.value -> ^bb190, ^bb5
  ^bb190:
    %179 = ematch.get_class_result %178
    pdl_interp.is_not_null %179 : !pdl.value -> ^bb191, ^bb5
  ^bb191:
    %180 = pdl_interp.get_operand 2 of %0
    pdl_interp.is_not_null %180 : !pdl.value -> ^bb192, ^bb5
  ^bb192:
    %181 = pdl_interp.get_value_type of %176 : !pdl.type
    %182 = pdl_interp.get_value_type of %179 : !pdl.type
    pdl_interp.are_equal %181, %182 : !pdl.type -> ^bb193, ^bb5
  ^bb193:
    %183 = pdl_interp.get_value_type of %177 : !pdl.type
    pdl_interp.are_equal %181, %183 : !pdl.type -> ^bb194, ^bb5
  ^bb194:
    %184 = pdl_interp.get_value_type of %180 : !pdl.type
    pdl_interp.are_equal %181, %184 : !pdl.type -> ^bb195, ^bb5
  ^bb195:
    %185 = ematch.get_class_representative %176
    %186 = ematch.get_class_representative %177
    %187 = ematch.get_class_representative %180
    pdl_interp.record_match @rewriters::@AddAddToCompress(%185, %186, %187, %181, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("comb.add") -> ^bb5
  ^bb4:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb196, ^bb5
  ^bb196:
    pdl_interp.check_result_count of %0 is 1 -> ^bb197, ^bb5
  ^bb197:
    %188 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %188 : !pdl.value -> ^bb198, ^bb5
  ^bb198:
    %189 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %189 : !pdl.value -> ^bb199, ^bb5
  ^bb199:
    %190 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %190 : !pdl.value -> ^bb200, ^bb5
  ^bb200:
    %191 = ematch.get_class_result %190
    pdl_interp.is_not_null %191 : !pdl.value -> ^bb201, ^bb5
  ^bb201:
    %192 = ematch.get_class_vals %188
    pdl_interp.foreach %193 : !pdl.value in %192 {
      %194 = pdl_interp.get_defining_op of %193 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %194 : !pdl.operation -> ^bb202, ^bb203
    ^bb203:
      pdl_interp.continue
    ^bb202:
      pdl_interp.check_operation_name of %194 is "comb.shru" -> ^bb204, ^bb203
    ^bb204:
      pdl_interp.check_operand_count of %194 is 2 -> ^bb205, ^bb203
    ^bb205:
      pdl_interp.check_result_count of %194 is 1 -> ^bb206, ^bb203
    ^bb206:
      %195 = pdl_interp.get_operand 0 of %194
      pdl_interp.is_not_null %195 : !pdl.value -> ^bb207, ^bb203
    ^bb207:
      %196 = pdl_interp.get_operand 1 of %194
      pdl_interp.is_not_null %196 : !pdl.value -> ^bb208, ^bb203
    ^bb208:
      %197 = pdl_interp.get_result 0 of %194
      pdl_interp.is_not_null %197 : !pdl.value -> ^bb209, ^bb203
    ^bb209:
      %198 = ematch.get_class_result %197
      pdl_interp.is_not_null %198 : !pdl.value -> ^bb210, ^bb203
    ^bb210:
      pdl_interp.are_equal %198, %188 : !pdl.value -> ^bb211, ^bb203
    ^bb211:
      %199 = pdl_interp.get_value_type of %195 : !pdl.type
      %200 = pdl_interp.get_value_type of %198 : !pdl.type
      pdl_interp.are_equal %199, %200 : !pdl.type -> ^bb212, ^bb203
    ^bb212:
      %201 = pdl_interp.get_value_type of %191 : !pdl.type
      pdl_interp.are_equal %199, %201 : !pdl.type -> ^bb213, ^bb203
    ^bb213:
      %202 = ematch.get_class_representative %196
      %203 = ematch.get_class_representative %189
      %204 = ematch.get_class_representative %195
      pdl_interp.record_match @rewriters::@MergeRightShift(%202, %203, %199, %204, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("comb.shru") -> ^bb203
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

