pdl.pattern @MulShlToShlMul : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %s = pdl.operand

  %mul = pdl.operation "comb.mul"(%a, %b : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  %mulResult = pdl.result 0 of %mul

  %shl = pdl.operation "comb.shl"(%mulResult, %s : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %shl {
    %newShl = pdl.operation "comb.shl"(%a, %s : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)
    %newShlResult = pdl.result 0 of %newShl

    %newMul = pdl.operation "comb.mul"(%newShlResult, %b : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)

    pdl.replace %shl with %newMul
  }
}

// pdl.pattern @AddShlToShlAdd : benefit(1) {
//   %type      = pdl.type : i17
//   %shiftType = pdl.type

//   %a = pdl.operand : %type
//   %b = pdl.operand : %type
//   %c = pdl.operand : %shiftType

//   %add = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)
//   %addResult = pdl.result 0 of %add

//   %shl = pdl.operation "comb.shl"(%addResult, %c : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   pdl.rewrite %shl {
//     %shlA = pdl.operation "comb.shl"(%a, %c : !pdl.value, !pdl.value)
//               -> (%type : !pdl.type)
//     %shlAResult = pdl.result 0 of %shlA

//     %shlB = pdl.operation "comb.shl"(%b, %c : !pdl.value, !pdl.value)
//               -> (%type : !pdl.type)
//     %shlBResult = pdl.result 0 of %shlB

//     %newAdd = pdl.operation "comb.add"(%shlAResult, %shlBResult : !pdl.value, !pdl.value)
//                 -> (%type : !pdl.type)

//     pdl.replace %shl with %newAdd
//   }
// }

pdl.pattern @MulToDatapath8 : benefit(1) {
  %type = pdl.type : i8

  %a = pdl.operand : %type
  %b = pdl.operand : %type

  %mul = pdl.operation "comb.mul"(%a, %b : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %mul {
    // datapath.partial_product %a, %b : (i8, i8) -> (i8, i8, i8, i8, i8, i8, i8, i8)
    %pp = pdl.operation "datapath.partial_product"(%a, %b : !pdl.value, !pdl.value)
            -> (%type, %type, %type, %type, %type, %type, %type, %type
                : !pdl.type, !pdl.type, !pdl.type, !pdl.type,
                  !pdl.type, !pdl.type, !pdl.type, !pdl.type)

    %pp0 = pdl.result 0 of %pp
    %pp1 = pdl.result 1 of %pp
    %pp2 = pdl.result 2 of %pp
    %pp3 = pdl.result 3 of %pp
    %pp4 = pdl.result 4 of %pp
    %pp5 = pdl.result 5 of %pp
    %pp6 = pdl.result 6 of %pp
    %pp7 = pdl.result 7 of %pp

    // datapath.compress pp#0, ..., pp#7 : i8 [8 -> 2]
    %compress = pdl.operation "datapath.compress"(
                    %pp0, %pp1, %pp2, %pp3, %pp4, %pp5, %pp6, %pp7
                    : !pdl.value, !pdl.value, !pdl.value, !pdl.value,
                      !pdl.value, !pdl.value, !pdl.value, !pdl.value)
                  -> (%type, %type : !pdl.type, !pdl.type)

    %comp0 = pdl.result 0 of %compress
    %comp1 = pdl.result 1 of %compress

    // comb.add bin comp#0, comp#1 : i8
    %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)

    pdl.replace %mul with %add
  }
}

// pdl.pattern @AddAddToAdd3 : benefit(1) {
//   %type = pdl.type : i17

//   %a = pdl.operand : %type
//   %b = pdl.operand : %type
//   %c = pdl.operand : %type

//   %add0 = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
//             -> (%type : !pdl.type)
//   %add0Result = pdl.result 0 of %add0

//   %add1 = pdl.operation "comb.add"(%add0Result, %c : !pdl.value, !pdl.value)
//             -> (%type : !pdl.type)

//   pdl.rewrite %add1 {
//     %newAdd = pdl.operation "comb.add"(%a, %b, %c : !pdl.value, !pdl.value, !pdl.value)
//                 -> (%type : !pdl.type)

//     pdl.replace %add1 with %newAdd
//   }
// }

// pdl.pattern @MulToDatapath8WithZext : benefit(1) {
//   %narrowType = pdl.type : i8
//   %wideType   = pdl.type
//   %prefixType = pdl.type

//   %arg0   = pdl.operand : %narrowType
//   %arg1   = pdl.operand : %narrowType
//   %zeros0 = pdl.operand : %prefixType

//   %ext0 = pdl.operation "comb.concat"(%zeros0, %arg0 : !pdl.value, !pdl.value)
//             -> (%wideType : !pdl.type)
//   %ext0Result = pdl.result 0 of %ext0

//   %ext1 = pdl.operation "comb.concat"(%zeros0, %arg1 : !pdl.value, !pdl.value)
//             -> (%wideType : !pdl.type)
//   %ext1Result = pdl.result 0 of %ext1

//   %mul = pdl.operation "comb.mul"(%ext0Result, %ext1Result : !pdl.value, !pdl.value)
//            -> (%wideType : !pdl.type)

//   pdl.rewrite %mul {
//     %pp = pdl.operation "datapath.partial_product"(%ext0Result, %ext1Result : !pdl.value, !pdl.value)
//             -> (%wideType, %wideType, %wideType, %wideType,
//                 %wideType, %wideType, %wideType, %wideType
//                 : !pdl.type, !pdl.type, !pdl.type, !pdl.type,
//                   !pdl.type, !pdl.type, !pdl.type, !pdl.type)

//     %pp0 = pdl.result 0 of %pp
//     %pp1 = pdl.result 1 of %pp
//     %pp2 = pdl.result 2 of %pp
//     %pp3 = pdl.result 3 of %pp
//     %pp4 = pdl.result 4 of %pp
//     %pp5 = pdl.result 5 of %pp
//     %pp6 = pdl.result 6 of %pp
//     %pp7 = pdl.result 7 of %pp

//     %compress = pdl.operation "datapath.compress"(
//                     %pp0, %pp1, %pp2, %pp3, %pp4, %pp5, %pp6, %pp7
//                     : !pdl.value, !pdl.value, !pdl.value, !pdl.value,
//                       !pdl.value, !pdl.value, !pdl.value, !pdl.value)
//                   -> (%wideType, %wideType : !pdl.type, !pdl.type)

//     %comp0 = pdl.result 0 of %compress
//     %comp1 = pdl.result 1 of %compress

//     %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
//              -> (%wideType : !pdl.type)

//     pdl.replace %mul with %add
//   }
// }

// Bind the two operands and the result type of the comb.mul.
pdl.pattern @MulToPartialProductTree : benefit(1) {

  // Operands – we don't constrain them beyond "they exist".
  %lhs = pdl.operand
  %rhs = pdl.operand

  // The result type of the mul (an integer type of some width).
  %resultType = pdl.type

  // The comb.mul operation itself.
  %mulOp = pdl.operation "comb.mul"(%lhs, %rhs : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  // ── Rewrite ────────────────────────────────────────────────────────────────
  pdl.rewrite %mulOp {
    // Delegate all width-dependent IR construction to C++.
    // Returns the comb.add Operation that replaces the mul.
    %pp = pdl.apply_native_rewrite "BuildPartialProduct"
                 (%mulOp: !pdl.operation)
                 : !pdl.operation

    // Splice the comb.add result in place of the original mul result.
    pdl.replace %mulOp with %pp
  }
}