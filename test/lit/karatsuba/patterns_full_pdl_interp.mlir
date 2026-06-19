builtin.module {
  pdl_interp.func @matcher(%0: !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["arith.addi", "arith.muli", "arith.subi", "arith.shli", "arith.extui"](^bb0, ^bb1, ^bb2, ^bb3, ^bb4) -> ^bb5
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
    %2 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb9, ^bb5
  ^bb9:
    %3 = ematch.get_class_result %2
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb10, ^bb5
  ^bb10:
    %4 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb11, ^bb5
  ^bb11:
    %5 = pdl_interp.get_value_type of %1 : !pdl.type
    %6 = pdl_interp.get_value_type of %3 : !pdl.type
    pdl_interp.are_equal %5, %6 : !pdl.type -> ^bb12, ^bb13
  ^bb13:
    %7 = ematch.get_class_vals %1
    pdl_interp.foreach %8 : !pdl.value in %7 {
      %9 = pdl_interp.get_defining_op of %8 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %9 : !pdl.operation -> ^bb14, ^bb15
    ^bb15:
      pdl_interp.continue
    ^bb14:
      pdl_interp.switch_operation_name of %9 to ["arith.muli", "arith.shli"](^bb16, ^bb17) -> ^bb15
    ^bb16:
      pdl_interp.check_operand_count of %9 is 2 -> ^bb18, ^bb15
    ^bb18:
      pdl_interp.check_result_count of %9 is 1 -> ^bb19, ^bb15
    ^bb19:
      %10 = pdl_interp.get_operand 0 of %9
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb20, ^bb15
    ^bb20:
      %11 = pdl_interp.get_result 0 of %9
      pdl_interp.is_not_null %11 : !pdl.value -> ^bb21, ^bb15
    ^bb21:
      %12 = ematch.get_class_result %11
      pdl_interp.is_not_null %12 : !pdl.value -> ^bb22, ^bb15
    ^bb22:
      pdl_interp.are_equal %12, %1 : !pdl.value -> ^bb23, ^bb15
    ^bb23:
      %13 = pdl_interp.get_operand 1 of %9
      pdl_interp.is_not_null %13 : !pdl.value -> ^bb24, ^bb15
    ^bb24:
      %14 = pdl_interp.get_value_type of %10 : !pdl.type
      %15 = pdl_interp.get_value_type of %13 : !pdl.type
      pdl_interp.are_equal %14, %15 : !pdl.type -> ^bb25, ^bb15
    ^bb25:
      %16 = pdl_interp.get_value_type of %12 : !pdl.type
      pdl_interp.are_equal %14, %16 : !pdl.type -> ^bb26, ^bb15
    ^bb26:
      %17 = pdl_interp.get_value_type of %3 : !pdl.type
      pdl_interp.are_equal %14, %17 : !pdl.type -> ^bb27, ^bb15
    ^bb27:
      %18 = ematch.get_class_vals %4
      pdl_interp.foreach %19 : !pdl.value in %18 {
        %20 = pdl_interp.get_defining_op of %19 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %20 : !pdl.operation -> ^bb28, ^bb29
      ^bb29:
        pdl_interp.continue
      ^bb28:
        pdl_interp.check_operation_name of %20 is "arith.muli" -> ^bb30, ^bb29
      ^bb30:
        pdl_interp.check_operand_count of %20 is 2 -> ^bb31, ^bb29
      ^bb31:
        pdl_interp.check_result_count of %20 is 1 -> ^bb32, ^bb29
      ^bb32:
        %21 = pdl_interp.get_result 0 of %20
        pdl_interp.is_not_null %21 : !pdl.value -> ^bb33, ^bb29
      ^bb33:
        %22 = ematch.get_class_result %21
        pdl_interp.is_not_null %22 : !pdl.value -> ^bb34, ^bb29
      ^bb34:
        pdl_interp.are_equal %22, %4 : !pdl.value -> ^bb35, ^bb29
      ^bb35:
        %23 = pdl_interp.get_operand 1 of %20
        pdl_interp.is_not_null %23 : !pdl.value -> ^bb36, ^bb37
      ^bb37:
        %24 = pdl_interp.get_operand 0 of %20
        pdl_interp.is_not_null %24 : !pdl.value -> ^bb38, ^bb29
      ^bb38:
        %25 = pdl_interp.get_value_type of %22 : !pdl.type
        pdl_interp.are_equal %14, %25 : !pdl.type -> ^bb39, ^bb29
      ^bb39:
        %26 = pdl_interp.get_operand 1 of %20
        pdl_interp.are_equal %13, %26 : !pdl.value -> ^bb40, ^bb29
      ^bb40:
        %27 = pdl_interp.get_value_type of %24 : !pdl.type
        pdl_interp.are_equal %14, %27 : !pdl.type -> ^bb41, ^bb29
      ^bb41:
        %28 = ematch.get_class_representative %10
        %29 = ematch.get_class_representative %24
        %30 = ematch.get_class_representative %13
        pdl_interp.record_match @rewriters::@UndistributeRight(%28, %29, %14, %30, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb29
      ^bb36:
        %31 = pdl_interp.get_value_type of %22 : !pdl.type
        pdl_interp.are_equal %14, %31 : !pdl.type -> ^bb42, ^bb37
      ^bb42:
        %32 = pdl_interp.get_operand 0 of %20
        pdl_interp.are_equal %10, %32 : !pdl.value -> ^bb43, ^bb37
      ^bb43:
        %33 = pdl_interp.get_value_type of %23 : !pdl.type
        pdl_interp.are_equal %14, %33 : !pdl.type -> ^bb44, ^bb37
      ^bb44:
        %34 = ematch.get_class_representative %13
        %35 = ematch.get_class_representative %23
        %36 = ematch.get_class_representative %10
        pdl_interp.record_match @rewriters::@UndistributeLeft(%34, %35, %14, %36, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb37
      } -> ^bb15
    ^bb17:
      pdl_interp.check_operand_count of %9 is 2 -> ^bb45, ^bb15
    ^bb45:
      pdl_interp.check_result_count of %9 is 1 -> ^bb46, ^bb15
    ^bb46:
      %37 = pdl_interp.get_operand 0 of %9
      pdl_interp.is_not_null %37 : !pdl.value -> ^bb47, ^bb15
    ^bb47:
      %38 = pdl_interp.get_result 0 of %9
      pdl_interp.is_not_null %38 : !pdl.value -> ^bb48, ^bb15
    ^bb48:
      %39 = ematch.get_class_result %38
      pdl_interp.is_not_null %39 : !pdl.value -> ^bb49, ^bb15
    ^bb49:
      pdl_interp.are_equal %39, %1 : !pdl.value -> ^bb50, ^bb15
    ^bb50:
      %40 = pdl_interp.get_operand 1 of %9
      pdl_interp.is_not_null %40 : !pdl.value -> ^bb51, ^bb15
    ^bb51:
      %41 = ematch.get_class_vals %4
      pdl_interp.foreach %42 : !pdl.value in %41 {
        %43 = pdl_interp.get_defining_op of %42 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %43 : !pdl.operation -> ^bb52, ^bb53
      ^bb53:
        pdl_interp.continue
      ^bb52:
        pdl_interp.check_operation_name of %43 is "arith.extui" -> ^bb54, ^bb53
      ^bb54:
        pdl_interp.check_operand_count of %43 is 1 -> ^bb55, ^bb53
      ^bb55:
        pdl_interp.check_result_count of %43 is 1 -> ^bb56, ^bb53
      ^bb56:
        %44 = pdl_interp.get_result 0 of %43
        pdl_interp.is_not_null %44 : !pdl.value -> ^bb57, ^bb53
      ^bb57:
        %45 = ematch.get_class_result %44
        pdl_interp.is_not_null %45 : !pdl.value -> ^bb58, ^bb53
      ^bb58:
        pdl_interp.are_equal %45, %4 : !pdl.value -> ^bb59, ^bb53
      ^bb59:
        %46 = pdl_interp.get_operand 0 of %43
        pdl_interp.is_not_null %46 : !pdl.value -> ^bb60, ^bb53
      ^bb60:
        %47 = ematch.get_class_vals %40
        pdl_interp.foreach %48 : !pdl.value in %47 {
          %49 = pdl_interp.get_defining_op of %48 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op"}
          pdl_interp.is_not_null %49 : !pdl.operation -> ^bb61, ^bb62
        ^bb62:
          pdl_interp.continue
        ^bb61:
          pdl_interp.check_operation_name of %49 is "arith.constant" -> ^bb63, ^bb62
        ^bb63:
          pdl_interp.check_operand_count of %49 is 0 -> ^bb64, ^bb62
        ^bb64:
          pdl_interp.check_result_count of %49 is 1 -> ^bb65, ^bb62
        ^bb65:
          %50 = pdl_interp.get_result 0 of %49
          pdl_interp.is_not_null %50 : !pdl.value -> ^bb66, ^bb62
        ^bb66:
          %51 = ematch.get_class_result %50
          pdl_interp.is_not_null %51 : !pdl.value -> ^bb67, ^bb62
        ^bb67:
          pdl_interp.are_equal %51, %40 : !pdl.value -> ^bb68, ^bb62
        ^bb68:
          %52 = pdl_interp.get_attribute "value" of %49
          pdl_interp.is_not_null %52 : !pdl.attribute -> ^bb69, ^bb62
        ^bb69:
          pdl_interp.check_attribute %52 is 8 : i32 -> ^bb70, ^bb71
        ^bb71:
          %53 = ematch.get_class_vals %37
          pdl_interp.foreach %54 : !pdl.value in %53 {
            %55 = pdl_interp.get_defining_op of %54 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
            pdl_interp.is_not_null %55 : !pdl.operation -> ^bb72, ^bb73
          ^bb73:
            pdl_interp.continue
          ^bb72:
            pdl_interp.check_operation_name of %55 is "arith.extui" -> ^bb74, ^bb73
          ^bb74:
            pdl_interp.check_operand_count of %55 is 1 -> ^bb75, ^bb73
          ^bb75:
            pdl_interp.check_result_count of %55 is 1 -> ^bb76, ^bb73
          ^bb76:
            %56 = pdl_interp.get_operand 0 of %55
            pdl_interp.is_not_null %56 : !pdl.value -> ^bb77, ^bb73
          ^bb77:
            %57 = pdl_interp.get_result 0 of %55
            pdl_interp.is_not_null %57 : !pdl.value -> ^bb78, ^bb73
          ^bb78:
            %58 = ematch.get_class_result %57
            pdl_interp.is_not_null %58 : !pdl.value -> ^bb79, ^bb73
          ^bb79:
            pdl_interp.are_equal %58, %37 : !pdl.value -> ^bb80, ^bb73
          ^bb80:
            %59 = pdl_interp.get_value_type of %58 : !pdl.type
            %60 = pdl_interp.get_value_type of %51 : !pdl.type
            pdl_interp.are_equal %59, %60 : !pdl.type -> ^bb81, ^bb73
          ^bb81:
            %61 = pdl_interp.get_value_type of %39 : !pdl.type
            pdl_interp.are_equal %59, %61 : !pdl.type -> ^bb82, ^bb73
          ^bb82:
            %62 = pdl_interp.get_value_type of %45 : !pdl.type
            pdl_interp.are_equal %59, %62 : !pdl.type -> ^bb83, ^bb73
          ^bb83:
            %63 = pdl_interp.get_value_type of %3 : !pdl.type
            pdl_interp.are_equal %59, %63 : !pdl.type -> ^bb84, ^bb73
          ^bb84:
            %64 = ematch.get_class_vals %46
            pdl_interp.foreach %65 : !pdl.value in %64 {
              %66 = pdl_interp.get_defining_op of %65 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
              pdl_interp.is_not_null %66 : !pdl.operation -> ^bb85, ^bb86
            ^bb86:
              pdl_interp.continue
            ^bb85:
              %67 = pdl_interp.get_result 0 of %66
              pdl_interp.is_not_null %67 : !pdl.value -> ^bb87, ^bb86
            ^bb87:
              %68 = ematch.get_class_result %67
              pdl_interp.are_equal %68, %46 : !pdl.value -> ^bb88, ^bb86
            ^bb88:
              %69 = ematch.get_class_vals %56
              pdl_interp.foreach %70 : !pdl.value in %69 {
                %71 = pdl_interp.get_defining_op of %70 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                pdl_interp.is_not_null %71 : !pdl.operation -> ^bb89, ^bb90
              ^bb90:
                pdl_interp.continue
              ^bb89:
                pdl_interp.check_operation_name of %71 is "arith.mului_extended" -> ^bb91, ^bb90
              ^bb91:
                pdl_interp.check_operand_count of %71 is 2 -> ^bb92, ^bb90
              ^bb92:
                pdl_interp.check_result_count of %71 is 2 -> ^bb93, ^bb90
              ^bb93:
                %72 = pdl_interp.get_operand 0 of %71
                pdl_interp.is_not_null %72 : !pdl.value -> ^bb94, ^bb90
              ^bb94:
                %73 = pdl_interp.get_result 0 of %71
                pdl_interp.is_not_null %73 : !pdl.value -> ^bb95, ^bb90
              ^bb95:
                %74 = ematch.get_class_result %73
                pdl_interp.is_not_null %74 : !pdl.value -> ^bb96, ^bb90
              ^bb96:
                pdl_interp.are_equal %71, %66 : !pdl.operation -> ^bb97, ^bb90
              ^bb97:
                %75 = pdl_interp.get_operand 1 of %71
                pdl_interp.is_not_null %75 : !pdl.value -> ^bb98, ^bb90
              ^bb98:
                %76 = pdl_interp.get_result 1 of %71
                pdl_interp.is_not_null %76 : !pdl.value -> ^bb99, ^bb90
              ^bb99:
                %77 = ematch.get_class_result %76
                pdl_interp.is_not_null %77 : !pdl.value -> ^bb100, ^bb90
              ^bb100:
                pdl_interp.are_equal %77, %56 : !pdl.value -> ^bb101, ^bb90
              ^bb101:
                %78 = pdl_interp.get_value_type of %72 : !pdl.type
                %79 = pdl_interp.get_value_type of %75 : !pdl.type
                pdl_interp.are_equal %78, %79 : !pdl.type -> ^bb102, ^bb90
              ^bb102:
                %80 = pdl_interp.get_value_type of %74 : !pdl.type
                pdl_interp.are_equal %78, %80 : !pdl.type -> ^bb103, ^bb90
              ^bb103:
                %81 = pdl_interp.get_value_type of %77 : !pdl.type
                pdl_interp.are_equal %78, %81 : !pdl.type -> ^bb104, ^bb90
              ^bb104:
                %82 = ematch.get_class_representative %72
                %83 = ematch.get_class_representative %75
                pdl_interp.record_match @rewriters::@MulxFuse(%82, %59, %83, %0 : !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(4), loc([]), root("arith.addi") -> ^bb90
              } -> ^bb86
            } -> ^bb73
          } -> ^bb62
        ^bb70:
          %84 = ematch.get_class_vals %37
          pdl_interp.foreach %85 : !pdl.value in %84 {
            %86 = pdl_interp.get_defining_op of %85 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
            pdl_interp.is_not_null %86 : !pdl.operation -> ^bb105, ^bb106
          ^bb106:
            pdl_interp.continue
          ^bb105:
            pdl_interp.check_operation_name of %86 is "arith.extui" -> ^bb107, ^bb106
          ^bb107:
            pdl_interp.check_operand_count of %86 is 1 -> ^bb108, ^bb106
          ^bb108:
            pdl_interp.check_result_count of %86 is 1 -> ^bb109, ^bb106
          ^bb109:
            %87 = pdl_interp.get_operand 0 of %86
            pdl_interp.is_not_null %87 : !pdl.value -> ^bb110, ^bb106
          ^bb110:
            %88 = pdl_interp.get_result 0 of %86
            pdl_interp.is_not_null %88 : !pdl.value -> ^bb111, ^bb106
          ^bb111:
            %89 = ematch.get_class_result %88
            pdl_interp.is_not_null %89 : !pdl.value -> ^bb112, ^bb106
          ^bb112:
            pdl_interp.are_equal %89, %37 : !pdl.value -> ^bb113, ^bb106
          ^bb113:
            %90 = pdl_interp.get_value_type of %89 : !pdl.type
            %91 = pdl_interp.get_value_type of %51 : !pdl.type
            pdl_interp.are_equal %90, %91 : !pdl.type -> ^bb114, ^bb106
          ^bb114:
            %92 = pdl_interp.get_value_type of %39 : !pdl.type
            pdl_interp.are_equal %90, %92 : !pdl.type -> ^bb115, ^bb106
          ^bb115:
            %93 = pdl_interp.get_value_type of %45 : !pdl.type
            pdl_interp.are_equal %90, %93 : !pdl.type -> ^bb116, ^bb106
          ^bb116:
            %94 = pdl_interp.get_value_type of %3 : !pdl.type
            pdl_interp.are_equal %90, %94 : !pdl.type -> ^bb117, ^bb106
          ^bb117:
            pdl_interp.check_type %90 is i32 -> ^bb118, ^bb106
          ^bb118:
            %95 = ematch.get_class_vals %46
            pdl_interp.foreach %96 : !pdl.value in %95 {
              %97 = pdl_interp.get_defining_op of %96 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
              pdl_interp.is_not_null %97 : !pdl.operation -> ^bb119, ^bb120
            ^bb120:
              pdl_interp.continue
            ^bb119:
              %98 = pdl_interp.get_result 0 of %97
              pdl_interp.is_not_null %98 : !pdl.value -> ^bb121, ^bb120
            ^bb121:
              %99 = ematch.get_class_result %98
              pdl_interp.are_equal %99, %46 : !pdl.value -> ^bb122, ^bb120
            ^bb122:
              pdl_interp.check_operation_name of %97 is "arith.trunci" -> ^bb123, ^bb120
            ^bb123:
              pdl_interp.check_operand_count of %97 is 1 -> ^bb124, ^bb120
            ^bb124:
              pdl_interp.check_result_count of %97 is 1 -> ^bb125, ^bb120
            ^bb125:
              pdl_interp.is_not_null %99 : !pdl.value -> ^bb126, ^bb120
            ^bb126:
              %100 = ematch.get_class_vals %87
              pdl_interp.foreach %101 : !pdl.value in %100 {
                %102 = pdl_interp.get_defining_op of %101 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                pdl_interp.is_not_null %102 : !pdl.operation -> ^bb127, ^bb128
              ^bb128:
                pdl_interp.continue
              ^bb127:
                pdl_interp.check_operation_name of %102 is "arith.trunci" -> ^bb129, ^bb128
              ^bb129:
                pdl_interp.check_operand_count of %102 is 1 -> ^bb130, ^bb128
              ^bb130:
                pdl_interp.check_result_count of %102 is 1 -> ^bb131, ^bb128
              ^bb131:
                %103 = pdl_interp.get_operand 0 of %102
                pdl_interp.is_not_null %103 : !pdl.value -> ^bb132, ^bb128
              ^bb132:
                %104 = pdl_interp.get_result 0 of %102
                pdl_interp.is_not_null %104 : !pdl.value -> ^bb133, ^bb128
              ^bb133:
                %105 = ematch.get_class_result %104
                pdl_interp.is_not_null %105 : !pdl.value -> ^bb134, ^bb128
              ^bb134:
                pdl_interp.are_equal %105, %87 : !pdl.value -> ^bb135, ^bb128
              ^bb135:
                %106 = pdl_interp.get_value_type of %105 : !pdl.type
                %107 = pdl_interp.get_value_type of %99 : !pdl.type
                pdl_interp.are_equal %106, %107 : !pdl.type -> ^bb136, ^bb128
              ^bb136:
                pdl_interp.check_type %106 is i8 -> ^bb137, ^bb128
              ^bb137:
                %108 = ematch.get_class_vals %103
                pdl_interp.foreach %109 : !pdl.value in %108 {
                  %110 = pdl_interp.get_defining_op of %109 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                  pdl_interp.is_not_null %110 : !pdl.operation -> ^bb138, ^bb139
                ^bb139:
                  pdl_interp.continue
                ^bb138:
                  pdl_interp.check_operation_name of %110 is "arith.shrui" -> ^bb140, ^bb139
                ^bb140:
                  pdl_interp.check_operand_count of %110 is 2 -> ^bb141, ^bb139
                ^bb141:
                  pdl_interp.check_result_count of %110 is 1 -> ^bb142, ^bb139
                ^bb142:
                  %111 = pdl_interp.get_operand 0 of %110
                  pdl_interp.is_not_null %111 : !pdl.value -> ^bb143, ^bb139
                ^bb143:
                  %112 = pdl_interp.get_operand 1 of %110
                  pdl_interp.is_not_null %112 : !pdl.value -> ^bb144, ^bb139
                ^bb144:
                  %113 = pdl_interp.get_operand 0 of %97
                  pdl_interp.are_equal %111, %113 : !pdl.value -> ^bb145, ^bb139
                ^bb145:
                  %114 = pdl_interp.get_result 0 of %110
                  pdl_interp.is_not_null %114 : !pdl.value -> ^bb146, ^bb139
                ^bb146:
                  %115 = ematch.get_class_result %114
                  pdl_interp.is_not_null %115 : !pdl.value -> ^bb147, ^bb139
                ^bb147:
                  pdl_interp.are_equal %115, %103 : !pdl.value -> ^bb148, ^bb139
                ^bb148:
                  %116 = pdl_interp.get_value_type of %111 : !pdl.type
                  %117 = pdl_interp.get_value_type of %115 : !pdl.type
                  pdl_interp.are_equal %116, %117 : !pdl.type -> ^bb149, ^bb139
                ^bb149:
                  pdl_interp.check_type %116 is i16 -> ^bb150, ^bb139
                ^bb150:
                  %118 = ematch.get_class_vals %112
                  pdl_interp.foreach %119 : !pdl.value in %118 {
                    %120 = pdl_interp.get_defining_op of %119 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op"}
                    pdl_interp.is_not_null %120 : !pdl.operation -> ^bb151, ^bb152
                  ^bb152:
                    pdl_interp.continue
                  ^bb151:
                    pdl_interp.check_operation_name of %120 is "arith.constant" -> ^bb153, ^bb152
                  ^bb153:
                    pdl_interp.check_operand_count of %120 is 0 -> ^bb154, ^bb152
                  ^bb154:
                    pdl_interp.check_result_count of %120 is 1 -> ^bb155, ^bb152
                  ^bb155:
                    %121 = pdl_interp.get_attribute "value" of %120
                    pdl_interp.is_not_null %121 : !pdl.attribute -> ^bb156, ^bb152
                  ^bb156:
                    pdl_interp.check_attribute %121 is 8 : i16 -> ^bb157, ^bb152
                  ^bb157:
                    %122 = pdl_interp.get_result 0 of %120
                    pdl_interp.is_not_null %122 : !pdl.value -> ^bb158, ^bb152
                  ^bb158:
                    %123 = ematch.get_class_result %122
                    pdl_interp.is_not_null %123 : !pdl.value -> ^bb159, ^bb152
                  ^bb159:
                    pdl_interp.are_equal %123, %112 : !pdl.value -> ^bb160, ^bb152
                  ^bb160:
                    %124 = pdl_interp.get_value_type of %123 : !pdl.type
                    pdl_interp.are_equal %124, %116 : !pdl.type -> ^bb161, ^bb152
                  ^bb161:
                    %125 = ematch.get_class_representative %111
                    pdl_interp.record_match @rewriters::@BytesRecompose(%125, %0 : !pdl.value, !pdl.operation) : benefit(4), loc([]), root("arith.addi") -> ^bb152
                  } -> ^bb139
                } -> ^bb128
              } -> ^bb120
            } -> ^bb106
          } -> ^bb71
        } -> ^bb53
      } -> ^bb15
    } -> ^bb5
  ^bb12:
    %126 = pdl_interp.get_value_type of %4 : !pdl.type
    pdl_interp.are_equal %5, %126 : !pdl.type -> ^bb162, ^bb163
  ^bb163:
    pdl_interp.check_type %5 is i32 -> ^bb164, ^bb165
  ^bb165:
    %127 = ematch.get_class_vals %4
    pdl_interp.foreach %128 : !pdl.value in %127 {
      %129 = pdl_interp.get_defining_op of %128 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %129 : !pdl.operation -> ^bb166, ^bb167
    ^bb167:
      pdl_interp.continue
    ^bb166:
      pdl_interp.check_operation_name of %129 is "arith.addi" -> ^bb168, ^bb167
    ^bb168:
      pdl_interp.check_operand_count of %129 is 2 -> ^bb169, ^bb167
    ^bb169:
      pdl_interp.check_result_count of %129 is 1 -> ^bb170, ^bb167
    ^bb170:
      %130 = pdl_interp.get_result 0 of %129
      pdl_interp.is_not_null %130 : !pdl.value -> ^bb171, ^bb167
    ^bb171:
      %131 = ematch.get_class_result %130
      pdl_interp.is_not_null %131 : !pdl.value -> ^bb172, ^bb167
    ^bb172:
      pdl_interp.are_equal %131, %4 : !pdl.value -> ^bb173, ^bb167
    ^bb173:
      %132 = pdl_interp.get_operand 0 of %129
      pdl_interp.is_not_null %132 : !pdl.value -> ^bb174, ^bb167
    ^bb174:
      %133 = pdl_interp.get_value_type of %131 : !pdl.type
      pdl_interp.are_equal %133, %5 : !pdl.type -> ^bb175, ^bb167
    ^bb175:
      %134 = pdl_interp.get_operand 1 of %129
      pdl_interp.is_not_null %134 : !pdl.value -> ^bb176, ^bb167
    ^bb176:
      %135 = pdl_interp.get_value_type of %132 : !pdl.type
      pdl_interp.are_equal %135, %5 : !pdl.type -> ^bb177, ^bb167
    ^bb177:
      %136 = pdl_interp.get_value_type of %134 : !pdl.type
      pdl_interp.are_equal %136, %5 : !pdl.type -> ^bb178, ^bb167
    ^bb178:
      %137 = ematch.get_class_representative %1
      %138 = ematch.get_class_representative %132
      %139 = ematch.get_class_representative %134
      pdl_interp.record_match @rewriters::@AddAssoc(%137, %138, %5, %139, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb167
    } -> ^bb13
  ^bb164:
    %140 = ematch.get_class_vals %4
    pdl_interp.foreach %141 : !pdl.value in %140 {
      %142 = pdl_interp.get_defining_op of %141 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %142 : !pdl.operation -> ^bb179, ^bb180
    ^bb180:
      pdl_interp.continue
    ^bb179:
      pdl_interp.check_operation_name of %142 is "arith.constant" -> ^bb181, ^bb180
    ^bb181:
      pdl_interp.check_operand_count of %142 is 0 -> ^bb182, ^bb180
    ^bb182:
      pdl_interp.check_result_count of %142 is 1 -> ^bb183, ^bb180
    ^bb183:
      %143 = pdl_interp.get_result 0 of %142
      pdl_interp.is_not_null %143 : !pdl.value -> ^bb184, ^bb180
    ^bb184:
      %144 = ematch.get_class_result %143
      pdl_interp.is_not_null %144 : !pdl.value -> ^bb185, ^bb180
    ^bb185:
      pdl_interp.are_equal %144, %4 : !pdl.value -> ^bb186, ^bb180
    ^bb186:
      %145 = pdl_interp.get_value_type of %144 : !pdl.type
      pdl_interp.are_equal %145, %5 : !pdl.type -> ^bb187, ^bb180
    ^bb187:
      %146 = pdl_interp.get_attribute "value" of %142
      pdl_interp.is_not_null %146 : !pdl.attribute -> ^bb188, ^bb180
    ^bb188:
      %147 = ematch.get_class_representative %1
      pdl_interp.record_match @rewriters::@AddZero(%147, %0 : !pdl.value, !pdl.operation) : benefit(2), loc([]), root("arith.addi") -> ^bb180
    } -> ^bb165
  ^bb162:
    %148 = ematch.get_class_representative %4
    %149 = ematch.get_class_representative %1
    pdl_interp.record_match @rewriters::@AddComm(%148, %149, %5, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb163
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb189, ^bb5
  ^bb189:
    pdl_interp.check_result_count of %0 is 1 -> ^bb190, ^bb5
  ^bb190:
    %150 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %150 : !pdl.value -> ^bb191, ^bb5
  ^bb191:
    %151 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %151 : !pdl.value -> ^bb192, ^bb5
  ^bb192:
    %152 = ematch.get_class_result %151
    pdl_interp.is_not_null %152 : !pdl.value -> ^bb193, ^bb5
  ^bb193:
    %153 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %153 : !pdl.value -> ^bb194, ^bb5
  ^bb194:
    %154 = pdl_interp.get_value_type of %150 : !pdl.type
    %155 = pdl_interp.get_value_type of %152 : !pdl.type
    pdl_interp.are_equal %154, %155 : !pdl.type -> ^bb195, ^bb5
  ^bb195:
    %156 = pdl_interp.get_value_type of %153 : !pdl.type
    pdl_interp.are_equal %154, %156 : !pdl.type -> ^bb196, ^bb197
  ^bb197:
    %157 = ematch.get_class_vals %153
    pdl_interp.foreach %158 : !pdl.value in %157 {
      %159 = pdl_interp.get_defining_op of %158 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %159 : !pdl.operation -> ^bb198, ^bb199
    ^bb199:
      pdl_interp.continue
    ^bb198:
      pdl_interp.switch_operation_name of %159 to ["arith.muli", "arith.addi"](^bb200, ^bb201) -> ^bb199
    ^bb200:
      pdl_interp.check_operand_count of %159 is 2 -> ^bb202, ^bb199
    ^bb202:
      pdl_interp.check_result_count of %159 is 1 -> ^bb203, ^bb199
    ^bb203:
      %160 = pdl_interp.get_result 0 of %159
      pdl_interp.is_not_null %160 : !pdl.value -> ^bb204, ^bb199
    ^bb204:
      %161 = ematch.get_class_result %160
      pdl_interp.is_not_null %161 : !pdl.value -> ^bb205, ^bb199
    ^bb205:
      pdl_interp.are_equal %161, %153 : !pdl.value -> ^bb206, ^bb199
    ^bb206:
      %162 = pdl_interp.get_operand 0 of %159
      pdl_interp.is_not_null %162 : !pdl.value -> ^bb207, ^bb199
    ^bb207:
      %163 = pdl_interp.get_value_type of %161 : !pdl.type
      pdl_interp.are_equal %163, %154 : !pdl.type -> ^bb208, ^bb199
    ^bb208:
      %164 = pdl_interp.get_operand 1 of %159
      pdl_interp.is_not_null %164 : !pdl.value -> ^bb209, ^bb199
    ^bb209:
      %165 = pdl_interp.get_value_type of %162 : !pdl.type
      pdl_interp.are_equal %165, %154 : !pdl.type -> ^bb210, ^bb199
    ^bb210:
      %166 = pdl_interp.get_value_type of %164 : !pdl.type
      pdl_interp.are_equal %166, %154 : !pdl.type -> ^bb211, ^bb199
    ^bb211:
      %167 = ematch.get_class_representative %150
      %168 = ematch.get_class_representative %162
      %169 = ematch.get_class_representative %164
      pdl_interp.record_match @rewriters::@MulAssoc(%167, %168, %154, %169, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb199
    ^bb201:
      pdl_interp.check_operand_count of %159 is 2 -> ^bb212, ^bb199
    ^bb212:
      pdl_interp.check_result_count of %159 is 1 -> ^bb213, ^bb199
    ^bb213:
      %170 = pdl_interp.get_result 0 of %159
      pdl_interp.is_not_null %170 : !pdl.value -> ^bb214, ^bb199
    ^bb214:
      %171 = ematch.get_class_result %170
      pdl_interp.is_not_null %171 : !pdl.value -> ^bb215, ^bb199
    ^bb215:
      pdl_interp.are_equal %171, %153 : !pdl.value -> ^bb216, ^bb199
    ^bb216:
      %172 = pdl_interp.get_operand 0 of %159
      pdl_interp.is_not_null %172 : !pdl.value -> ^bb217, ^bb199
    ^bb217:
      %173 = pdl_interp.get_value_type of %171 : !pdl.type
      pdl_interp.are_equal %173, %154 : !pdl.type -> ^bb218, ^bb199
    ^bb218:
      %174 = pdl_interp.get_operand 1 of %159
      pdl_interp.is_not_null %174 : !pdl.value -> ^bb219, ^bb199
    ^bb219:
      %175 = pdl_interp.get_value_type of %172 : !pdl.type
      pdl_interp.are_equal %175, %154 : !pdl.type -> ^bb220, ^bb199
    ^bb220:
      %176 = pdl_interp.get_value_type of %174 : !pdl.type
      pdl_interp.are_equal %176, %154 : !pdl.type -> ^bb221, ^bb199
    ^bb221:
      %177 = ematch.get_class_representative %150
      %178 = ematch.get_class_representative %172
      %179 = ematch.get_class_representative %174
      pdl_interp.record_match @rewriters::@DistributeMult(%177, %178, %154, %179, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb199
    } -> ^bb5
  ^bb196:
    %180 = ematch.get_class_representative %153
    %181 = ematch.get_class_representative %150
    pdl_interp.record_match @rewriters::@MulComm(%180, %181, %154, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb197
  ^bb2:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb222, ^bb5
  ^bb222:
    pdl_interp.check_result_count of %0 is 1 -> ^bb223, ^bb5
  ^bb223:
    %182 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %182 : !pdl.value -> ^bb224, ^bb5
  ^bb224:
    %183 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %183 : !pdl.value -> ^bb225, ^bb5
  ^bb225:
    %184 = ematch.get_class_result %183
    pdl_interp.is_not_null %184 : !pdl.value -> ^bb226, ^bb5
  ^bb226:
    %185 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %185 : !pdl.value -> ^bb227, ^bb228
  ^bb228:
    %186 = pdl_interp.get_value_type of %182 : !pdl.type
    %187 = pdl_interp.get_value_type of %184 : !pdl.type
    pdl_interp.are_equal %186, %187 : !pdl.type -> ^bb229, ^bb5
  ^bb229:
    pdl_interp.check_type %186 is i32 -> ^bb230, ^bb5
  ^bb230:
    %188 = pdl_interp.get_operand 1 of %0
    pdl_interp.are_equal %182, %188 : !pdl.value -> ^bb231, ^bb5
  ^bb231:
    pdl_interp.record_match @rewriters::@SubSame(%0 : !pdl.operation) : benefit(2), loc([]), root("arith.subi") -> ^bb5
  ^bb227:
    %189 = ematch.get_class_vals %182
    pdl_interp.foreach %190 : !pdl.value in %189 {
      %191 = pdl_interp.get_defining_op of %190 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %191 : !pdl.operation -> ^bb232, ^bb233
    ^bb233:
      pdl_interp.continue
    ^bb232:
      pdl_interp.check_operation_name of %191 is "arith.addi" -> ^bb234, ^bb233
    ^bb234:
      pdl_interp.check_operand_count of %191 is 2 -> ^bb235, ^bb233
    ^bb235:
      pdl_interp.check_result_count of %191 is 1 -> ^bb236, ^bb233
    ^bb236:
      %192 = pdl_interp.get_operand 0 of %191
      pdl_interp.is_not_null %192 : !pdl.value -> ^bb237, ^bb233
    ^bb237:
      %193 = pdl_interp.get_result 0 of %191
      pdl_interp.is_not_null %193 : !pdl.value -> ^bb238, ^bb233
    ^bb238:
      %194 = ematch.get_class_result %193
      pdl_interp.is_not_null %194 : !pdl.value -> ^bb239, ^bb233
    ^bb239:
      pdl_interp.are_equal %194, %182 : !pdl.value -> ^bb240, ^bb233
    ^bb240:
      %195 = pdl_interp.get_operand 1 of %191
      pdl_interp.is_not_null %195 : !pdl.value -> ^bb241, ^bb233
    ^bb241:
      %196 = pdl_interp.get_value_type of %192 : !pdl.type
      %197 = pdl_interp.get_value_type of %195 : !pdl.type
      pdl_interp.are_equal %196, %197 : !pdl.type -> ^bb242, ^bb233
    ^bb242:
      %198 = pdl_interp.get_value_type of %194 : !pdl.type
      pdl_interp.are_equal %196, %198 : !pdl.type -> ^bb243, ^bb233
    ^bb243:
      %199 = pdl_interp.get_value_type of %184 : !pdl.type
      pdl_interp.are_equal %196, %199 : !pdl.type -> ^bb244, ^bb233
    ^bb244:
      %200 = pdl_interp.get_value_type of %185 : !pdl.type
      pdl_interp.are_equal %196, %200 : !pdl.type -> ^bb245, ^bb233
    ^bb245:
      %201 = ematch.get_class_representative %192
      %202 = ematch.get_class_representative %185
      %203 = ematch.get_class_representative %195
      pdl_interp.record_match @rewriters::@AssocAddSub(%201, %202, %196, %203, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.subi") -> ^bb233
    } -> ^bb228
  ^bb3:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb246, ^bb5
  ^bb246:
    pdl_interp.check_result_count of %0 is 1 -> ^bb247, ^bb5
  ^bb247:
    %204 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %204 : !pdl.value -> ^bb248, ^bb5
  ^bb248:
    %205 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %205 : !pdl.value -> ^bb249, ^bb5
  ^bb249:
    %206 = ematch.get_class_result %205
    pdl_interp.is_not_null %206 : !pdl.value -> ^bb250, ^bb5
  ^bb250:
    %207 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %207 : !pdl.value -> ^bb251, ^bb5
  ^bb251:
    %208 = pdl_interp.get_value_type of %204 : !pdl.type
    %209 = pdl_interp.get_value_type of %206 : !pdl.type
    pdl_interp.are_equal %208, %209 : !pdl.type -> ^bb252, ^bb253
  ^bb253:
    %210 = ematch.get_class_vals %204
    pdl_interp.foreach %211 : !pdl.value in %210 {
      %212 = pdl_interp.get_defining_op of %211 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %212 : !pdl.operation -> ^bb254, ^bb255
    ^bb255:
      pdl_interp.continue
    ^bb254:
      pdl_interp.switch_operation_name of %212 to ["arith.muli", "arith.addi"](^bb256, ^bb257) -> ^bb255
    ^bb256:
      pdl_interp.check_operand_count of %212 is 2 -> ^bb258, ^bb255
    ^bb258:
      pdl_interp.check_result_count of %212 is 1 -> ^bb259, ^bb255
    ^bb259:
      %213 = pdl_interp.get_operand 0 of %212
      pdl_interp.is_not_null %213 : !pdl.value -> ^bb260, ^bb255
    ^bb260:
      %214 = pdl_interp.get_result 0 of %212
      pdl_interp.is_not_null %214 : !pdl.value -> ^bb261, ^bb255
    ^bb261:
      %215 = ematch.get_class_result %214
      pdl_interp.is_not_null %215 : !pdl.value -> ^bb262, ^bb255
    ^bb262:
      pdl_interp.are_equal %215, %204 : !pdl.value -> ^bb263, ^bb255
    ^bb263:
      %216 = pdl_interp.get_operand 1 of %212
      pdl_interp.is_not_null %216 : !pdl.value -> ^bb264, ^bb255
    ^bb264:
      %217 = pdl_interp.get_value_type of %213 : !pdl.type
      %218 = pdl_interp.get_value_type of %216 : !pdl.type
      pdl_interp.are_equal %217, %218 : !pdl.type -> ^bb265, ^bb255
    ^bb265:
      %219 = pdl_interp.get_value_type of %215 : !pdl.type
      pdl_interp.are_equal %217, %219 : !pdl.type -> ^bb266, ^bb255
    ^bb266:
      %220 = pdl_interp.get_value_type of %206 : !pdl.type
      pdl_interp.are_equal %217, %220 : !pdl.type -> ^bb267, ^bb255
    ^bb267:
      %221 = pdl_interp.get_value_type of %207 : !pdl.type
      pdl_interp.are_equal %217, %221 : !pdl.type -> ^bb268, ^bb255
    ^bb268:
      %222 = ematch.get_class_representative %216
      %223 = ematch.get_class_representative %207
      %224 = ematch.get_class_representative %213
      pdl_interp.record_match @rewriters::@ShiftMul1(%222, %223, %217, %224, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.shli") -> ^bb255
    ^bb257:
      pdl_interp.check_operand_count of %212 is 2 -> ^bb269, ^bb255
    ^bb269:
      pdl_interp.check_result_count of %212 is 1 -> ^bb270, ^bb255
    ^bb270:
      %225 = pdl_interp.get_operand 0 of %212
      pdl_interp.is_not_null %225 : !pdl.value -> ^bb271, ^bb255
    ^bb271:
      %226 = pdl_interp.get_result 0 of %212
      pdl_interp.is_not_null %226 : !pdl.value -> ^bb272, ^bb255
    ^bb272:
      %227 = ematch.get_class_result %226
      pdl_interp.is_not_null %227 : !pdl.value -> ^bb273, ^bb255
    ^bb273:
      pdl_interp.are_equal %227, %204 : !pdl.value -> ^bb274, ^bb255
    ^bb274:
      %228 = pdl_interp.get_operand 1 of %212
      pdl_interp.is_not_null %228 : !pdl.value -> ^bb275, ^bb255
    ^bb275:
      %229 = pdl_interp.get_value_type of %225 : !pdl.type
      %230 = pdl_interp.get_value_type of %228 : !pdl.type
      pdl_interp.are_equal %229, %230 : !pdl.type -> ^bb276, ^bb255
    ^bb276:
      %231 = pdl_interp.get_value_type of %227 : !pdl.type
      pdl_interp.are_equal %229, %231 : !pdl.type -> ^bb277, ^bb255
    ^bb277:
      %232 = pdl_interp.get_value_type of %206 : !pdl.type
      pdl_interp.are_equal %229, %232 : !pdl.type -> ^bb278, ^bb255
    ^bb278:
      %233 = pdl_interp.get_value_type of %207 : !pdl.type
      pdl_interp.are_equal %229, %233 : !pdl.type -> ^bb279, ^bb255
    ^bb279:
      %234 = ematch.get_class_representative %225
      %235 = ematch.get_class_representative %207
      %236 = ematch.get_class_representative %228
      pdl_interp.record_match @rewriters::@ShiftAdd(%234, %235, %229, %236, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.shli") -> ^bb255
    } -> ^bb5
  ^bb252:
    pdl_interp.check_type %208 is i32 -> ^bb280, ^bb253
  ^bb280:
    %237 = ematch.get_class_vals %207
    pdl_interp.foreach %238 : !pdl.value in %237 {
      %239 = pdl_interp.get_defining_op of %238 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %239 : !pdl.operation -> ^bb281, ^bb282
    ^bb282:
      pdl_interp.continue
    ^bb281:
      pdl_interp.check_operation_name of %239 is "arith.constant" -> ^bb283, ^bb282
    ^bb283:
      pdl_interp.check_operand_count of %239 is 0 -> ^bb284, ^bb282
    ^bb284:
      pdl_interp.check_result_count of %239 is 1 -> ^bb285, ^bb282
    ^bb285:
      %240 = pdl_interp.get_result 0 of %239
      pdl_interp.is_not_null %240 : !pdl.value -> ^bb286, ^bb282
    ^bb286:
      %241 = ematch.get_class_result %240
      pdl_interp.is_not_null %241 : !pdl.value -> ^bb287, ^bb282
    ^bb287:
      pdl_interp.are_equal %241, %207 : !pdl.value -> ^bb288, ^bb282
    ^bb288:
      %242 = pdl_interp.get_value_type of %241 : !pdl.type
      pdl_interp.are_equal %242, %208 : !pdl.type -> ^bb289, ^bb282
    ^bb289:
      %243 = pdl_interp.get_attribute "value" of %239
      pdl_interp.is_not_null %243 : !pdl.attribute -> ^bb290, ^bb282
    ^bb290:
      pdl_interp.check_attribute %243 is 16 : i32 -> ^bb291, ^bb282
    ^bb291:
      %244 = ematch.get_class_representative %204
      pdl_interp.record_match @rewriters::@ShiftSplit16(%244, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.shli") -> ^bb282
    } -> ^bb253
  ^bb4:
    pdl_interp.check_operand_count of %0 is 1 -> ^bb292, ^bb5
  ^bb292:
    pdl_interp.check_result_count of %0 is 1 -> ^bb293, ^bb5
  ^bb293:
    %245 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %245 : !pdl.value -> ^bb294, ^bb5
  ^bb294:
    %246 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %246 : !pdl.value -> ^bb295, ^bb5
  ^bb295:
    %247 = ematch.get_class_result %246
    pdl_interp.is_not_null %247 : !pdl.value -> ^bb296, ^bb5
  ^bb296:
    %248 = ematch.get_class_vals %245
    pdl_interp.foreach %249 : !pdl.value in %248 {
      %250 = pdl_interp.get_defining_op of %249 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %250 : !pdl.operation -> ^bb297, ^bb298
    ^bb298:
      pdl_interp.continue
    ^bb297:
      pdl_interp.switch_operation_name of %250 to ["arith.extui", "arith.addi"](^bb299, ^bb300) -> ^bb298
    ^bb299:
      pdl_interp.check_operand_count of %250 is 1 -> ^bb301, ^bb298
    ^bb301:
      pdl_interp.check_result_count of %250 is 1 -> ^bb302, ^bb298
    ^bb302:
      %251 = pdl_interp.get_operand 0 of %250
      pdl_interp.is_not_null %251 : !pdl.value -> ^bb303, ^bb298
    ^bb303:
      %252 = pdl_interp.get_result 0 of %250
      pdl_interp.is_not_null %252 : !pdl.value -> ^bb304, ^bb298
    ^bb304:
      %253 = ematch.get_class_result %252
      pdl_interp.is_not_null %253 : !pdl.value -> ^bb305, ^bb298
    ^bb305:
      pdl_interp.are_equal %253, %245 : !pdl.value -> ^bb306, ^bb298
    ^bb306:
      %254 = pdl_interp.get_value_type of %247 : !pdl.type
      %255 = ematch.get_class_representative %251
      pdl_interp.record_match @rewriters::@ZextCompose(%255, %254, %0 : !pdl.value, !pdl.type, !pdl.operation) : benefit(3), loc([]), root("arith.extui") -> ^bb298
    ^bb300:
      pdl_interp.check_operand_count of %250 is 2 -> ^bb307, ^bb298
    ^bb307:
      pdl_interp.check_result_count of %250 is 1 -> ^bb308, ^bb298
    ^bb308:
      %256 = pdl_interp.get_operand 0 of %250
      pdl_interp.is_not_null %256 : !pdl.value -> ^bb309, ^bb298
    ^bb309:
      %257 = pdl_interp.get_result 0 of %250
      pdl_interp.is_not_null %257 : !pdl.value -> ^bb310, ^bb298
    ^bb310:
      %258 = ematch.get_class_result %257
      pdl_interp.is_not_null %258 : !pdl.value -> ^bb311, ^bb298
    ^bb311:
      pdl_interp.are_equal %258, %245 : !pdl.value -> ^bb312, ^bb298
    ^bb312:
      %259 = pdl_interp.get_operand 1 of %250
      pdl_interp.is_not_null %259 : !pdl.value -> ^bb313, ^bb298
    ^bb313:
      %260 = ematch.get_class_vals %259
      pdl_interp.foreach %261 : !pdl.value in %260 {
        %262 = pdl_interp.get_defining_op of %261 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op"}
        pdl_interp.is_not_null %262 : !pdl.operation -> ^bb314, ^bb315
      ^bb315:
        pdl_interp.continue
      ^bb314:
        pdl_interp.check_operation_name of %262 is "arith.extui" -> ^bb316, ^bb315
      ^bb316:
        pdl_interp.check_operand_count of %262 is 1 -> ^bb317, ^bb315
      ^bb317:
        pdl_interp.check_result_count of %262 is 1 -> ^bb318, ^bb315
      ^bb318:
        %263 = pdl_interp.get_result 0 of %262
        pdl_interp.is_not_null %263 : !pdl.value -> ^bb319, ^bb315
      ^bb319:
        %264 = ematch.get_class_result %263
        pdl_interp.is_not_null %264 : !pdl.value -> ^bb320, ^bb315
      ^bb320:
        pdl_interp.are_equal %264, %259 : !pdl.value -> ^bb321, ^bb315
      ^bb321:
        %265 = pdl_interp.get_operand 0 of %262
        pdl_interp.is_not_null %265 : !pdl.value -> ^bb322, ^bb315
      ^bb322:
        %266 = ematch.get_class_vals %256
        pdl_interp.foreach %267 : !pdl.value in %266 {
          %268 = pdl_interp.get_defining_op of %267 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
          pdl_interp.is_not_null %268 : !pdl.operation -> ^bb323, ^bb324
        ^bb324:
          pdl_interp.continue
        ^bb323:
          pdl_interp.check_operation_name of %268 is "arith.extui" -> ^bb325, ^bb324
        ^bb325:
          pdl_interp.check_operand_count of %268 is 1 -> ^bb326, ^bb324
        ^bb326:
          pdl_interp.check_result_count of %268 is 1 -> ^bb327, ^bb324
        ^bb327:
          %269 = pdl_interp.get_operand 0 of %268
          pdl_interp.is_not_null %269 : !pdl.value -> ^bb328, ^bb324
        ^bb328:
          %270 = pdl_interp.get_result 0 of %268
          pdl_interp.is_not_null %270 : !pdl.value -> ^bb329, ^bb324
        ^bb329:
          %271 = ematch.get_class_result %270
          pdl_interp.is_not_null %271 : !pdl.value -> ^bb330, ^bb324
        ^bb330:
          pdl_interp.are_equal %271, %256 : !pdl.value -> ^bb331, ^bb324
        ^bb331:
          %272 = pdl_interp.get_value_type of %271 : !pdl.type
          %273 = pdl_interp.get_value_type of %264 : !pdl.type
          pdl_interp.are_equal %272, %273 : !pdl.type -> ^bb332, ^bb324
        ^bb332:
          %274 = pdl_interp.get_value_type of %258 : !pdl.type
          pdl_interp.are_equal %272, %274 : !pdl.type -> ^bb333, ^bb324
        ^bb333:
          %275 = pdl_interp.get_value_type of %247 : !pdl.type
          %276 = ematch.get_class_representative %256
          %277 = ematch.get_class_representative %259
          pdl_interp.record_match @rewriters::@ZextAdd(%276, %275, %277, %0 : !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(3), loc([]), root("arith.extui") -> ^bb324
        } -> ^bb315
      } -> ^bb298
    } -> ^bb5
  }
  builtin.module @rewriters {
    pdl_interp.func @UndistributeRight(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.addi"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.muli"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @UndistributeLeft(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.addi"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.muli"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MulxFuse(%0: !pdl.value, %1: !pdl.type, %2: !pdl.value, %3: !pdl.operation) {
      %4 = ematch.get_class_result %0
      %5 = pdl_interp.create_operation "arith.extui"(%4 : !pdl.value) -> (%1 : !pdl.type)
      %6 = ematch.dedup %5
      %7 = pdl_interp.get_result 0 of %6
      %8 = ematch.get_class_result %7
      %9 = ematch.get_class_result %2
      %10 = pdl_interp.create_operation "arith.extui"(%9 : !pdl.value) -> (%1 : !pdl.type)
      %11 = ematch.dedup %10
      %12 = pdl_interp.get_result 0 of %11
      %13 = ematch.get_class_result %12
      %14 = pdl_interp.create_operation "arith.muli"(%8, %13 : !pdl.value, !pdl.value) -> (%1 : !pdl.type)
      %15 = ematch.dedup %14
      %16 = pdl_interp.get_results of %15 : !pdl.range<value>
      %17 = ematch.get_class_results %16
      ematch.union %3 : !pdl.operation, %17 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @BytesRecompose(%0: !pdl.value, %1: !pdl.operation) {
      %2 = ematch.get_class_result %0
      %3 = pdl_interp.create_type i32
      %4 = pdl_interp.create_operation "arith.extui"(%2 : !pdl.value) -> (%3 : !pdl.type)
      %5 = ematch.dedup %4
      %6 = pdl_interp.get_results of %5 : !pdl.range<value>
      %7 = ematch.get_class_results %6
      ematch.union %1 : !pdl.operation, %7 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AddAssoc(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.addi"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.addi"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AddZero(%0: !pdl.value, %1: !pdl.operation) {
      %2 = ematch.get_class_result %0
      %3 = pdl_interp.create_range %2 : !pdl.value
      ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AddComm(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.operation) {
      %4 = ematch.get_class_result %0
      %5 = ematch.get_class_result %1
      %6 = pdl_interp.create_operation "arith.addi"(%4, %5 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %7 = ematch.dedup %6
      %8 = pdl_interp.get_results of %7 : !pdl.range<value>
      %9 = ematch.get_class_results %8
      ematch.union %3 : !pdl.operation, %9 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MulAssoc(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.muli"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.muli"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @DistributeMult(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.muli"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.muli"(%5, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_result 0 of %13
      %15 = ematch.get_class_result %14
      %16 = pdl_interp.create_operation "arith.addi"(%10, %15 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %17 = ematch.dedup %16
      %18 = pdl_interp.get_results of %17 : !pdl.range<value>
      %19 = ematch.get_class_results %18
      ematch.union %4 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @MulComm(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.operation) {
      %4 = ematch.get_class_result %0
      %5 = ematch.get_class_result %1
      %6 = pdl_interp.create_operation "arith.muli"(%4, %5 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %7 = ematch.dedup %6
      %8 = pdl_interp.get_results of %7 : !pdl.range<value>
      %9 = ematch.get_class_results %8
      ematch.union %3 : !pdl.operation, %9 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @SubSame(%0: !pdl.operation) {
      %1 = pdl_interp.create_attribute 0 : i32
      %2 = pdl_interp.create_type i32
      %3 = pdl_interp.create_operation "arith.constant" {"value" = %1} -> (%2 : !pdl.type)
      %4 = ematch.dedup %3
      %5 = pdl_interp.get_result 0 of %4
      %6 = ematch.get_class_result %5
      %7 = pdl_interp.create_range %6 : !pdl.value
      ematch.union %0 : !pdl.operation, %7 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @AssocAddSub(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.subi"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.addi"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @ShiftMul1(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.shli"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.muli"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_results of %13 : !pdl.range<value>
      %15 = ematch.get_class_results %14
      ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @ShiftAdd(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
      %5 = ematch.get_class_result %0
      %6 = ematch.get_class_result %1
      %7 = pdl_interp.create_operation "arith.shli"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %8 = ematch.dedup %7
      %9 = pdl_interp.get_result 0 of %8
      %10 = ematch.get_class_result %9
      %11 = ematch.get_class_result %3
      %12 = pdl_interp.create_operation "arith.shli"(%11, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %13 = ematch.dedup %12
      %14 = pdl_interp.get_result 0 of %13
      %15 = ematch.get_class_result %14
      %16 = pdl_interp.create_operation "arith.addi"(%10, %15 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
      %17 = ematch.dedup %16
      %18 = pdl_interp.get_results of %17 : !pdl.range<value>
      %19 = ematch.get_class_results %18
      ematch.union %4 : !pdl.operation, %19 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @ShiftSplit16(%0: !pdl.value, %1: !pdl.operation) {
      %2 = pdl_interp.create_attribute 8 : i32
      %3 = pdl_interp.create_type i32
      %4 = pdl_interp.create_operation "arith.constant" {"value" = %2} -> (%3 : !pdl.type)
      %5 = ematch.dedup %4
      %6 = pdl_interp.get_result 0 of %5
      %7 = ematch.get_class_result %6
      %8 = ematch.get_class_result %0
      %9 = pdl_interp.create_operation "arith.shli"(%8, %7 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %10 = ematch.dedup %9
      %11 = pdl_interp.get_result 0 of %10
      %12 = ematch.get_class_result %11
      %13 = pdl_interp.create_operation "arith.shli"(%12, %7 : !pdl.value, !pdl.value) -> (%3 : !pdl.type)
      %14 = ematch.dedup %13
      %15 = pdl_interp.get_results of %14 : !pdl.range<value>
      %16 = ematch.get_class_results %15
      ematch.union %1 : !pdl.operation, %16 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @ZextCompose(%0: !pdl.value, %1: !pdl.type, %2: !pdl.operation) {
      %3 = ematch.get_class_result %0
      %4 = pdl_interp.create_operation "arith.extui"(%3 : !pdl.value) -> (%1 : !pdl.type)
      %5 = ematch.dedup %4
      %6 = pdl_interp.get_results of %5 : !pdl.range<value>
      %7 = ematch.get_class_results %6
      ematch.union %2 : !pdl.operation, %7 : !pdl.range<value>
      pdl_interp.finalize
    }
    pdl_interp.func @ZextAdd(%0: !pdl.value, %1: !pdl.type, %2: !pdl.value, %3: !pdl.operation) {
      %4 = ematch.get_class_result %0
      %5 = pdl_interp.create_operation "arith.extui"(%4 : !pdl.value) -> (%1 : !pdl.type)
      %6 = ematch.dedup %5
      %7 = pdl_interp.get_result 0 of %6
      %8 = ematch.get_class_result %7
      %9 = ematch.get_class_result %2
      %10 = pdl_interp.create_operation "arith.extui"(%9 : !pdl.value) -> (%1 : !pdl.type)
      %11 = ematch.dedup %10
      %12 = pdl_interp.get_result 0 of %11
      %13 = ematch.get_class_result %12
      %14 = pdl_interp.create_operation "arith.addi"(%8, %13 : !pdl.value, !pdl.value) -> (%1 : !pdl.type)
      %15 = ematch.dedup %14
      %16 = pdl_interp.get_results of %15 : !pdl.range<value>
      %17 = ematch.get_class_results %16
      ematch.union %3 : !pdl.operation, %17 : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}

