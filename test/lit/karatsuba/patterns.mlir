// RUN: true

// Port of egg-style rewrite rules to PDL, specialized to i8.
//
// The leading width child `?w` in each egg term is carried by the result
// type in PDL, so it does not appear as an operand here. All ops are the
// integer `arith` variants: addi / subi / muli / shli.

// // ---------------------------------------------------------------------------
// // add-comm:  (+ a b)  ->  (+ b a)
// // ---------------------------------------------------------------------------
// pdl.pattern @AddComm : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8

//   %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %add {
//     %new = pdl.operation "arith.addi"(%b, %a : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     pdl.replace %add with %new
//   }
// }

// // ---------------------------------------------------------------------------
// // add-assoc:  (+ a (+ b c))  ->  (+ (+ a b) c)
// // ---------------------------------------------------------------------------
// pdl.pattern @AddAssoc : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %c = pdl.operand : %i8

//   %inner = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//   %innerRes = pdl.result 0 of %inner
//   %outer = pdl.operation "arith.addi"(%a, %innerRes : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)

//   pdl.rewrite %outer {
//     %newInner = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
//                   -> (%i8 : !pdl.type)
//     %newInnerRes = pdl.result 0 of %newInner
//     %newOuter = pdl.operation "arith.addi"(%newInnerRes, %c : !pdl.value, !pdl.value)
//                   -> (%i8 : !pdl.type)
//     pdl.replace %outer with %newOuter
//   }
// }

// // ---------------------------------------------------------------------------
// // mul-comm:  (* a b)  ->  (* b a)
// // ---------------------------------------------------------------------------
// pdl.pattern @MulComm : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8

//   %mul = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %mul {
//     %new = pdl.operation "arith.muli"(%b, %a : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     pdl.replace %mul with %new
//   }
// }

// // ---------------------------------------------------------------------------
// // undistribute-left:  (+ (* a b) (* a c))  ->  (* a (+ b c))
// // ---------------------------------------------------------------------------
// pdl.pattern @UndistributeLeft : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %c = pdl.operand : %i8

//   %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %mul1Res = pdl.result 0 of %mul1
//   %mul2 = pdl.operation "arith.muli"(%a, %c : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %mul2Res = pdl.result 0 of %mul2
//   %add = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %add {
//     %sum = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     %sumRes = pdl.result 0 of %sum
//     %new = pdl.operation "arith.muli"(%a, %sumRes : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     pdl.replace %add with %new
//   }
// }

// // ---------------------------------------------------------------------------
// // undistribute-right:  (+ (* a b) (* c b))  ->  (* (+ a c) b)
// // ---------------------------------------------------------------------------
// pdl.pattern @UndistributeRight : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %c = pdl.operand : %i8

//   %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %mul1Res = pdl.result 0 of %mul1
//   %mul2 = pdl.operation "arith.muli"(%c, %b : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//   %mul2Res = pdl.result 0 of %mul2
//   %add = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %add {
//     %sum = pdl.operation "arith.addi"(%a, %c : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     %sumRes = pdl.result 0 of %sum
//     %new = pdl.operation "arith.muli"(%sumRes, %b : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)
//     pdl.replace %add with %new
//   }
// }

// // ---------------------------------------------------------------------------
// // sub-same:  (- a a)  ->  0
// // ---------------------------------------------------------------------------
// pdl.pattern @SubSame : benefit(2) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8

//   // Reusing %a in both positions constrains the two operands to be identical.
//   %sub = pdl.operation "arith.subi"(%a, %a : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %sub {
//     %zeroAttr = pdl.attribute = 0 : i8
//     %zeroOp = pdl.operation "arith.constant" {"value" = %zeroAttr}
//                 -> (%i8 : !pdl.type)
//     %zero = pdl.result 0 of %zeroOp
//     pdl.replace %sub with (%zero : !pdl.value)
//   }
// }

// // ---------------------------------------------------------------------------
// // add-zero:  (+ a 0)  ->  a
// // ---------------------------------------------------------------------------
// pdl.pattern @AddZero : benefit(2) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8

//   %zeroAttr = pdl.attribute = 0 : i8
//   %zeroOp = pdl.operation "arith.constant" {"value" = %zeroAttr}
//               -> (%i8 : !pdl.type)
//   %zero = pdl.result 0 of %zeroOp

//   %add = pdl.operation "arith.addi"(%a, %zero : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %add {
//     pdl.replace %add with (%a : !pdl.value)
//   }
// }

// // ---------------------------------------------------------------------------
// // assoc-add-sub:  (- (+ a b) c)  ->  (+ (- a c) b)
// // ---------------------------------------------------------------------------
// pdl.pattern @AssocAddSub : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %c = pdl.operand : %i8

