// RUN: true

// // ---- Commutativity ----

// pdl.pattern @MulCommute : benefit(1) {
//   %type = pdl.type
//   %a = pdl.operand : %type
//   %b = pdl.operand : %type

//   %mul = pdl.operation "arith.mulf"(%a, %b : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   pdl.rewrite %mul {
//     %new = pdl.operation "arith.mulf"(%b, %a : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)
//     pdl.replace %mul with %new
//   }
// }

// pdl.pattern @AddCommute : benefit(1) {
//   %type = pdl.type
//   %a = pdl.operand : %type
//   %b = pdl.operand : %type

//   %add = pdl.operation "arith.addf"(%a, %b : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   pdl.rewrite %add {
//     %new = pdl.operation "arith.addf"(%b, %a : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)
//     pdl.replace %add with %new
//   }
// }

// // ---- Associativity:  a op (b op c)  ->  (a op b) op c ----

// pdl.pattern @MulAssoc : benefit(1) {
//   %type = pdl.type
//   %a = pdl.operand : %type
//   %b = pdl.operand : %type
//   %c = pdl.operand : %type

//   // match: a * (b * c)
//   %inner = pdl.operation "arith.mulf"(%b, %c : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)
//   %innerRes = pdl.result 0 of %inner
//   %outer = pdl.operation "arith.mulf"(%a, %innerRes : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)

//   pdl.rewrite %outer {
//     // rewrite to: (a * b) * c
//     %newInner = pdl.operation "arith.mulf"(%a, %b : !pdl.value, !pdl.value)
//                   -> (%type : !pdl.type)
//     %newInnerRes = pdl.result 0 of %newInner
//     %newOuter = pdl.operation "arith.mulf"(%newInnerRes, %c : !pdl.value, !pdl.value)
//                   -> (%type : !pdl.type)
//     pdl.replace %outer with %newOuter
//   }
// }

// pdl.pattern @AddAssoc : benefit(1) {
//   %type = pdl.type
//   %a = pdl.operand : %type
//   %b = pdl.operand : %type
//   %c = pdl.operand : %type

//   // match: a + (b + c)
//   %inner = pdl.operation "arith.addf"(%b, %c : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)
//   %innerRes = pdl.result 0 of %inner
//   %outer = pdl.operation "arith.addf"(%a, %innerRes : !pdl.value, !pdl.value)
//              -> (%type : !pdl.type)

//   pdl.rewrite %outer {
//     // rewrite to: (a + b) + c
//     %newInner = pdl.operation "arith.addf"(%a, %b : !pdl.value, !pdl.value)
//                   -> (%type : !pdl.type)
//     %newInnerRes = pdl.result 0 of %newInner
//     %newOuter = pdl.operation "arith.addf"(%newInnerRes, %c : !pdl.value, !pdl.value)
//                   -> (%type : !pdl.type)
//     pdl.replace %outer with %newOuter
//   }
// }

// // ---- Inverse:  a * a^-1  ->  1   (with a^-1 == divf 1.0, a) ----
// // Reuses the already-present 1.0 value instead of materializing a new const.

// pdl.pattern @MulInverse : benefit(2) {
//   %f64 = pdl.type : f64
//   %a = pdl.operand : %f64

//   %oneAttr = pdl.attribute = 1.000000e+00 : f64
//   %oneOp = pdl.operation "arith.constant" {"value" = %oneAttr}
//              -> (%f64 : !pdl.type)
//   %one = pdl.result 0 of %oneOp

//   %inv = pdl.operation "arith.divf"(%one, %a : !pdl.value, !pdl.value)
//            -> (%f64 : !pdl.type)
//   %invRes = pdl.result 0 of %inv

//   %mul = pdl.operation "arith.mulf"(%a, %invRes : !pdl.value, !pdl.value)
//            -> (%f64 : !pdl.type)

//   pdl.rewrite %mul {
//     pdl.replace %mul with (%one : !pdl.value)
//   }
// }

// // ---- Multiplicative identity:  x * 1.0  ->  x ----

// pdl.pattern @MulByOne : benefit(1) {
//   %type = pdl.type

//   %x = pdl.operand : %type

//   // Match the constant 1.0
//   %oneAttr = pdl.attribute = 1.0 : f64
//   %oneOp = pdl.operation "arith.constant" {"value" = %oneAttr} -> (%type : !pdl.type)
//   %one = pdl.result 0 of %oneOp

//   %mul = pdl.operation "arith.mulf"(%x, %one : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   pdl.rewrite %mul {
//     pdl.replace %mul with (%x : !pdl.value)
//   }
// }

