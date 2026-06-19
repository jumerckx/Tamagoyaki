module @ir {
func.func @a_h_mul_b_h(%ah: i8, %bh: i8) -> i32 {
  %c8_32 = arith.constant 8 : i32
  %z2_lo, %z2_hi = arith.mului_extended %ah, %bh : i8
  %z2_hi32 = arith.extui %z2_hi : i8 to i32
  %z2_lo32 = arith.extui %z2_lo : i8 to i32
  %z2_hsh  = arith.shli  %z2_hi32, %c8_32 : i32
  %z2      = arith.addi  %z2_hsh, %z2_lo32 : i32
  func.return %z2 : i32
}
}

module @patterns {
pdl.pattern @MulxFuse : benefit(4) {
  %tw = pdl.type        // mulx operand width  (i8 or i9 here)
  %tW = pdl.type        // reassembly width    (i32 here)

  %a = pdl.operand : %tw
  %b = pdl.operand : %tw

  // %lo, %hi = arith.mului_extended %a, %b : iw
  %mulx = pdl.operation "arith.mului_extended"(%a, %b : !pdl.value, !pdl.value)
            -> (%tw, %tw : !pdl.type, !pdl.type)
  %lo = pdl.result 0 of %mulx
  %hi = pdl.result 1 of %mulx

  %hiExt = pdl.operation "arith.extui"(%hi : !pdl.value) -> (%tW : !pdl.type)
  %hiExtRes = pdl.result 0 of %hiExt
  %loExt = pdl.operation "arith.extui"(%lo : !pdl.value) -> (%tW : !pdl.type)
  %loExtRes = pdl.result 0 of %loExt

  // shift amount = constant equal to the mulx input width
  %shAttr = pdl.attribute
  %shCst  = pdl.operation "arith.constant" {"value" = %shAttr} -> (%tW : !pdl.type)
  %sh     = pdl.result 0 of %shCst

  %shl = pdl.operation "arith.shli"(%hiExtRes, %sh : !pdl.value, !pdl.value)
           -> (%tW : !pdl.type)
  %shlRes = pdl.result 0 of %shl

  %add = pdl.operation "arith.addi"(%shlRes, %loExtRes : !pdl.value, !pdl.value)
           -> (%tW : !pdl.type)

  // shift constant must equal bitwidth(%tw), and W >= 2*w
  // pdl.apply_native_constraint "attrEqualsBitwidth"(%shAttr, %tw : !pdl.attribute, !pdl.type)
  // pdl.apply_native_constraint "atLeastDoubleWidth"(%tw, %tW : !pdl.type, !pdl.type)

  pdl.rewrite %add {
    %aExt = pdl.operation "arith.extui"(%a : !pdl.value) -> (%tW : !pdl.type)
    %aExtRes = pdl.result 0 of %aExt
    %bExt = pdl.operation "arith.extui"(%b : !pdl.value) -> (%tW : !pdl.type)
    %bExtRes = pdl.result 0 of %bExt
    %new = pdl.operation "arith.muli"(%aExtRes, %bExtRes : !pdl.value, !pdl.value)
             -> (%tW : !pdl.type)
    pdl.replace %add with %new
  }
}

}