//   %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)
//   %addRes = pdl.result 0 of %add
//   %sub = pdl.operation "arith.subi"(%addRes, %c : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %sub {
//     %newSub = pdl.operation "arith.subi"(%a, %c : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//     %newSubRes = pdl.result 0 of %newSub
//     %newAdd = pdl.operation "arith.addi"(%newSubRes, %b : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//     pdl.replace %sub with %newAdd
//   }
// }

// // ---------------------------------------------------------------------------
// // distribute-mult:  (* a (+ b c))  ->  (+ (* a b) (* a c))
// // ---------------------------------------------------------------------------
// pdl.pattern @DistributeMult : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %c = pdl.operand : %i8

//   %add = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)
//   %addRes = pdl.result 0 of %add
//   %mul = pdl.operation "arith.muli"(%a, %addRes : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)

//   pdl.rewrite %mul {
//     %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
//               -> (%i8 : !pdl.type)
//     %mul1Res = pdl.result 0 of %mul1
//     %mul2 = pdl.operation "arith.muli"(%a, %c : !pdl.value, !pdl.value)
//               -> (%i8 : !pdl.type)
//     %mul2Res = pdl.result 0 of %mul2
//     %newAdd = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//     pdl.replace %mul with %newAdd
//   }
// }

// // ---------------------------------------------------------------------------
// // shift-mul-1:  (<< (* a b) s)  ->  (* a (<< b s))
// // ---------------------------------------------------------------------------
// pdl.pattern @ShiftMul1 : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %s = pdl.operand : %i8

//   %mul = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)
//   %mulRes = pdl.result 0 of %mul
//   %shift = pdl.operation "arith.shli"(%mulRes, %s : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)

//   pdl.rewrite %shift {
//     %newShift = pdl.operation "arith.shli"(%b, %s : !pdl.value, !pdl.value)
//                   -> (%i8 : !pdl.type)
//     %newShiftRes = pdl.result 0 of %newShift
//     %newMul = pdl.operation "arith.muli"(%a, %newShiftRes : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//     pdl.replace %shift with %newMul
//   }
// }

// // ---------------------------------------------------------------------------
// // shift-add:  (<< (+ a b) s)  ->  (+ (<< a s) (<< b s))
// // ---------------------------------------------------------------------------
// pdl.pattern @ShiftAdd : benefit(1) {
//   %i8 = pdl.type : i8
//   %a = pdl.operand : %i8
//   %b = pdl.operand : %i8
//   %s = pdl.operand : %i8

//   %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
//            -> (%i8 : !pdl.type)
//   %addRes = pdl.result 0 of %add
//   %shift = pdl.operation "arith.shli"(%addRes, %s : !pdl.value, !pdl.value)
//              -> (%i8 : !pdl.type)

//   pdl.rewrite %shift {
//     %sa = pdl.operation "arith.shli"(%a, %s : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//     %saRes = pdl.result 0 of %sa
//     %sb = pdl.operation "arith.shli"(%b, %s : !pdl.value, !pdl.value)
//             -> (%i8 : !pdl.type)
//     %sbRes = pdl.result 0 of %sb
//     %newAdd = pdl.operation "arith.addi"(%saRes, %sbRes : !pdl.value, !pdl.value)
//                 -> (%i8 : !pdl.type)
//     pdl.replace %shift with %newAdd
//   }
// }


