// pdl.pattern @MulShlToShlMul : benefit(1) {
//   %type = pdl.type

//   %a = pdl.operand : %type
//   %b = pdl.operand : %type
//   %s = pdl.operand

//   %mul = pdl.operation "comb.mul"(%a, %b : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   %mulResult = pdl.result 0 of %mul

//   %shl = pdl.operation "comb.shl"(%mulResult, %s : !pdl.value, !pdl.value)
//            -> (%type : !pdl.type)

//   pdl.rewrite %shl {
//     %newShl = pdl.operation "comb.shl"(%a, %s : !pdl.value, !pdl.value)
//                 -> (%type : !pdl.type)
//     %newShlResult = pdl.result 0 of %newShl

//     %newMul = pdl.operation "comb.mul"(%newShlResult, %b : !pdl.value, !pdl.value)
//                 -> (%type : !pdl.type)

//     pdl.replace %shl with %newMul
//   }
// }

pdl.pattern @AddShlToShlAdd : benefit(1) {
  %type      = pdl.type
  %shiftType = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %c = pdl.operand : %shiftType

  %add = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)
  %addResult = pdl.result 0 of %add

  %shl = pdl.operation "comb.shl"(%addResult, %c : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %shl {
    %shlA = pdl.operation "comb.shl"(%a, %c : !pdl.value, !pdl.value)
              -> (%type : !pdl.type)
    %shlAResult = pdl.result 0 of %shlA

    %shlB = pdl.operation "comb.shl"(%b, %c : !pdl.value, !pdl.value)
              -> (%type : !pdl.type)
    %shlBResult = pdl.result 0 of %shlB

    %newAdd = pdl.operation "comb.add"(%shlAResult, %shlBResult : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)

    pdl.replace %shl with %newAdd
  }
}



pdl.pattern @AddAddToAdd3 : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %c = pdl.operand : %type

  %add0 = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
            -> (%type : !pdl.type)
  %add0Result = pdl.result 0 of %add0

  %add1 = pdl.operation "comb.add"(%add0Result, %c : !pdl.value, !pdl.value)
            -> (%type : !pdl.type)

  pdl.rewrite %add1 {
    %range = pdl.range %a, %b, %c : !pdl.value, !pdl.value, !pdl.value
    %compress = pdl.apply_native_rewrite "BuildCompress"
             (%range: !pdl.range<value>)
             : !pdl.operation
    
    %comp0 = pdl.result 0 of %compress
    %comp1 = pdl.result 1 of %compress

    %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %add1 with %add
  }
}


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
    %ppResults = pdl.results of %pp 

    %compress = pdl.apply_native_rewrite "BuildCompress"
             (%ppResults: !pdl.range<value>)
             : !pdl.operation
    
    %comp0 = pdl.result 0 of %compress
    %comp1 = pdl.result 1 of %compress

    %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
             -> (%resultType : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %mulOp with %add
  }
}