pdl_interp.func @matcher(%0: !pdl.operation) {
  pdl_interp.switch_operation_name of %0 to ["arith.mulf", "arith.addf"](^bb0, ^bb1) -> ^bb2
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
  %5 = pdl_interp.get_value_type of %1 : !pdl.type
  %6 = pdl_interp.get_value_type of %4 : !pdl.type
  pdl_interp.are_equal %5, %6 : !pdl.type -> ^bb9, ^bb2
^bb9:
  %7 = pdl_interp.get_value_type of %2 : !pdl.type
  pdl_interp.are_equal %5, %7 : !pdl.type -> ^bb10, ^bb11
^bb11:
  pdl_interp.check_type %5 is f64 -> ^bb12, ^bb13
^bb13:
  %8 = ematch.get_class_vals %2
  pdl_interp.foreach %9 : !pdl.value in %8 {
    %10 = pdl_interp.get_defining_op of %9 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %10 : !pdl.operation -> ^bb14, ^bb15
  ^bb15:
    pdl_interp.continue
  ^bb14:
    pdl_interp.switch_operation_name of %10 to ["arith.mulf", "arith.constant"](^bb16, ^bb17) -> ^bb15
  ^bb16:
    pdl_interp.check_operand_count of %10 is 2 -> ^bb18, ^bb15
  ^bb18:
    pdl_interp.check_result_count of %10 is 1 -> ^bb19, ^bb15
  ^bb19:
    %11 = pdl_interp.get_result 0 of %10
    pdl_interp.is_not_null %11 : !pdl.value -> ^bb20, ^bb15
  ^bb20:
    %12 = ematch.get_class_result %11
    pdl_interp.is_not_null %12 : !pdl.value -> ^bb21, ^bb15
  ^bb21:
    pdl_interp.are_equal %12, %2 : !pdl.value -> ^bb22, ^bb15
  ^bb22:
    %13 = pdl_interp.get_value_type of %12 : !pdl.type
    pdl_interp.are_equal %13, %5 : !pdl.type -> ^bb23, ^bb15
  ^bb23:
    %14 = pdl_interp.get_operand 0 of %10
    pdl_interp.is_not_null %14 : !pdl.value -> ^bb24, ^bb15
  ^bb24:
    %15 = pdl_interp.get_operand 1 of %10
    pdl_interp.is_not_null %15 : !pdl.value -> ^bb25, ^bb15
  ^bb25:
    %16 = pdl_interp.get_value_type of %14 : !pdl.type
    pdl_interp.are_equal %16, %5 : !pdl.type -> ^bb26, ^bb15
  ^bb26:
    %17 = pdl_interp.get_value_type of %15 : !pdl.type
    pdl_interp.are_equal %17, %5 : !pdl.type -> ^bb27, ^bb15
  ^bb27:
    %18 = ematch.get_class_representative %1
    %19 = ematch.get_class_representative %14
    %20 = ematch.get_class_representative %15
    pdl_interp.record_match @rewriters::@MulAssoc(%18, %19, %5, %20, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.mulf") -> ^bb15
  ^bb17:
    pdl_interp.check_operand_count of %10 is 0 -> ^bb28, ^bb15
  ^bb28:
    pdl_interp.check_result_count of %10 is 1 -> ^bb29, ^bb15
  ^bb29:
    %21 = pdl_interp.get_result 0 of %10
    pdl_interp.is_not_null %21 : !pdl.value -> ^bb30, ^bb15
  ^bb30:
    %22 = ematch.get_class_result %21
    pdl_interp.is_not_null %22 : !pdl.value -> ^bb31, ^bb15
  ^bb31:
    pdl_interp.are_equal %22, %2 : !pdl.value -> ^bb32, ^bb15
  ^bb32:
    %23 = pdl_interp.get_value_type of %22 : !pdl.type
    pdl_interp.are_equal %23, %5 : !pdl.type -> ^bb33, ^bb15
  ^bb33:
    %24 = pdl_interp.get_attribute "value" of %10
    pdl_interp.is_not_null %24 : !pdl.attribute -> ^bb34, ^bb15
  ^bb34:
    pdl_interp.check_attribute %24 is 1.000000e+00 : f64 -> ^bb35, ^bb15
  ^bb35:
    %25 = ematch.get_class_representative %1
    pdl_interp.record_match @rewriters::@MulByOne(%25, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.mulf") -> ^bb15
  } -> ^bb2
^bb12:
  %26 = ematch.get_class_vals %2
  pdl_interp.foreach %27 : !pdl.value in %26 {
    %28 = pdl_interp.get_defining_op of %27 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %28 : !pdl.operation -> ^bb36, ^bb37
  ^bb37:
    pdl_interp.continue
  ^bb36:
    pdl_interp.check_operation_name of %28 is "arith.divf" -> ^bb38, ^bb37
  ^bb38:
    pdl_interp.check_operand_count of %28 is 2 -> ^bb39, ^bb37
  ^bb39:
    pdl_interp.check_result_count of %28 is 1 -> ^bb40, ^bb37
  ^bb40:
    %29 = pdl_interp.get_result 0 of %28
    pdl_interp.is_not_null %29 : !pdl.value -> ^bb41, ^bb37
  ^bb41:
    %30 = ematch.get_class_result %29
    pdl_interp.is_not_null %30 : !pdl.value -> ^bb42, ^bb37
  ^bb42:
    pdl_interp.are_equal %30, %2 : !pdl.value -> ^bb43, ^bb37
  ^bb43:
    %31 = pdl_interp.get_value_type of %30 : !pdl.type
    pdl_interp.are_equal %31, %5 : !pdl.type -> ^bb44, ^bb37
  ^bb44:
    %32 = pdl_interp.get_operand 0 of %28
    pdl_interp.is_not_null %32 : !pdl.value -> ^bb45, ^bb37
  ^bb45:
    %33 = pdl_interp.get_operand 1 of %28
    pdl_interp.are_equal %33, %1 : !pdl.value -> ^bb46, ^bb37
  ^bb46:
    %34 = ematch.get_class_vals %32
    pdl_interp.foreach %35 : !pdl.value in %34 {
      %36 = pdl_interp.get_defining_op of %35 : !pdl.value {position = "root.operand[1].defining_op.operand[0].defining_op"}
      pdl_interp.is_not_null %36 : !pdl.operation -> ^bb47, ^bb48
    ^bb48:
      pdl_interp.continue
    ^bb47:
      pdl_interp.check_operation_name of %36 is "arith.constant" -> ^bb49, ^bb48
    ^bb49:
      pdl_interp.check_operand_count of %36 is 0 -> ^bb50, ^bb48
    ^bb50:
      pdl_interp.check_result_count of %36 is 1 -> ^bb51, ^bb48
    ^bb51:
      %37 = pdl_interp.get_attribute "value" of %36
      pdl_interp.is_not_null %37 : !pdl.attribute -> ^bb52, ^bb48
    ^bb52:
      pdl_interp.check_attribute %37 is 1.000000e+00 : f64 -> ^bb53, ^bb48
    ^bb53:
      %38 = pdl_interp.get_result 0 of %36
      pdl_interp.is_not_null %38 : !pdl.value -> ^bb54, ^bb48
    ^bb54:
      %39 = ematch.get_class_result %38
      pdl_interp.is_not_null %39 : !pdl.value -> ^bb55, ^bb48
    ^bb55:
      pdl_interp.are_equal %39, %32 : !pdl.value -> ^bb56, ^bb48
    ^bb56:
      %40 = pdl_interp.get_value_type of %39 : !pdl.type
      pdl_interp.are_equal %40, %5 : !pdl.type -> ^bb57, ^bb48
    ^bb57:
      %41 = ematch.get_class_representative %32
      pdl_interp.record_match @rewriters::@MulInverse(%41, %0 : !pdl.value, !pdl.operation) : benefit(2), loc([]), root("arith.mulf") -> ^bb48
    } -> ^bb37
  } -> ^bb13
^bb10:
  %42 = ematch.get_class_representative %2
  %43 = ematch.get_class_representative %1
  pdl_interp.record_match @rewriters::@MulCommute(%42, %43, %5, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("arith.mulf") -> ^bb11
^bb1:
  pdl_interp.check_operand_count of %0 is 2 -> ^bb58, ^bb2
^bb58:
  pdl_interp.check_result_count of %0 is 1 -> ^bb59, ^bb2
^bb59:
  %44 = pdl_interp.get_operand 0 of %0
  pdl_interp.is_not_null %44 : !pdl.value -> ^bb60, ^bb2
^bb60:
  %45 = pdl_interp.get_operand 1 of %0
  pdl_interp.is_not_null %45 : !pdl.value -> ^bb61, ^bb2
^bb61:
  %46 = pdl_interp.get_result 0 of %0
  pdl_interp.is_not_null %46 : !pdl.value -> ^bb62, ^bb2
^bb62:
  %47 = ematch.get_class_result %46
  pdl_interp.is_not_null %47 : !pdl.value -> ^bb63, ^bb2
^bb63:
  %48 = pdl_interp.get_value_type of %44 : !pdl.type
  %49 = pdl_interp.get_value_type of %47 : !pdl.type
  pdl_interp.are_equal %48, %49 : !pdl.type -> ^bb64, ^bb2
^bb64:
  %50 = pdl_interp.get_value_type of %45 : !pdl.type
  pdl_interp.are_equal %48, %50 : !pdl.type -> ^bb65, ^bb66
^bb66:
  %51 = ematch.get_class_vals %45
  pdl_interp.foreach %52 : !pdl.value in %51 {
    %53 = pdl_interp.get_defining_op of %52 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %53 : !pdl.operation -> ^bb67, ^bb68
  ^bb68:
    pdl_interp.continue
  ^bb67:
    pdl_interp.check_operation_name of %53 is "arith.addf" -> ^bb69, ^bb68
  ^bb69:
    pdl_interp.check_operand_count of %53 is 2 -> ^bb70, ^bb68
  ^bb70:
    pdl_interp.check_result_count of %53 is 1 -> ^bb71, ^bb68
  ^bb71:
    %54 = pdl_interp.get_result 0 of %53
    pdl_interp.is_not_null %54 : !pdl.value -> ^bb72, ^bb68
  ^bb72:
    %55 = ematch.get_class_result %54
    pdl_interp.is_not_null %55 : !pdl.value -> ^bb73, ^bb68
  ^bb73:
    pdl_interp.are_equal %55, %45 : !pdl.value -> ^bb74, ^bb68
  ^bb74:
    %56 = pdl_interp.get_value_type of %55 : !pdl.type
    pdl_interp.are_equal %56, %48 : !pdl.type -> ^bb75, ^bb68
  ^bb75:
    %57 = pdl_interp.get_operand 0 of %53
    pdl_interp.is_not_null %57 : !pdl.value -> ^bb76, ^bb68
  ^bb76:
    %58 = pdl_interp.get_operand 1 of %53
    pdl_interp.is_not_null %58 : !pdl.value -> ^bb77, ^bb68
  ^bb77:
    %59 = pdl_interp.get_value_type of %57 : !pdl.type
    pdl_interp.are_equal %59, %48 : !pdl.type -> ^bb78, ^bb68
  ^bb78:
    %60 = pdl_interp.get_value_type of %58 : !pdl.type
    pdl_interp.are_equal %60, %48 : !pdl.type -> ^bb79, ^bb68
  ^bb79:
    %61 = ematch.get_class_representative %44
    %62 = ematch.get_class_representative %57
    %63 = ematch.get_class_representative %58
    pdl_interp.record_match @rewriters::@AddAssoc(%61, %62, %48, %63, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addf") -> ^bb68
  } -> ^bb2
^bb65:
  %64 = ematch.get_class_representative %45
  %65 = ematch.get_class_representative %44
  pdl_interp.record_match @rewriters::@AddCommute(%64, %65, %48, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.operation) : benefit(1), loc([]), root("arith.addf") -> ^bb66
}
builtin.module @rewriters {
  pdl_interp.func @MulAssoc(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
    %5 = ematch.get_class_result %0
    %6 = ematch.get_class_result %1
    %7 = pdl_interp.create_operation "arith.mulf"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %3
    %12 = pdl_interp.create_operation "arith.mulf"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @MulByOne(%0: !pdl.value, %1: !pdl.operation) {
    %2 = ematch.get_class_result %0
    %3 = pdl_interp.create_range %2 : !pdl.value
    ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @MulInverse(%0: !pdl.value, %1: !pdl.operation) {
    %2 = ematch.get_class_result %0
    %3 = pdl_interp.create_range %2 : !pdl.value
    ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @MulCommute(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_operation "arith.mulf"(%4, %5 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %7 = ematch.dedup %6
    %8 = pdl_interp.get_results of %7 : !pdl.range<value>
    %9 = ematch.get_class_results %8
    ematch.union %3 : !pdl.operation, %9 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AddAssoc(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
    %5 = ematch.get_class_result %0
    %6 = ematch.get_class_result %1
    %7 = pdl_interp.create_operation "arith.addf"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %3
    %12 = pdl_interp.create_operation "arith.addf"(%10, %11 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %4 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AddCommute(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_operation "arith.addf"(%4, %5 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
    %7 = ematch.dedup %6
    %8 = pdl_interp.get_results of %7 : !pdl.range<value>
    %9 = ematch.get_class_results %8
    ematch.union %3 : !pdl.operation, %9 : !pdl.range<value>
    pdl_interp.finalize
  }
}