pdl_interp.func @matcher(%0: !pdl.operation) {
  pdl_interp.switch_operation_name of %0 to ["arith.addi", "arith.muli", "arith.subi", "arith.shli"](^bb0, ^bb1, ^bb2, ^bb3) -> ^bb4
^bb4:
  pdl_interp.finalize
^bb0:
  pdl_interp.check_operand_count of %0 is 2 -> ^bb5, ^bb4
^bb5:
  pdl_interp.check_result_count of %0 is 1 -> ^bb6, ^bb4
^bb6:
  %1 = pdl_interp.get_operand 0 of %0
  pdl_interp.is_not_null %1 : !pdl.value -> ^bb7, ^bb4
^bb7:
  %2 = pdl_interp.get_result 0 of %0
  pdl_interp.is_not_null %2 : !pdl.value -> ^bb8, ^bb4
^bb8:
  %3 = ematch.get_class_result %2
  pdl_interp.is_not_null %3 : !pdl.value -> ^bb9, ^bb4
^bb9:
  %4 = pdl_interp.get_operand 1 of %0
  pdl_interp.is_not_null %4 : !pdl.value -> ^bb10, ^bb4
^bb10:
  %5 = pdl_interp.get_value_type of %1 : !pdl.type
  %6 = pdl_interp.get_value_type of %3 : !pdl.type
  pdl_interp.are_equal %5, %6 : !pdl.type -> ^bb11, ^bb12
^bb12:
  %7 = ematch.get_class_vals %1
  pdl_interp.foreach %8 : !pdl.value in %7 {
    %9 = pdl_interp.get_defining_op of %8 : !pdl.value {position = "root.operand[0].defining_op"}
    pdl_interp.is_not_null %9 : !pdl.operation -> ^bb13, ^bb14
  ^bb14:
    pdl_interp.continue
  ^bb13:
    pdl_interp.check_operation_name of %9 is "arith.muli" -> ^bb15, ^bb14
  ^bb15:
    pdl_interp.check_operand_count of %9 is 2 -> ^bb16, ^bb14
  ^bb16:
    pdl_interp.check_result_count of %9 is 1 -> ^bb17, ^bb14
  ^bb17:
    %10 = pdl_interp.get_operand 0 of %9
    pdl_interp.is_not_null %10 : !pdl.value -> ^bb18, ^bb14
  ^bb18:
    %11 = pdl_interp.get_operand 1 of %9
    pdl_interp.is_not_null %11 : !pdl.value -> ^bb19, ^bb14
  ^bb19:
    %12 = pdl_interp.get_result 0 of %9
    pdl_interp.is_not_null %12 : !pdl.value -> ^bb20, ^bb14
  ^bb20:
    %13 = ematch.get_class_result %12
    pdl_interp.is_not_null %13 : !pdl.value -> ^bb21, ^bb14
  ^bb21:
    pdl_interp.are_equal %13, %1 : !pdl.value -> ^bb22, ^bb14
  ^bb22:
    %14 = pdl_interp.get_value_type of %10 : !pdl.type
    %15 = pdl_interp.get_value_type of %11 : !pdl.type
    pdl_interp.are_equal %14, %15 : !pdl.type -> ^bb23, ^bb14
  ^bb23:
    %16 = pdl_interp.get_value_type of %13 : !pdl.type
    pdl_interp.are_equal %14, %16 : !pdl.type -> ^bb24, ^bb14
  ^bb24:
    %17 = pdl_interp.get_value_type of %3 : !pdl.type
    pdl_interp.are_equal %14, %17 : !pdl.type -> ^bb25, ^bb14
  ^bb25:
    pdl_interp.check_type %14 is i8 -> ^bb26, ^bb14
  ^bb26:
    %18 = ematch.get_class_vals %4
    pdl_interp.foreach %19 : !pdl.value in %18 {
      %20 = pdl_interp.get_defining_op of %19 : !pdl.value {position = "root.operand[1].defining_op"}
      pdl_interp.is_not_null %20 : !pdl.operation -> ^bb27, ^bb28
    ^bb28:
      pdl_interp.continue
    ^bb27:
      pdl_interp.check_operation_name of %20 is "arith.muli" -> ^bb29, ^bb28
    ^bb29:
      pdl_interp.check_operand_count of %20 is 2 -> ^bb30, ^bb28
    ^bb30:
      pdl_interp.check_result_count of %20 is 1 -> ^bb31, ^bb28
    ^bb31:
      %21 = pdl_interp.get_result 0 of %20
      pdl_interp.is_not_null %21 : !pdl.value -> ^bb32, ^bb28
    ^bb32:
      %22 = ematch.get_class_result %21
      pdl_interp.is_not_null %22 : !pdl.value -> ^bb33, ^bb28
    ^bb33:
      pdl_interp.are_equal %22, %4 : !pdl.value -> ^bb34, ^bb28
    ^bb34:
      %23 = pdl_interp.get_operand 1 of %20
      pdl_interp.is_not_null %23 : !pdl.value -> ^bb35, ^bb36
    ^bb36:
      %24 = pdl_interp.get_operand 0 of %20
      pdl_interp.is_not_null %24 : !pdl.value -> ^bb37, ^bb28
    ^bb37:
      %25 = pdl_interp.get_value_type of %22 : !pdl.type
      pdl_interp.are_equal %14, %25 : !pdl.type -> ^bb38, ^bb28
    ^bb38:
      %26 = pdl_interp.get_operand 1 of %20
      pdl_interp.are_equal %11, %26 : !pdl.value -> ^bb39, ^bb28
    ^bb39:
      %27 = pdl_interp.get_value_type of %24 : !pdl.type
      pdl_interp.are_equal %14, %27 : !pdl.type -> ^bb40, ^bb28
    ^bb40:
      %28 = ematch.get_class_representative %10
      %29 = ematch.get_class_representative %24
      %30 = ematch.get_class_representative %11
      pdl_interp.record_match @rewriters::@UndistributeRight(%28, %29, %30, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb28
    ^bb35:
      %31 = pdl_interp.get_value_type of %22 : !pdl.type
      pdl_interp.are_equal %14, %31 : !pdl.type -> ^bb41, ^bb36
    ^bb41:
      %32 = pdl_interp.get_operand 0 of %20
      pdl_interp.are_equal %10, %32 : !pdl.value -> ^bb42, ^bb36
    ^bb42:
      %33 = pdl_interp.get_value_type of %23 : !pdl.type
      pdl_interp.are_equal %14, %33 : !pdl.type -> ^bb43, ^bb36
    ^bb43:
      %34 = ematch.get_class_representative %11
      %35 = ematch.get_class_representative %23
      %36 = ematch.get_class_representative %10
      pdl_interp.record_match @rewriters::@UndistributeLeft(%34, %35, %36, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb36
    } -> ^bb14
  } -> ^bb4
^bb11:
  pdl_interp.check_type %5 is i8 -> ^bb44, ^bb12
^bb44:
  %37 = pdl_interp.get_value_type of %4 : !pdl.type
  pdl_interp.are_equal %5, %37 : !pdl.type -> ^bb45, ^bb46
^bb46:
  %38 = ematch.get_class_vals %4
  pdl_interp.foreach %39 : !pdl.value in %38 {
    %40 = pdl_interp.get_defining_op of %39 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %40 : !pdl.operation -> ^bb47, ^bb48
  ^bb48:
    pdl_interp.continue
  ^bb47:
    pdl_interp.switch_operation_name of %40 to ["arith.addi", "arith.constant"](^bb49, ^bb50) -> ^bb48
  ^bb49:
    pdl_interp.check_operand_count of %40 is 2 -> ^bb51, ^bb48
  ^bb51:
    pdl_interp.check_result_count of %40 is 1 -> ^bb52, ^bb48
  ^bb52:
    %41 = pdl_interp.get_result 0 of %40
    pdl_interp.is_not_null %41 : !pdl.value -> ^bb53, ^bb48
  ^bb53:
    %42 = ematch.get_class_result %41
    pdl_interp.is_not_null %42 : !pdl.value -> ^bb54, ^bb48
  ^bb54:
    pdl_interp.are_equal %42, %4 : !pdl.value -> ^bb55, ^bb48
  ^bb55:
    %43 = pdl_interp.get_operand 0 of %40
    pdl_interp.is_not_null %43 : !pdl.value -> ^bb56, ^bb48
  ^bb56:
    %44 = pdl_interp.get_operand 1 of %40
    pdl_interp.is_not_null %44 : !pdl.value -> ^bb57, ^bb48
  ^bb57:
    %45 = pdl_interp.get_value_type of %42 : !pdl.type
    pdl_interp.are_equal %45, %5 : !pdl.type -> ^bb58, ^bb48
  ^bb58:
    %46 = pdl_interp.get_value_type of %43 : !pdl.type
    pdl_interp.are_equal %46, %5 : !pdl.type -> ^bb59, ^bb48
  ^bb59:
    %47 = pdl_interp.get_value_type of %44 : !pdl.type
    pdl_interp.are_equal %47, %5 : !pdl.type -> ^bb60, ^bb48
  ^bb60:
    %48 = ematch.get_class_representative %1
    %49 = ematch.get_class_representative %43
    %50 = ematch.get_class_representative %44
    pdl_interp.record_match @rewriters::@AddAssoc(%48, %49, %50, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb48
  ^bb50:
    pdl_interp.check_operand_count of %40 is 0 -> ^bb61, ^bb48
  ^bb61:
    pdl_interp.check_result_count of %40 is 1 -> ^bb62, ^bb48
  ^bb62:
    %51 = pdl_interp.get_result 0 of %40
    pdl_interp.is_not_null %51 : !pdl.value -> ^bb63, ^bb48
  ^bb63:
    %52 = ematch.get_class_result %51
    pdl_interp.is_not_null %52 : !pdl.value -> ^bb64, ^bb48
  ^bb64:
    pdl_interp.are_equal %52, %4 : !pdl.value -> ^bb65, ^bb48
  ^bb65:
    %53 = pdl_interp.get_value_type of %52 : !pdl.type
    pdl_interp.are_equal %53, %5 : !pdl.type -> ^bb66, ^bb48
  ^bb66:
    %54 = pdl_interp.get_attribute "value" of %40
    pdl_interp.is_not_null %54 : !pdl.attribute -> ^bb67, ^bb48
  ^bb67:
    %55 = ematch.get_class_representative %1
    pdl_interp.record_match @rewriters::@AddZero(%55, %0 : !pdl.value, !pdl.operation) : benefit(2), loc([]), root("arith.addi") -> ^bb48
  } -> ^bb12
^bb45:
  %56 = ematch.get_class_representative %4
  %57 = ematch.get_class_representative %1
  pdl_interp.record_match @rewriters::@AddComm(%56, %57, %0 : !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.addi") -> ^bb46
^bb1:
  pdl_interp.check_operand_count of %0 is 2 -> ^bb68, ^bb4
^bb68:
  pdl_interp.check_result_count of %0 is 1 -> ^bb69, ^bb4
^bb69:
  %58 = pdl_interp.get_operand 0 of %0
  pdl_interp.is_not_null %58 : !pdl.value -> ^bb70, ^bb4
^bb70:
  %59 = pdl_interp.get_result 0 of %0
  pdl_interp.is_not_null %59 : !pdl.value -> ^bb71, ^bb4
^bb71:
  %60 = ematch.get_class_result %59
  pdl_interp.is_not_null %60 : !pdl.value -> ^bb72, ^bb4
^bb72:
  %61 = pdl_interp.get_operand 1 of %0
  pdl_interp.is_not_null %61 : !pdl.value -> ^bb73, ^bb4
^bb73:
  %62 = pdl_interp.get_value_type of %58 : !pdl.type
  %63 = pdl_interp.get_value_type of %60 : !pdl.type
  pdl_interp.are_equal %62, %63 : !pdl.type -> ^bb74, ^bb4
^bb74:
  pdl_interp.check_type %62 is i8 -> ^bb75, ^bb4
^bb75:
  %64 = pdl_interp.get_value_type of %61 : !pdl.type
  pdl_interp.are_equal %62, %64 : !pdl.type -> ^bb76, ^bb77
^bb77:
  %65 = ematch.get_class_vals %61
  pdl_interp.foreach %66 : !pdl.value in %65 {
    %67 = pdl_interp.get_defining_op of %66 : !pdl.value {position = "root.operand[1].defining_op"}
    pdl_interp.is_not_null %67 : !pdl.operation -> ^bb78, ^bb79
  ^bb79:
    pdl_interp.continue
  ^bb78:
    pdl_interp.check_operation_name of %67 is "arith.addi" -> ^bb80, ^bb79
  ^bb80:
    pdl_interp.check_operand_count of %67 is 2 -> ^bb81, ^bb79
  ^bb81:
    pdl_interp.check_result_count of %67 is 1 -> ^bb82, ^bb79
  ^bb82:
    %68 = pdl_interp.get_result 0 of %67
    pdl_interp.is_not_null %68 : !pdl.value -> ^bb83, ^bb79
  ^bb83:
    %69 = ematch.get_class_result %68
    pdl_interp.is_not_null %69 : !pdl.value -> ^bb84, ^bb79
  ^bb84:
    pdl_interp.are_equal %69, %61 : !pdl.value -> ^bb85, ^bb79
  ^bb85:
    %70 = pdl_interp.get_operand 0 of %67
    pdl_interp.is_not_null %70 : !pdl.value -> ^bb86, ^bb79
  ^bb86:
    %71 = pdl_interp.get_operand 1 of %67
    pdl_interp.is_not_null %71 : !pdl.value -> ^bb87, ^bb79
  ^bb87:
    %72 = pdl_interp.get_value_type of %69 : !pdl.type
    pdl_interp.are_equal %72, %62 : !pdl.type -> ^bb88, ^bb79
  ^bb88:
    %73 = pdl_interp.get_value_type of %70 : !pdl.type
    pdl_interp.are_equal %73, %62 : !pdl.type -> ^bb89, ^bb79
  ^bb89:
    %74 = pdl_interp.get_value_type of %71 : !pdl.type
    pdl_interp.are_equal %74, %62 : !pdl.type -> ^bb90, ^bb79
  ^bb90:
    %75 = ematch.get_class_representative %58
    %76 = ematch.get_class_representative %70
    %77 = ematch.get_class_representative %71
    pdl_interp.record_match @rewriters::@DistributeMult(%75, %76, %77, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb79
  } -> ^bb4
^bb76:
  %78 = ematch.get_class_representative %61
  %79 = ematch.get_class_representative %58
  pdl_interp.record_match @rewriters::@MulComm(%78, %79, %0 : !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb77
^bb2:
  pdl_interp.check_operand_count of %0 is 2 -> ^bb91, ^bb4
^bb91:
  pdl_interp.check_result_count of %0 is 1 -> ^bb92, ^bb4
^bb92:
  %80 = pdl_interp.get_operand 0 of %0
  pdl_interp.is_not_null %80 : !pdl.value -> ^bb93, ^bb4
^bb93:
  %81 = pdl_interp.get_result 0 of %0
  pdl_interp.is_not_null %81 : !pdl.value -> ^bb94, ^bb4
^bb94:
  %82 = ematch.get_class_result %81
  pdl_interp.is_not_null %82 : !pdl.value -> ^bb95, ^bb4
^bb95:
  %83 = pdl_interp.get_value_type of %80 : !pdl.type
  %84 = pdl_interp.get_value_type of %82 : !pdl.type
  pdl_interp.are_equal %83, %84 : !pdl.type -> ^bb96, ^bb97
^bb97:
  %85 = pdl_interp.get_operand 1 of %0
  pdl_interp.is_not_null %85 : !pdl.value -> ^bb98, ^bb4
^bb98:
  %86 = ematch.get_class_vals %80
  pdl_interp.foreach %87 : !pdl.value in %86 {
    %88 = pdl_interp.get_defining_op of %87 : !pdl.value {position = "root.operand[0].defining_op"}
    pdl_interp.is_not_null %88 : !pdl.operation -> ^bb99, ^bb100
  ^bb100:
    pdl_interp.continue
  ^bb99:
    pdl_interp.check_operation_name of %88 is "arith.addi" -> ^bb101, ^bb100
  ^bb101:
    pdl_interp.check_operand_count of %88 is 2 -> ^bb102, ^bb100
  ^bb102:
    pdl_interp.check_result_count of %88 is 1 -> ^bb103, ^bb100
  ^bb103:
    %89 = pdl_interp.get_operand 0 of %88
    pdl_interp.is_not_null %89 : !pdl.value -> ^bb104, ^bb100
  ^bb104:
    %90 = pdl_interp.get_operand 1 of %88
    pdl_interp.is_not_null %90 : !pdl.value -> ^bb105, ^bb100
  ^bb105:
    %91 = pdl_interp.get_result 0 of %88
    pdl_interp.is_not_null %91 : !pdl.value -> ^bb106, ^bb100
  ^bb106:
    %92 = ematch.get_class_result %91
    pdl_interp.is_not_null %92 : !pdl.value -> ^bb107, ^bb100
  ^bb107:
    pdl_interp.are_equal %92, %80 : !pdl.value -> ^bb108, ^bb100
  ^bb108:
    %93 = pdl_interp.get_value_type of %89 : !pdl.type
    %94 = pdl_interp.get_value_type of %90 : !pdl.type
    pdl_interp.are_equal %93, %94 : !pdl.type -> ^bb109, ^bb100
  ^bb109:
    %95 = pdl_interp.get_value_type of %92 : !pdl.type
    pdl_interp.are_equal %93, %95 : !pdl.type -> ^bb110, ^bb100
  ^bb110:
    %96 = pdl_interp.get_value_type of %82 : !pdl.type
    pdl_interp.are_equal %93, %96 : !pdl.type -> ^bb111, ^bb100
  ^bb111:
    pdl_interp.check_type %93 is i8 -> ^bb112, ^bb100
  ^bb112:
    %97 = pdl_interp.get_value_type of %85 : !pdl.type
    pdl_interp.are_equal %93, %97 : !pdl.type -> ^bb113, ^bb100
  ^bb113:
    %98 = ematch.get_class_representative %89
    %99 = ematch.get_class_representative %85
    %100 = ematch.get_class_representative %90
    pdl_interp.record_match @rewriters::@AssocAddSub(%98, %99, %100, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.subi") -> ^bb100
  } -> ^bb4
^bb96:
  pdl_interp.check_type %83 is i8 -> ^bb114, ^bb97
^bb114:
  %101 = pdl_interp.get_operand 1 of %0
  pdl_interp.are_equal %80, %101 : !pdl.value -> ^bb115, ^bb97
^bb115:
  pdl_interp.record_match @rewriters::@SubSame(%0 : !pdl.operation) : benefit(2), loc([]), root("arith.subi") -> ^bb97
^bb3:
  pdl_interp.check_operand_count of %0 is 2 -> ^bb116, ^bb4
^bb116:
  pdl_interp.check_result_count of %0 is 1 -> ^bb117, ^bb4
^bb117:
  %102 = pdl_interp.get_operand 0 of %0
  pdl_interp.is_not_null %102 : !pdl.value -> ^bb118, ^bb4
^bb118:
  %103 = pdl_interp.get_result 0 of %0
  pdl_interp.is_not_null %103 : !pdl.value -> ^bb119, ^bb4
^bb119:
  %104 = ematch.get_class_result %103
  pdl_interp.is_not_null %104 : !pdl.value -> ^bb120, ^bb4
^bb120:
  %105 = pdl_interp.get_operand 1 of %0
  pdl_interp.is_not_null %105 : !pdl.value -> ^bb121, ^bb4
^bb121:
  %106 = ematch.get_class_vals %102
  pdl_interp.foreach %107 : !pdl.value in %106 {
    %108 = pdl_interp.get_defining_op of %107 : !pdl.value {position = "root.operand[0].defining_op"}
    pdl_interp.is_not_null %108 : !pdl.operation -> ^bb122, ^bb123
  ^bb123:
    pdl_interp.continue
  ^bb122:
    pdl_interp.switch_operation_name of %108 to ["arith.muli", "arith.addi"](^bb124, ^bb125) -> ^bb123
  ^bb124:
    pdl_interp.check_operand_count of %108 is 2 -> ^bb126, ^bb123
  ^bb126:
    pdl_interp.check_result_count of %108 is 1 -> ^bb127, ^bb123
  ^bb127:
    %109 = pdl_interp.get_operand 0 of %108
    pdl_interp.is_not_null %109 : !pdl.value -> ^bb128, ^bb123
  ^bb128:
    %110 = pdl_interp.get_operand 1 of %108
    pdl_interp.is_not_null %110 : !pdl.value -> ^bb129, ^bb123
  ^bb129:
    %111 = pdl_interp.get_result 0 of %108
    pdl_interp.is_not_null %111 : !pdl.value -> ^bb130, ^bb123
  ^bb130:
    %112 = ematch.get_class_result %111
    pdl_interp.is_not_null %112 : !pdl.value -> ^bb131, ^bb123
  ^bb131:
    pdl_interp.are_equal %112, %102 : !pdl.value -> ^bb132, ^bb123
  ^bb132:
    %113 = pdl_interp.get_value_type of %109 : !pdl.type
    %114 = pdl_interp.get_value_type of %110 : !pdl.type
    pdl_interp.are_equal %113, %114 : !pdl.type -> ^bb133, ^bb123
  ^bb133:
    %115 = pdl_interp.get_value_type of %112 : !pdl.type
    pdl_interp.are_equal %113, %115 : !pdl.type -> ^bb134, ^bb123
  ^bb134:
    %116 = pdl_interp.get_value_type of %104 : !pdl.type
    pdl_interp.are_equal %113, %116 : !pdl.type -> ^bb135, ^bb123
  ^bb135:
    pdl_interp.check_type %113 is i8 -> ^bb136, ^bb123
  ^bb136:
    %117 = pdl_interp.get_value_type of %105 : !pdl.type
    pdl_interp.are_equal %113, %117 : !pdl.type -> ^bb137, ^bb123
  ^bb137:
    %118 = ematch.get_class_representative %110
    %119 = ematch.get_class_representative %105
    %120 = ematch.get_class_representative %109
    pdl_interp.record_match @rewriters::@ShiftMul1(%118, %119, %120, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.shli") -> ^bb123
  ^bb125:
    pdl_interp.check_operand_count of %108 is 2 -> ^bb138, ^bb123
  ^bb138:
    pdl_interp.check_result_count of %108 is 1 -> ^bb139, ^bb123
  ^bb139:
    %121 = pdl_interp.get_operand 0 of %108
    pdl_interp.is_not_null %121 : !pdl.value -> ^bb140, ^bb123
  ^bb140:
    %122 = pdl_interp.get_operand 1 of %108
    pdl_interp.is_not_null %122 : !pdl.value -> ^bb141, ^bb123
  ^bb141:
    %123 = pdl_interp.get_result 0 of %108
    pdl_interp.is_not_null %123 : !pdl.value -> ^bb142, ^bb123
  ^bb142:
    %124 = ematch.get_class_result %123
    pdl_interp.is_not_null %124 : !pdl.value -> ^bb143, ^bb123
  ^bb143:
    pdl_interp.are_equal %124, %102 : !pdl.value -> ^bb144, ^bb123
  ^bb144:
    %125 = pdl_interp.get_value_type of %121 : !pdl.type
    %126 = pdl_interp.get_value_type of %122 : !pdl.type
    pdl_interp.are_equal %125, %126 : !pdl.type -> ^bb145, ^bb123
  ^bb145:
    %127 = pdl_interp.get_value_type of %124 : !pdl.type
    pdl_interp.are_equal %125, %127 : !pdl.type -> ^bb146, ^bb123
  ^bb146:
    %128 = pdl_interp.get_value_type of %104 : !pdl.type
    pdl_interp.are_equal %125, %128 : !pdl.type -> ^bb147, ^bb123
  ^bb147:
    pdl_interp.check_type %125 is i8 -> ^bb148, ^bb123
  ^bb148:
    %129 = pdl_interp.get_value_type of %105 : !pdl.type
    pdl_interp.are_equal %125, %129 : !pdl.type -> ^bb149, ^bb123
  ^bb149:
    %130 = ematch.get_class_representative %121
    %131 = ematch.get_class_representative %105
    %132 = ematch.get_class_representative %122
    pdl_interp.record_match @rewriters::@ShiftAdd(%130, %131, %132, %0 : !pdl.value, !pdl.value, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.shli") -> ^bb123
  } -> ^bb4
}
builtin.module @rewriters {
  pdl_interp.func @UndistributeRight(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.addi"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.muli"(%10, %11 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %3 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @UndistributeLeft(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.addi"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.muli"(%11, %10 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %3 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AddAssoc(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.addi"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.addi"(%10, %11 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %3 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AddZero(%0: !pdl.value, %1: !pdl.operation) {
    %2 = ematch.get_class_result %0
    %3 = pdl_interp.create_range %2 : !pdl.value
    ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AddComm(%0: !pdl.value, %1: !pdl.value, %2: !pdl.operation) {
    %3 = ematch.get_class_result %0
    %4 = ematch.get_class_result %1
    %5 = pdl_interp.create_type i8
    %6 = pdl_interp.create_operation "arith.addi"(%3, %4 : !pdl.value, !pdl.value) -> (%5 : !pdl.type)
    %7 = ematch.dedup %6
    %8 = pdl_interp.get_results of %7 : !pdl.range<value>
    %9 = ematch.get_class_results %8
    ematch.union %2 : !pdl.operation, %9 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @DistributeMult(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.muli"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.muli"(%4, %11 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_result 0 of %13
    %15 = ematch.get_class_result %14
    %16 = pdl_interp.create_operation "arith.addi"(%10, %15 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %17 = ematch.dedup %16
    %18 = pdl_interp.get_results of %17 : !pdl.range<value>
    %19 = ematch.get_class_results %18
    ematch.union %3 : !pdl.operation, %19 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @MulComm(%0: !pdl.value, %1: !pdl.value, %2: !pdl.operation) {
    %3 = ematch.get_class_result %0
    %4 = ematch.get_class_result %1
    %5 = pdl_interp.create_type i8
    %6 = pdl_interp.create_operation "arith.muli"(%3, %4 : !pdl.value, !pdl.value) -> (%5 : !pdl.type)
    %7 = ematch.dedup %6
    %8 = pdl_interp.get_results of %7 : !pdl.range<value>
    %9 = ematch.get_class_results %8
    ematch.union %2 : !pdl.operation, %9 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @AssocAddSub(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.subi"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.addi"(%10, %11 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %3 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @SubSame(%0: !pdl.operation) {
    %1 = pdl_interp.create_attribute 0 : i8
    %2 = pdl_interp.create_type i8
    %3 = pdl_interp.create_operation "arith.constant" {"value" = %1} -> (%2 : !pdl.type)
    %4 = ematch.dedup %3
    %5 = pdl_interp.get_result 0 of %4
    %6 = ematch.get_class_result %5
    %7 = pdl_interp.create_range %6 : !pdl.value
    ematch.union %0 : !pdl.operation, %7 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @ShiftMul1(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.shli"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.muli"(%11, %10 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_results of %13 : !pdl.range<value>
    %15 = ematch.get_class_results %14
    ematch.union %3 : !pdl.operation, %15 : !pdl.range<value>
    pdl_interp.finalize
  }
  pdl_interp.func @ShiftAdd(%0: !pdl.value, %1: !pdl.value, %2: !pdl.value, %3: !pdl.operation) {
    %4 = ematch.get_class_result %0
    %5 = ematch.get_class_result %1
    %6 = pdl_interp.create_type i8
    %7 = pdl_interp.create_operation "arith.shli"(%4, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %8 = ematch.dedup %7
    %9 = pdl_interp.get_result 0 of %8
    %10 = ematch.get_class_result %9
    %11 = ematch.get_class_result %2
    %12 = pdl_interp.create_operation "arith.shli"(%11, %5 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %13 = ematch.dedup %12
    %14 = pdl_interp.get_result 0 of %13
    %15 = ematch.get_class_result %14
    %16 = pdl_interp.create_operation "arith.addi"(%10, %15 : !pdl.value, !pdl.value) -> (%6 : !pdl.type)
    %17 = ematch.dedup %16
    %18 = pdl_interp.get_results of %17 : !pdl.range<value>
    %19 = ematch.get_class_results %18
    ematch.union %3 : !pdl.operation, %19 : !pdl.range<value>
    pdl_interp.finalize
  }
}
