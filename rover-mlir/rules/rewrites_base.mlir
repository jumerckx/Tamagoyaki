//------------------------------------------------------------------------------
// ROVER REWRITES -- base set
//
// Rewrites over comb/hw only. The evaluation's "rover" configuration saturates
// with just this file; "multi" appends rewrites_datapath.mlir. Patterns live at
// the top level (implicit module), so the two files concatenate directly.
//------------------------------------------------------------------------------
pdl.pattern @LeftShiftMult : benefit(1) {
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

pdl.pattern @LeftShiftMult1 : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %s = pdl.operand

  %shl = pdl.operation "comb.shl"(%a, %s : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  %shlResult = pdl.result 0 of %shl

  %mul = pdl.operation "comb.mul"(%shlResult, %b : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %mul {
    %mulNew = pdl.operation "comb.mul"(%a, %b : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)

    %mulResult = pdl.result 0 of %mulNew

    %shlNew = pdl.operation "comb.shl"(%mulResult, %s : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)

    pdl.replace %mul with %shlNew
  }
}

pdl.pattern @LeftShiftMult2 : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %s = pdl.operand

  %shl = pdl.operation "comb.shl"(%a, %s : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  %shlResult = pdl.result 0 of %shl

  %mul = pdl.operation "comb.mul"(%b, %shlResult : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %mul {
    %mulNew = pdl.operation "comb.mul"(%b, %a : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)

    %mulResult = pdl.result 0 of %mulNew

    %shlNew = pdl.operation "comb.shl"(%mulResult, %s : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)

    pdl.replace %mul with %shlNew
  }
}

pdl.pattern @LeftShiftAdd : benefit(1) {
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

pdl.pattern @SelMul : benefit(1) {
  %s = pdl.operand
  %a = pdl.operand
  %b = pdl.operand
  %c = pdl.operand
  %resultType = pdl.type

  %ab = pdl.operation "comb.mul"(%a, %b : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
  %abres = pdl.result 0 of %ab
  %ac = pdl.operation "comb.mul"(%a, %c : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
  %acres = pdl.result 0 of %ac

  %mux = pdl.operation "comb.mux"(%s, %abres, %acres : !pdl.value, !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  pdl.rewrite %mux {
    %new_mux = pdl.operation "comb.mux"(%s, %b, %c : !pdl.value, !pdl.value, !pdl.value) 
               -> (%resultType : !pdl.type)
    %new_mux_res = pdl.result 0 of %new_mux
    %mul  = pdl.operation "comb.mul"(%a, %new_mux_res : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
    
    pdl.replace %mux with %mul
  }
}

pdl.pattern @SelAdd : benefit(1) {
  %s = pdl.operand
  %a = pdl.operand
  %b = pdl.operand
  %c = pdl.operand
  %d = pdl.operand
  %resultType = pdl.type

  %ab = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
  %abres = pdl.result 0 of %ab
  %cd = pdl.operation "comb.add"(%c, %d : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
  %cdres = pdl.result 0 of %cd

  %mux = pdl.operation "comb.mux"(%s, %abres, %cdres : !pdl.value, !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  pdl.rewrite %mux {
    %mux_ac = pdl.operation "comb.mux"(%s, %a, %c : !pdl.value, !pdl.value, !pdl.value) 
               -> (%resultType : !pdl.type)
    %mux_bd = pdl.operation "comb.mux"(%s, %b, %d : !pdl.value, !pdl.value, !pdl.value) 
               -> (%resultType : !pdl.type)

    %mux_ac_res = pdl.result 0 of %mux_ac
    %mux_bd_res = pdl.result 0 of %mux_bd
    %add  = pdl.operation "comb.add"(%mux_ac_res, %mux_bd_res : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
    
    pdl.replace %mux with %add
  }
}

pdl.pattern @SelAddLeft : benefit(1) {
  %s = pdl.operand
  %a = pdl.operand
  %b = pdl.operand
  %resultType = pdl.type

  %ab = pdl.operation "comb.add"(%a, %b : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
  %abres = pdl.result 0 of %ab


  %mux = pdl.operation "comb.mux"(%s, %abres, %a : !pdl.value, !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  pdl.rewrite %mux {
    %zero = pdl.apply_native_rewrite "BuildZero"
             (%mux: !pdl.operation)
             : !pdl.operation
    %zeroRes = pdl.result 0 of %zero
    %mux_b = pdl.operation "comb.mux"(%s, %b, %zeroRes : !pdl.value, !pdl.value, !pdl.value) 
               -> (%resultType : !pdl.type)

    %mux_b_res = pdl.result 0 of %mux_b
    %add  = pdl.operation "comb.add"(%a, %mux_b_res : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)
    
    pdl.replace %mux with %add
  }
}

pdl.pattern @SelSame : benefit(1) {
  %s = pdl.operand
  %a = pdl.operand
  %resultType = pdl.type

  %mux = pdl.operation "comb.mux"(%s, %a, %a : !pdl.value, !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  pdl.rewrite %mux {
    pdl.replace %mux with (%a : !pdl.value)
  }
}

pdl.pattern @AddRightShift : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %s = pdl.operand

  %shr = pdl.operation "comb.shru"(%a, %s : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)
  %shrRes = pdl.result 0 of %shr

  %add = pdl.operation "comb.add"(%shrRes, %b : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %add {
    %shl = pdl.operation "comb.shl"(%b, %s : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)
    %shlRes = pdl.result 0 of %shl

    %newAdd = pdl.operation "comb.add"(%a, %shlRes : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)
    %newAddRes = pdl.result 0 of %newAdd

    %newShr = pdl.operation "comb.shru"(%newAddRes, %s : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)

    pdl.replace %add with %newShr
  }
}

pdl.pattern @MergeRightShift : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %s1 = pdl.operand
  %s2 = pdl.operand

  %shr1 = pdl.operation "comb.shru"(%a, %s1 : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)
  %shrRes = pdl.result 0 of %shr1

  %shr2 = pdl.operation "comb.shru"(%shrRes, %s2 : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %shr2 {
    %newAdd = pdl.operation "comb.add"(%s1, %s2 : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)
    %newAddRes = pdl.result 0 of %newAdd

    %newShr = pdl.operation "comb.shru"(%a, %newAddRes : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)

    pdl.replace %shr2 with %newShr
  }
}

pdl.pattern @MergeLeftShift : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %s1 = pdl.operand
  %s2 = pdl.operand

  %shl1 = pdl.operation "comb.shl"(%a, %s1 : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)
  %shlRes = pdl.result 0 of %shl1

  %shl2 = pdl.operation "comb.shl"(%shlRes, %s2 : !pdl.value, !pdl.value)
           -> (%type : !pdl.type)

  pdl.rewrite %shl2 {
    %newAdd = pdl.operation "comb.add"(%s1, %s2 : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)
    %newAddRes = pdl.result 0 of %newAdd

    %newShl = pdl.operation "comb.shl"(%a, %newAddRes : !pdl.value, !pdl.value)
                -> (%type : !pdl.type)

    pdl.replace %shl2 with %newShl
  }
}

pdl.pattern @MergeAdd3 : benefit(1) {
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
    %add = pdl.operation "comb.add"(%a, %b, %c : !pdl.value, !pdl.value, !pdl.value)
             -> (%type : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %add1 with %add
  }
}

pdl.pattern @MergeAdd4 : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %c = pdl.operand : %type
  %d = pdl.operand : %type

  %add0 = pdl.operation "comb.add"(%a, %b, %c : !pdl.value, !pdl.value, !pdl.value)
            -> (%type : !pdl.type)
  %add0Result = pdl.result 0 of %add0

  %add1 = pdl.operation "comb.add"(%add0Result, %d : !pdl.value, !pdl.value)
            -> (%type : !pdl.type)

  pdl.rewrite %add1 {
    %add = pdl.operation "comb.add"(%a, %b, %c, %d : !pdl.value, !pdl.value, !pdl.value, !pdl.value)
             -> (%type : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %add1 with %add
  }
}

