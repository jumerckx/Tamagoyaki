module @ir {
func.func @ext_add_compose(%ah : i8, %al : i8, %bh : i8, %bl : i8) -> (i32) {
  %c9_32 = arith.constant 9 : i32

  %ah9 = arith.extui %ah : i8 to i9
  %al9 = arith.extui %al : i8 to i9
  %sa  = arith.addi  %ah9, %al9 : i9

  %bh9 = arith.extui %bh : i8 to i9
  %bl9 = arith.extui %bl : i8 to i9
  %sb  = arith.addi  %bh9, %bl9 : i9            // bh + bl
  
  %m_lo, %m_hi = arith.mului_extended %sa, %sb : i9
  %m_hi32  = arith.extui %m_hi : i9 to i32
  %m_lo32  = arith.extui %m_lo : i9 to i32
  %m_hsh   = arith.shli  %m_hi32, %c9_32 : i32  // hi half is worth 2^9 now
  %P       = arith.addi  %m_hsh, %m_lo32 : i32  // (ah+al)*(bh+bl)
  return %P : i32
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


// ---------------------------------------------------------------------------
// zext-compose:  (extui (extui x : iw->iwm) : iwm->iW)  ->  (extui x : iw->iW)
// Collapses the nested extension on the i9 path
// (extui ah : i8->i9, then extui ... : i9->i32).
// Always sound: zero-extension is value-preserving.
// ---------------------------------------------------------------------------
pdl.pattern @ZextCompose : benefit(3) {
  %tw  = pdl.type
  %twm = pdl.type
  %tW  = pdl.type

  %x = pdl.operand : %tw

  %inner = pdl.operation "arith.extui"(%x : !pdl.value) -> (%twm : !pdl.type)
  %innerRes = pdl.result 0 of %inner
  %outer = pdl.operation "arith.extui"(%innerRes : !pdl.value) -> (%tW : !pdl.type)

  pdl.rewrite %outer {
    %new = pdl.operation "arith.extui"(%x : !pdl.value) -> (%tW : !pdl.type)
    pdl.replace %outer with %new
  }
}


// ---------------------------------------------------------------------------
// zext-add:  (extui (addi x y : iw) : iw->iW)  ->  (addi (extui x) (extui y)) : iW
//
// Matches sa = extui(ah) + extui(al) : i9, then extui ... : i9->i32.
//
// SOUNDNESS without a native constraint: we require BOTH addends to themselves
// be `extui` results. Since extui strictly widens, each addend < 2^(w-1), so
// their sum < 2^w and the iw add cannot overflow. This is exactly the program's
// shape; it does not fire for general (possibly-overflowing) adds.
// ---------------------------------------------------------------------------
pdl.pattern @ZextAdd : benefit(3) {
  %tsrcA = pdl.type     // i8 (byte) for ah
  %tsrcB = pdl.type     // i8 (byte) for al
  %tn    = pdl.type     // i9  (add width)
  %tW    = pdl.type     // i32 (final width)

  %p = pdl.operand : %tsrcA
  %q = pdl.operand : %tsrcB

  // x = extui p : srcA -> n ,  y = extui q : srcB -> n
  %x = pdl.operation "arith.extui"(%p : !pdl.value) -> (%tn : !pdl.type)
  %xRes = pdl.result 0 of %x
  %y = pdl.operation "arith.extui"(%q : !pdl.value) -> (%tn : !pdl.type)
  %yRes = pdl.result 0 of %y

  %add = pdl.operation "arith.addi"(%xRes, %yRes : !pdl.value, !pdl.value)
           -> (%tn : !pdl.type)
  %addRes = pdl.result 0 of %add

  %ext = pdl.operation "arith.extui"(%addRes : !pdl.value) -> (%tW : !pdl.type)

  pdl.rewrite %ext {
    // push the wide extension onto each (already-extui) addend; ZextCompose
    // then folds extui(extui p) -> extui p : src -> W.
    %xW = pdl.operation "arith.extui"(%xRes : !pdl.value) -> (%tW : !pdl.type)
    %xWRes = pdl.result 0 of %xW
    %yW = pdl.operation "arith.extui"(%yRes : !pdl.value) -> (%tW : !pdl.type)
    %yWRes = pdl.result 0 of %yW
    %newAdd = pdl.operation "arith.addi"(%xWRes, %yWRes : !pdl.value, !pdl.value)
                -> (%tW : !pdl.type)
    pdl.replace %ext with %newAdd
  }
}
}
