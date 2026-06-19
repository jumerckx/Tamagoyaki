builtin.module {
  pdl_interp.func @matcher(%0: !pdl.operation) {
    pdl_interp.switch_operation_name of %0 to ["arith.muli", "arith.addi"](^bb0, ^bb1) -> ^bb2
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
      pdl_interp.check_operation_name of %7 is "arith.extui" -> ^bb11, ^bb10
    ^bb11:
      pdl_interp.check_operand_count of %7 is 1 -> ^bb12, ^bb10
    ^bb12:
      pdl_interp.check_result_count of %7 is 1 -> ^bb13, ^bb10
    ^bb13:
      %8 = pdl_interp.get_operand 0 of %7
      pdl_interp.is_not_null %8 : !pdl.value -> ^bb14, ^bb10
    ^bb14:
      %9 = pdl_interp.get_result 0 of %7
      pdl_interp.is_not_null %9 : !pdl.value -> ^bb15, ^bb10
    ^bb15:
      %10 = ematch.get_class_result %9
      pdl_interp.is_not_null %10 : !pdl.value -> ^bb16, ^bb10
    ^bb16:
      pdl_interp.are_equal %10, %1 : !pdl.value -> ^bb17, ^bb10
    ^bb17:
      pdl_interp.apply_constraint "is_arg_0"(%8 : !pdl.value) -> ^bb18, ^bb10
    ^bb18:
      %11 = pdl_interp.get_value_type of %10 : !pdl.type
      %12 = pdl_interp.get_value_type of %4 : !pdl.type
      pdl_interp.are_equal %11, %12 : !pdl.type -> ^bb19, ^bb10
    ^bb19:
      %13 = pdl_interp.get_value_type of %8 : !pdl.type
      pdl_interp.check_type %13 is i16 -> ^bb20, ^bb10
    ^bb20:
      pdl_interp.check_type %11 is i32 -> ^bb21, ^bb10
    ^bb21:
      %14 = ematch.get_class_vals %2
      pdl_interp.foreach %15 : !pdl.value in %14 {
        %16 = pdl_interp.get_defining_op of %15 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %16 : !pdl.operation -> ^bb22, ^bb23
      ^bb23:
        pdl_interp.continue
      ^bb22:
        pdl_interp.check_operation_name of %16 is "arith.extui" -> ^bb24, ^bb23
      ^bb24:
        pdl_interp.check_operand_count of %16 is 1 -> ^bb25, ^bb23
      ^bb25:
        pdl_interp.check_result_count of %16 is 1 -> ^bb26, ^bb23
      ^bb26:
        %17 = pdl_interp.get_result 0 of %16
        pdl_interp.is_not_null %17 : !pdl.value -> ^bb27, ^bb23
      ^bb27:
        %18 = ematch.get_class_result %17
        pdl_interp.is_not_null %18 : !pdl.value -> ^bb28, ^bb23
      ^bb28:
        pdl_interp.are_equal %18, %2 : !pdl.value -> ^bb29, ^bb23
      ^bb29:
        %19 = pdl_interp.get_operand 0 of %16
        pdl_interp.is_not_null %19 : !pdl.value -> ^bb30, ^bb23
      ^bb30:
        pdl_interp.apply_constraint "is_arg_1"(%19 : !pdl.value) -> ^bb31, ^bb23
      ^bb31:
        %20 = pdl_interp.get_value_type of %19 : !pdl.type
        pdl_interp.are_equal %13, %20 : !pdl.type -> ^bb32, ^bb23
      ^bb32:
        %21 = pdl_interp.get_value_type of %18 : !pdl.type
        pdl_interp.are_equal %11, %21 : !pdl.type -> ^bb33, ^bb23
      ^bb33:
        pdl_interp.record_match @rewriters::@SimplifiedProduct(%0 : !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb23
      } -> ^bb10
    } -> ^bb2
  ^bb1:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb34, ^bb2
  ^bb34:
    pdl_interp.check_result_count of %0 is 1 -> ^bb35, ^bb2
  ^bb35:
    %22 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %22 : !pdl.value -> ^bb36, ^bb2
  ^bb36:
    %23 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %23 : !pdl.value -> ^bb37, ^bb2
  ^bb37:
    %24 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %24 : !pdl.value -> ^bb38, ^bb2
  ^bb38:
    %25 = ematch.get_class_result %24
    pdl_interp.is_not_null %25 : !pdl.value -> ^bb39, ^bb2
  ^bb39:
    %26 = ematch.get_class_vals %22
    pdl_interp.foreach %27 : !pdl.value in %26 {
      %28 = pdl_interp.get_defining_op of %27 : !pdl.value {position = "root.operand[0].defining_op"}
      pdl_interp.is_not_null %28 : !pdl.operation -> ^bb40, ^bb41
    ^bb41:
      pdl_interp.continue
    ^bb40:
      pdl_interp.check_operation_name of %28 is "arith.addi" -> ^bb42, ^bb41
    ^bb42:
      pdl_interp.check_operand_count of %28 is 2 -> ^bb43, ^bb41
    ^bb43:
      pdl_interp.check_result_count of %28 is 1 -> ^bb44, ^bb41
    ^bb44:
      %29 = pdl_interp.get_operand 0 of %28
      pdl_interp.is_not_null %29 : !pdl.value -> ^bb45, ^bb41
    ^bb45:
      %30 = pdl_interp.get_result 0 of %28
      pdl_interp.is_not_null %30 : !pdl.value -> ^bb46, ^bb41
    ^bb46:
      %31 = ematch.get_class_result %30
      pdl_interp.is_not_null %31 : !pdl.value -> ^bb47, ^bb41
    ^bb47:
      pdl_interp.are_equal %31, %22 : !pdl.value -> ^bb48, ^bb41
    ^bb48:
      %32 = pdl_interp.get_operand 1 of %28
      pdl_interp.is_not_null %32 : !pdl.value -> ^bb49, ^bb41
    ^bb49:
      %33 = ematch.get_class_vals %23
      pdl_interp.foreach %34 : !pdl.value in %33 {
        %35 = pdl_interp.get_defining_op of %34 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %35 : !pdl.operation -> ^bb50, ^bb51
      ^bb51:
        pdl_interp.continue
      ^bb50:
        pdl_interp.check_operation_name of %35 is "arith.muli" -> ^bb52, ^bb51
      ^bb52:
        pdl_interp.check_operand_count of %35 is 2 -> ^bb53, ^bb51
      ^bb53:
        pdl_interp.check_result_count of %35 is 1 -> ^bb54, ^bb51
      ^bb54:
        %36 = pdl_interp.get_result 0 of %35
        pdl_interp.is_not_null %36 : !pdl.value -> ^bb55, ^bb51
      ^bb55:
        %37 = ematch.get_class_result %36
        pdl_interp.is_not_null %37 : !pdl.value -> ^bb56, ^bb51
      ^bb56:
        pdl_interp.are_equal %37, %23 : !pdl.value -> ^bb57, ^bb51
      ^bb57:
        %38 = ematch.get_class_vals %29
        pdl_interp.foreach %39 : !pdl.value in %38 {
          %40 = pdl_interp.get_defining_op of %39 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op"}
          pdl_interp.is_not_null %40 : !pdl.operation -> ^bb58, ^bb59
        ^bb59:
          pdl_interp.continue
        ^bb58:
          pdl_interp.check_operation_name of %40 is "arith.shli" -> ^bb60, ^bb59
        ^bb60:
          pdl_interp.check_operand_count of %40 is 2 -> ^bb61, ^bb59
        ^bb61:
          pdl_interp.check_result_count of %40 is 1 -> ^bb62, ^bb59
        ^bb62:
          %41 = pdl_interp.get_operand 0 of %40
          pdl_interp.is_not_null %41 : !pdl.value -> ^bb63, ^bb59
        ^bb63:
          %42 = pdl_interp.get_operand 1 of %40
          pdl_interp.is_not_null %42 : !pdl.value -> ^bb64, ^bb59
        ^bb64:
          %43 = pdl_interp.get_result 0 of %40
          pdl_interp.is_not_null %43 : !pdl.value -> ^bb65, ^bb59
        ^bb65:
          %44 = ematch.get_class_result %43
          pdl_interp.is_not_null %44 : !pdl.value -> ^bb66, ^bb59
        ^bb66:
          pdl_interp.are_equal %44, %29 : !pdl.value -> ^bb67, ^bb59
        ^bb67:
          %45 = ematch.get_class_vals %32
          pdl_interp.foreach %46 : !pdl.value in %45 {
            %47 = pdl_interp.get_defining_op of %46 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op"}
            pdl_interp.is_not_null %47 : !pdl.operation -> ^bb68, ^bb69
          ^bb69:
            pdl_interp.continue
          ^bb68:
            pdl_interp.check_operation_name of %47 is "arith.shli" -> ^bb70, ^bb69
          ^bb70:
            pdl_interp.check_operand_count of %47 is 2 -> ^bb71, ^bb69
          ^bb71:
            pdl_interp.check_result_count of %47 is 1 -> ^bb72, ^bb69
          ^bb72:
            %48 = pdl_interp.get_operand 0 of %47
            pdl_interp.is_not_null %48 : !pdl.value -> ^bb73, ^bb69
          ^bb73:
            %49 = pdl_interp.get_operand 1 of %47
            pdl_interp.is_not_null %49 : !pdl.value -> ^bb74, ^bb69
          ^bb74:
            %50 = pdl_interp.get_result 0 of %47
            pdl_interp.is_not_null %50 : !pdl.value -> ^bb75, ^bb69
          ^bb75:
            %51 = ematch.get_class_result %50
            pdl_interp.is_not_null %51 : !pdl.value -> ^bb76, ^bb69
          ^bb76:
            pdl_interp.are_equal %51, %32 : !pdl.value -> ^bb77, ^bb69
          ^bb77:
            %52 = ematch.get_class_vals %42
            pdl_interp.foreach %53 : !pdl.value in %52 {
              %54 = pdl_interp.get_defining_op of %53 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op"}
              pdl_interp.is_not_null %54 : !pdl.operation -> ^bb78, ^bb79
            ^bb79:
              pdl_interp.continue
            ^bb78:
              pdl_interp.check_operation_name of %54 is "arith.constant" -> ^bb80, ^bb79
            ^bb80:
              pdl_interp.check_operand_count of %54 is 0 -> ^bb81, ^bb79
            ^bb81:
              pdl_interp.check_result_count of %54 is 1 -> ^bb82, ^bb79
            ^bb82:
              %55 = pdl_interp.get_attribute "value" of %54
              pdl_interp.is_not_null %55 : !pdl.attribute -> ^bb83, ^bb79
            ^bb83:
              pdl_interp.check_attribute %55 is 16 : i32 -> ^bb84, ^bb79
            ^bb84:
              %56 = pdl_interp.get_result 0 of %54
              pdl_interp.is_not_null %56 : !pdl.value -> ^bb85, ^bb79
            ^bb85:
              %57 = ematch.get_class_result %56
              pdl_interp.is_not_null %57 : !pdl.value -> ^bb86, ^bb79
            ^bb86:
              pdl_interp.are_equal %57, %42 : !pdl.value -> ^bb87, ^bb79
            ^bb87:
              %58 = ematch.get_class_vals %48
              pdl_interp.foreach %59 : !pdl.value in %58 {
                %60 = pdl_interp.get_defining_op of %59 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op"}
                pdl_interp.is_not_null %60 : !pdl.operation -> ^bb88, ^bb89
              ^bb89:
                pdl_interp.continue
              ^bb88:
                pdl_interp.check_operation_name of %60 is "arith.addi" -> ^bb90, ^bb89
              ^bb90:
                pdl_interp.check_operand_count of %60 is 2 -> ^bb91, ^bb89
              ^bb91:
                pdl_interp.check_result_count of %60 is 1 -> ^bb92, ^bb89
              ^bb92:
                %61 = pdl_interp.get_operand 0 of %60
                pdl_interp.is_not_null %61 : !pdl.value -> ^bb93, ^bb89
              ^bb93:
                %62 = pdl_interp.get_operand 1 of %60
                pdl_interp.is_not_null %62 : !pdl.value -> ^bb94, ^bb89
              ^bb94:
                %63 = pdl_interp.get_result 0 of %60
                pdl_interp.is_not_null %63 : !pdl.value -> ^bb95, ^bb89
              ^bb95:
                %64 = ematch.get_class_result %63
                pdl_interp.is_not_null %64 : !pdl.value -> ^bb96, ^bb89
              ^bb96:
                pdl_interp.are_equal %64, %48 : !pdl.value -> ^bb97, ^bb89
              ^bb97:
                %65 = ematch.get_class_vals %41
                pdl_interp.foreach %66 : !pdl.value in %65 {
                  %67 = pdl_interp.get_defining_op of %66 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                  pdl_interp.is_not_null %67 : !pdl.operation -> ^bb98, ^bb99
                ^bb99:
                  pdl_interp.continue
                ^bb98:
                  pdl_interp.check_operation_name of %67 is "arith.muli" -> ^bb100, ^bb99
                ^bb100:
                  pdl_interp.check_operand_count of %67 is 2 -> ^bb101, ^bb99
                ^bb101:
                  pdl_interp.check_result_count of %67 is 1 -> ^bb102, ^bb99
                ^bb102:
                  %68 = pdl_interp.get_operand 0 of %67
                  pdl_interp.is_not_null %68 : !pdl.value -> ^bb103, ^bb99
                ^bb103:
                  %69 = pdl_interp.get_operand 1 of %67
                  pdl_interp.is_not_null %69 : !pdl.value -> ^bb104, ^bb99
                ^bb104:
                  %70 = pdl_interp.get_result 0 of %67
                  pdl_interp.is_not_null %70 : !pdl.value -> ^bb105, ^bb99
                ^bb105:
                  %71 = ematch.get_class_result %70
                  pdl_interp.is_not_null %71 : !pdl.value -> ^bb106, ^bb99
                ^bb106:
                  pdl_interp.are_equal %71, %41 : !pdl.value -> ^bb107, ^bb99
                ^bb107:
                  %72 = ematch.get_class_vals %49
                  pdl_interp.foreach %73 : !pdl.value in %72 {
                    %74 = pdl_interp.get_defining_op of %73 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[1].defining_op"}
                    pdl_interp.is_not_null %74 : !pdl.operation -> ^bb108, ^bb109
                  ^bb109:
                    pdl_interp.continue
                  ^bb108:
                    pdl_interp.check_operation_name of %74 is "arith.constant" -> ^bb110, ^bb109
                  ^bb110:
                    pdl_interp.check_operand_count of %74 is 0 -> ^bb111, ^bb109
                  ^bb111:
                    pdl_interp.check_result_count of %74 is 1 -> ^bb112, ^bb109
                  ^bb112:
                    %75 = pdl_interp.get_attribute "value" of %74
                    pdl_interp.is_not_null %75 : !pdl.attribute -> ^bb113, ^bb109
                  ^bb113:
                    pdl_interp.check_attribute %75 is 8 : i32 -> ^bb114, ^bb109
                  ^bb114:
                    %76 = pdl_interp.get_result 0 of %74
                    pdl_interp.is_not_null %76 : !pdl.value -> ^bb115, ^bb109
                  ^bb115:
                    %77 = ematch.get_class_result %76
                    pdl_interp.is_not_null %77 : !pdl.value -> ^bb116, ^bb109
                  ^bb116:
                    pdl_interp.are_equal %77, %49 : !pdl.value -> ^bb117, ^bb109
                  ^bb117:
                    %78 = ematch.get_class_vals %62
                    pdl_interp.foreach %79 : !pdl.value in %78 {
                      %80 = pdl_interp.get_defining_op of %79 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[1].defining_op"}
                      pdl_interp.is_not_null %80 : !pdl.operation -> ^bb118, ^bb119
                    ^bb119:
                      pdl_interp.continue
                    ^bb118:
                      pdl_interp.check_operation_name of %80 is "arith.muli" -> ^bb120, ^bb119
                    ^bb120:
                      pdl_interp.check_operand_count of %80 is 2 -> ^bb121, ^bb119
                    ^bb121:
                      pdl_interp.check_result_count of %80 is 1 -> ^bb122, ^bb119
                    ^bb122:
                      %81 = pdl_interp.get_operand 1 of %80
                      pdl_interp.is_not_null %81 : !pdl.value -> ^bb123, ^bb119
                    ^bb123:
                      %82 = pdl_interp.get_result 0 of %80
                      pdl_interp.is_not_null %82 : !pdl.value -> ^bb124, ^bb119
                    ^bb124:
                      %83 = ematch.get_class_result %82
                      pdl_interp.is_not_null %83 : !pdl.value -> ^bb125, ^bb119
                    ^bb125:
                      pdl_interp.are_equal %83, %62 : !pdl.value -> ^bb126, ^bb119
                    ^bb126:
                      %84 = ematch.get_class_vals %61
                      pdl_interp.foreach %85 : !pdl.value in %84 {
                        %86 = pdl_interp.get_defining_op of %85 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[0].defining_op"}
                        pdl_interp.is_not_null %86 : !pdl.operation -> ^bb127, ^bb128
                      ^bb128:
                        pdl_interp.continue
                      ^bb127:
                        pdl_interp.check_operation_name of %86 is "arith.muli" -> ^bb129, ^bb128
                      ^bb129:
                        pdl_interp.check_operand_count of %86 is 2 -> ^bb130, ^bb128
                      ^bb130:
                        pdl_interp.check_result_count of %86 is 1 -> ^bb131, ^bb128
                      ^bb131:
                        %87 = pdl_interp.get_operand 0 of %86
                        pdl_interp.is_not_null %87 : !pdl.value -> ^bb132, ^bb128
                      ^bb132:
                        %88 = pdl_interp.get_result 0 of %86
                        pdl_interp.is_not_null %88 : !pdl.value -> ^bb133, ^bb128
                      ^bb133:
                        %89 = ematch.get_class_result %88
                        pdl_interp.is_not_null %89 : !pdl.value -> ^bb134, ^bb128
                      ^bb134:
                        pdl_interp.are_equal %89, %61 : !pdl.value -> ^bb135, ^bb128
                      ^bb135:
                        %90 = ematch.get_class_vals %69
                        pdl_interp.foreach %91 : !pdl.value in %90 {
                          %92 = pdl_interp.get_defining_op of %91 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op"}
                          pdl_interp.is_not_null %92 : !pdl.operation -> ^bb136, ^bb137
                        ^bb137:
                          pdl_interp.continue
                        ^bb136:
                          pdl_interp.check_operation_name of %92 is "arith.extui" -> ^bb138, ^bb137
                        ^bb138:
                          pdl_interp.check_operand_count of %92 is 1 -> ^bb139, ^bb137
                        ^bb139:
                          pdl_interp.check_result_count of %92 is 1 -> ^bb140, ^bb137
                        ^bb140:
                          %93 = pdl_interp.get_operand 0 of %92
                          pdl_interp.is_not_null %93 : !pdl.value -> ^bb141, ^bb137
                        ^bb141:
                          %94 = pdl_interp.get_result 0 of %92
                          pdl_interp.is_not_null %94 : !pdl.value -> ^bb142, ^bb137
                        ^bb142:
                          %95 = ematch.get_class_result %94
                          pdl_interp.is_not_null %95 : !pdl.value -> ^bb143, ^bb137
                        ^bb143:
                          pdl_interp.are_equal %95, %69 : !pdl.value -> ^bb144, ^bb137
                        ^bb144:
                          %96 = ematch.get_class_vals %68
                          pdl_interp.foreach %97 : !pdl.value in %96 {
                            %98 = pdl_interp.get_defining_op of %97 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                            pdl_interp.is_not_null %98 : !pdl.operation -> ^bb145, ^bb146
                          ^bb146:
                            pdl_interp.continue
                          ^bb145:
                            pdl_interp.check_operation_name of %98 is "arith.extui" -> ^bb147, ^bb146
                          ^bb147:
                            pdl_interp.check_operand_count of %98 is 1 -> ^bb148, ^bb146
                          ^bb148:
                            pdl_interp.check_result_count of %98 is 1 -> ^bb149, ^bb146
                          ^bb149:
                            %99 = pdl_interp.get_operand 0 of %98
                            pdl_interp.is_not_null %99 : !pdl.value -> ^bb150, ^bb146
                          ^bb150:
                            %100 = pdl_interp.get_result 0 of %98
                            pdl_interp.is_not_null %100 : !pdl.value -> ^bb151, ^bb146
                          ^bb151:
                            %101 = ematch.get_class_result %100
                            pdl_interp.is_not_null %101 : !pdl.value -> ^bb152, ^bb146
                          ^bb152:
                            pdl_interp.are_equal %101, %68 : !pdl.value -> ^bb153, ^bb146
                          ^bb153:
                            %102 = pdl_interp.get_value_type of %101 : !pdl.type
                            %103 = pdl_interp.get_value_type of %95 : !pdl.type
                            pdl_interp.are_equal %102, %103 : !pdl.type -> ^bb154, ^bb146
                          ^bb154:
                            %104 = pdl_interp.get_value_type of %71 : !pdl.type
                            pdl_interp.are_equal %102, %104 : !pdl.type -> ^bb155, ^bb146
                          ^bb155:
                            %105 = pdl_interp.get_value_type of %57 : !pdl.type
                            pdl_interp.are_equal %102, %105 : !pdl.type -> ^bb156, ^bb146
                          ^bb156:
                            %106 = pdl_interp.get_value_type of %44 : !pdl.type
                            pdl_interp.are_equal %102, %106 : !pdl.type -> ^bb157, ^bb146
                          ^bb157:
                            %107 = pdl_interp.get_value_type of %89 : !pdl.type
                            pdl_interp.are_equal %102, %107 : !pdl.type -> ^bb158, ^bb146
                          ^bb158:
                            %108 = pdl_interp.get_value_type of %83 : !pdl.type
                            pdl_interp.are_equal %102, %108 : !pdl.type -> ^bb159, ^bb146
                          ^bb159:
                            %109 = pdl_interp.get_value_type of %64 : !pdl.type
                            pdl_interp.are_equal %102, %109 : !pdl.type -> ^bb160, ^bb146
                          ^bb160:
                            %110 = pdl_interp.get_value_type of %77 : !pdl.type
                            pdl_interp.are_equal %102, %110 : !pdl.type -> ^bb161, ^bb146
                          ^bb161:
                            %111 = pdl_interp.get_value_type of %51 : !pdl.type
                            pdl_interp.are_equal %102, %111 : !pdl.type -> ^bb162, ^bb146
                          ^bb162:
                            %112 = pdl_interp.get_value_type of %31 : !pdl.type
                            pdl_interp.are_equal %102, %112 : !pdl.type -> ^bb163, ^bb146
                          ^bb163:
                            %113 = pdl_interp.get_value_type of %37 : !pdl.type
                            pdl_interp.are_equal %102, %113 : !pdl.type -> ^bb164, ^bb146
                          ^bb164:
                            %114 = pdl_interp.get_value_type of %25 : !pdl.type
                            pdl_interp.are_equal %102, %114 : !pdl.type -> ^bb165, ^bb146
                          ^bb165:
                            pdl_interp.check_type %102 is i32 -> ^bb166, ^bb146
                          ^bb166:
                            %115 = ematch.get_class_vals %81
                            pdl_interp.foreach %116 : !pdl.value in %115 {
                              %117 = pdl_interp.get_defining_op of %116 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[1].defining_op.operand[1].defining_op"}
                              pdl_interp.is_not_null %117 : !pdl.operation -> ^bb167, ^bb168
                            ^bb168:
                              pdl_interp.continue
                            ^bb167:
                              pdl_interp.check_operation_name of %117 is "arith.extui" -> ^bb169, ^bb168
                            ^bb169:
                              pdl_interp.check_operand_count of %117 is 1 -> ^bb170, ^bb168
                            ^bb170:
                              pdl_interp.check_result_count of %117 is 1 -> ^bb171, ^bb168
                            ^bb171:
                              %118 = pdl_interp.get_operand 0 of %117
                              pdl_interp.is_not_null %118 : !pdl.value -> ^bb172, ^bb168
                            ^bb172:
                              %119 = pdl_interp.get_result 0 of %117
                              pdl_interp.is_not_null %119 : !pdl.value -> ^bb173, ^bb168
                            ^bb173:
                              %120 = ematch.get_class_result %119
                              pdl_interp.is_not_null %120 : !pdl.value -> ^bb174, ^bb168
                            ^bb174:
                              pdl_interp.are_equal %120, %81 : !pdl.value -> ^bb175, ^bb168
                            ^bb175:
                              %121 = pdl_interp.get_value_type of %120 : !pdl.type
                              pdl_interp.are_equal %121, %102 : !pdl.type -> ^bb176, ^bb168
                            ^bb176:
                              %122 = ematch.get_class_vals %87
                              pdl_interp.foreach %123 : !pdl.value in %122 {
                                %124 = pdl_interp.get_defining_op of %123 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                                pdl_interp.is_not_null %124 : !pdl.operation -> ^bb177, ^bb178
                              ^bb178:
                                pdl_interp.continue
                              ^bb177:
                                pdl_interp.check_operation_name of %124 is "arith.extui" -> ^bb179, ^bb178
                              ^bb179:
                                pdl_interp.check_operand_count of %124 is 1 -> ^bb180, ^bb178
                              ^bb180:
                                pdl_interp.check_result_count of %124 is 1 -> ^bb181, ^bb178
                              ^bb181:
                                %125 = pdl_interp.get_operand 0 of %124
                                pdl_interp.is_not_null %125 : !pdl.value -> ^bb182, ^bb178
                              ^bb182:
                                %126 = pdl_interp.get_result 0 of %124
                                pdl_interp.is_not_null %126 : !pdl.value -> ^bb183, ^bb178
                              ^bb183:
                                %127 = ematch.get_class_result %126
                                pdl_interp.is_not_null %127 : !pdl.value -> ^bb184, ^bb178
                              ^bb184:
                                pdl_interp.are_equal %127, %87 : !pdl.value -> ^bb185, ^bb178
                              ^bb185:
                                %128 = pdl_interp.get_value_type of %127 : !pdl.type
                                pdl_interp.are_equal %128, %102 : !pdl.type -> ^bb186, ^bb178
                              ^bb186:
                                %129 = ematch.get_class_vals %93
                                pdl_interp.foreach %130 : !pdl.value in %129 {
                                  %131 = pdl_interp.get_defining_op of %130 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op"}
                                  pdl_interp.is_not_null %131 : !pdl.operation -> ^bb187, ^bb188
                                ^bb188:
                                  pdl_interp.continue
                                ^bb187:
                                  pdl_interp.check_operation_name of %131 is "arith.trunci" -> ^bb189, ^bb188
                                ^bb189:
                                  pdl_interp.check_operand_count of %131 is 1 -> ^bb190, ^bb188
                                ^bb190:
                                  pdl_interp.check_result_count of %131 is 1 -> ^bb191, ^bb188
                                ^bb191:
                                  %132 = pdl_interp.get_operand 0 of %131
                                  pdl_interp.is_not_null %132 : !pdl.value -> ^bb192, ^bb188
                                ^bb192:
                                  %133 = pdl_interp.get_result 0 of %131
                                  pdl_interp.is_not_null %133 : !pdl.value -> ^bb193, ^bb188
                                ^bb193:
                                  %134 = ematch.get_class_result %133
                                  pdl_interp.is_not_null %134 : !pdl.value -> ^bb194, ^bb188
                                ^bb194:
                                  pdl_interp.are_equal %134, %93 : !pdl.value -> ^bb195, ^bb188
                                ^bb195:
                                  %135 = ematch.get_class_vals %99
                                  pdl_interp.foreach %136 : !pdl.value in %135 {
                                    %137 = pdl_interp.get_defining_op of %136 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                                    pdl_interp.is_not_null %137 : !pdl.operation -> ^bb196, ^bb197
                                  ^bb197:
                                    pdl_interp.continue
                                  ^bb196:
                                    pdl_interp.check_operation_name of %137 is "arith.trunci" -> ^bb198, ^bb197
                                  ^bb198:
                                    pdl_interp.check_operand_count of %137 is 1 -> ^bb199, ^bb197
                                  ^bb199:
                                    pdl_interp.check_result_count of %137 is 1 -> ^bb200, ^bb197
                                  ^bb200:
                                    %138 = pdl_interp.get_operand 0 of %137
                                    pdl_interp.is_not_null %138 : !pdl.value -> ^bb201, ^bb197
                                  ^bb201:
                                    %139 = pdl_interp.get_result 0 of %137
                                    pdl_interp.is_not_null %139 : !pdl.value -> ^bb202, ^bb197
                                  ^bb202:
                                    %140 = ematch.get_class_result %139
                                    pdl_interp.is_not_null %140 : !pdl.value -> ^bb203, ^bb197
                                  ^bb203:
                                    pdl_interp.are_equal %140, %99 : !pdl.value -> ^bb204, ^bb197
                                  ^bb204:
                                    %141 = pdl_interp.get_value_type of %140 : !pdl.type
                                    %142 = pdl_interp.get_value_type of %134 : !pdl.type
                                    pdl_interp.are_equal %141, %142 : !pdl.type -> ^bb205, ^bb197
                                  ^bb205:
                                    pdl_interp.check_type %141 is i8 -> ^bb206, ^bb197
                                  ^bb206:
                                    %143 = ematch.get_class_vals %125
                                    pdl_interp.foreach %144 : !pdl.value in %143 {
                                      %145 = pdl_interp.get_defining_op of %144 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                                      pdl_interp.is_not_null %145 : !pdl.operation -> ^bb207, ^bb208
                                    ^bb208:
                                      pdl_interp.continue
                                    ^bb207:
                                      pdl_interp.check_operation_name of %145 is "arith.trunci" -> ^bb209, ^bb208
                                    ^bb209:
                                      pdl_interp.check_operand_count of %145 is 1 -> ^bb210, ^bb208
                                    ^bb210:
                                      pdl_interp.check_result_count of %145 is 1 -> ^bb211, ^bb208
                                    ^bb211:
                                      %146 = pdl_interp.get_result 0 of %145
                                      pdl_interp.is_not_null %146 : !pdl.value -> ^bb212, ^bb208
                                    ^bb212:
                                      %147 = ematch.get_class_result %146
                                      pdl_interp.is_not_null %147 : !pdl.value -> ^bb213, ^bb208
                                    ^bb213:
                                      pdl_interp.are_equal %147, %125 : !pdl.value -> ^bb214, ^bb208
                                    ^bb214:
                                      %148 = pdl_interp.get_value_type of %147 : !pdl.type
                                      pdl_interp.are_equal %148, %141 : !pdl.type -> ^bb215, ^bb208
                                    ^bb215:
                                      %149 = ematch.get_class_vals %138
                                      pdl_interp.foreach %150 : !pdl.value in %149 {
                                        %151 = pdl_interp.get_defining_op of %150 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op"}
                                        pdl_interp.is_not_null %151 : !pdl.operation -> ^bb216, ^bb217
                                      ^bb217:
                                        pdl_interp.continue
                                      ^bb216:
                                        pdl_interp.check_operation_name of %151 is "arith.shrui" -> ^bb218, ^bb217
                                      ^bb218:
                                        pdl_interp.check_operand_count of %151 is 2 -> ^bb219, ^bb217
                                      ^bb219:
                                        pdl_interp.check_result_count of %151 is 1 -> ^bb220, ^bb217
                                      ^bb220:
                                        %152 = pdl_interp.get_operand 0 of %151
                                        pdl_interp.is_not_null %152 : !pdl.value -> ^bb221, ^bb217
                                      ^bb221:
                                        %153 = pdl_interp.get_operand 1 of %151
                                        pdl_interp.is_not_null %153 : !pdl.value -> ^bb222, ^bb217
                                      ^bb222:
                                        %154 = pdl_interp.get_operand 0 of %145
                                        pdl_interp.are_equal %152, %154 : !pdl.value -> ^bb223, ^bb217
                                      ^bb223:
                                        pdl_interp.apply_constraint "is_arg_0"(%152 : !pdl.value) -> ^bb224, ^bb217
                                      ^bb224:
                                        %155 = pdl_interp.get_result 0 of %151
                                        pdl_interp.is_not_null %155 : !pdl.value -> ^bb225, ^bb217
                                      ^bb225:
                                        %156 = ematch.get_class_result %155
                                        pdl_interp.is_not_null %156 : !pdl.value -> ^bb226, ^bb217
                                      ^bb226:
                                        pdl_interp.are_equal %156, %138 : !pdl.value -> ^bb227, ^bb217
                                      ^bb227:
                                        %157 = pdl_interp.get_value_type of %152 : !pdl.type
                                        %158 = pdl_interp.get_value_type of %156 : !pdl.type
                                        pdl_interp.are_equal %157, %158 : !pdl.type -> ^bb228, ^bb217
                                      ^bb228:
                                        pdl_interp.check_type %157 is i16 -> ^bb229, ^bb217
                                      ^bb229:
                                        %159 = ematch.get_class_vals %132
                                        pdl_interp.foreach %160 : !pdl.value in %159 {
                                          %161 = pdl_interp.get_defining_op of %160 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[0].defining_op"}
                                          pdl_interp.is_not_null %161 : !pdl.operation -> ^bb230, ^bb231
                                        ^bb231:
                                          pdl_interp.continue
                                        ^bb230:
                                          pdl_interp.check_operation_name of %161 is "arith.shrui" -> ^bb232, ^bb231
                                        ^bb232:
                                          pdl_interp.check_operand_count of %161 is 2 -> ^bb233, ^bb231
                                        ^bb233:
                                          pdl_interp.check_result_count of %161 is 1 -> ^bb234, ^bb231
                                        ^bb234:
                                          %162 = pdl_interp.get_operand 0 of %161
                                          pdl_interp.is_not_null %162 : !pdl.value -> ^bb235, ^bb231
                                        ^bb235:
                                          pdl_interp.apply_constraint "is_arg_1"(%162 : !pdl.value) -> ^bb236, ^bb231
                                        ^bb236:
                                          %163 = pdl_interp.get_result 0 of %161
                                          pdl_interp.is_not_null %163 : !pdl.value -> ^bb237, ^bb231
                                        ^bb237:
                                          %164 = ematch.get_class_result %163
                                          pdl_interp.is_not_null %164 : !pdl.value -> ^bb238, ^bb231
                                        ^bb238:
                                          pdl_interp.are_equal %164, %132 : !pdl.value -> ^bb239, ^bb231
                                        ^bb239:
                                          %165 = pdl_interp.get_value_type of %162 : !pdl.type
                                          pdl_interp.are_equal %157, %165 : !pdl.type -> ^bb240, ^bb231
                                        ^bb240:
                                          %166 = pdl_interp.get_value_type of %164 : !pdl.type
                                          pdl_interp.are_equal %157, %166 : !pdl.type -> ^bb241, ^bb231
                                        ^bb241:
                                          %167 = ematch.get_class_vals %118
                                          pdl_interp.foreach %168 : !pdl.value in %167 {
                                            %169 = pdl_interp.get_defining_op of %168 : !pdl.value {position = "root.operand[0].defining_op.operand[1].defining_op.operand[0].defining_op.operand[1].defining_op.operand[1].defining_op.operand[0].defining_op"}
                                            pdl_interp.is_not_null %169 : !pdl.operation -> ^bb242, ^bb243
                                          ^bb243:
                                            pdl_interp.continue
                                          ^bb242:
                                            pdl_interp.check_operation_name of %169 is "arith.trunci" -> ^bb244, ^bb243
                                          ^bb244:
                                            pdl_interp.check_operand_count of %169 is 1 -> ^bb245, ^bb243
                                          ^bb245:
                                            pdl_interp.check_result_count of %169 is 1 -> ^bb246, ^bb243
                                          ^bb246:
                                            %170 = pdl_interp.get_operand 0 of %169
                                            pdl_interp.are_equal %162, %170 : !pdl.value -> ^bb247, ^bb243
                                          ^bb247:
                                            %171 = pdl_interp.get_result 0 of %169
                                            pdl_interp.is_not_null %171 : !pdl.value -> ^bb248, ^bb243
                                          ^bb248:
                                            %172 = ematch.get_class_result %171
                                            pdl_interp.is_not_null %172 : !pdl.value -> ^bb249, ^bb243
                                          ^bb249:
                                            pdl_interp.are_equal %172, %118 : !pdl.value -> ^bb250, ^bb243
                                          ^bb250:
                                            %173 = pdl_interp.get_value_type of %172 : !pdl.type
                                            pdl_interp.are_equal %173, %141 : !pdl.type -> ^bb251, ^bb243
                                          ^bb251:
                                            %174 = ematch.get_class_vals %153
                                            pdl_interp.foreach %175 : !pdl.value in %174 {
                                              %176 = pdl_interp.get_defining_op of %175 : !pdl.value {position = "root.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[0].defining_op.operand[1].defining_op"}
                                              pdl_interp.is_not_null %176 : !pdl.operation -> ^bb252, ^bb253
                                            ^bb253:
                                              pdl_interp.continue
                                            ^bb252:
                                              pdl_interp.check_operation_name of %176 is "arith.constant" -> ^bb254, ^bb253
                                            ^bb254:
                                              pdl_interp.check_operand_count of %176 is 0 -> ^bb255, ^bb253
                                            ^bb255:
                                              pdl_interp.check_result_count of %176 is 1 -> ^bb256, ^bb253
                                            ^bb256:
                                              %177 = pdl_interp.get_attribute "value" of %176
                                              pdl_interp.is_not_null %177 : !pdl.attribute -> ^bb257, ^bb253
                                            ^bb257:
                                              pdl_interp.check_attribute %177 is 8 : i16 -> ^bb258, ^bb253
                                            ^bb258:
                                              %178 = pdl_interp.get_result 0 of %176
                                              pdl_interp.is_not_null %178 : !pdl.value -> ^bb259, ^bb253
                                            ^bb259:
                                              %179 = ematch.get_class_result %178
                                              pdl_interp.is_not_null %179 : !pdl.value -> ^bb260, ^bb253
                                            ^bb260:
                                              pdl_interp.are_equal %179, %153 : !pdl.value -> ^bb261, ^bb253
                                            ^bb261:
                                              %180 = pdl_interp.get_value_type of %179 : !pdl.type
                                              pdl_interp.are_equal %180, %157 : !pdl.type -> ^bb262, ^bb253
                                            ^bb262:
                                              pdl_interp.record_match @rewriters::@PreRecombineStage(%0 : !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb253
                                            } -> ^bb243
                                          } -> ^bb231
                                        } -> ^bb217
                                      } -> ^bb208
                                    } -> ^bb197
                                  } -> ^bb188
                                } -> ^bb178
                              } -> ^bb168
                            } -> ^bb146
                          } -> ^bb137
                        } -> ^bb128
                      } -> ^bb119
                    } -> ^bb109
                  } -> ^bb99
                } -> ^bb89
              } -> ^bb79
            } -> ^bb69
          } -> ^bb59
        } -> ^bb51
      } -> ^bb41
    } -> ^bb2
  }
  builtin.module @rewriters {
    pdl_interp.func @SimplifiedProduct(%0: !pdl.operation) {
      pdl_interp.apply_rewrite "rewriter"(%0 : !pdl.operation)
      pdl_interp.finalize
    }
    pdl_interp.func @PreRecombineStage(%0: !pdl.operation) {
      pdl_interp.apply_rewrite "rewriter"(%0 : !pdl.operation)
      pdl_interp.finalize
    }
  }
}

