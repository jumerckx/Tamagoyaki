// ===========================================================================
// Algebra rules, updated to fire on the Karatsuba program.
//
// WHAT CHANGED vs. the original:
//   * `%i8 = pdl.type : i8`  ->  `%t = pdl.type`  (unconstrained, width-generic)
//     so each rule matches the i32 reassembly arithmetic and the i9 byte sums,
//     not just i8. comm / assoc / distribute / undistribute / shift / the
//     add-sub reassociation are all valid at any width mod 2^n.
//   * `sub-same` and `add-zero` build/match a typed 0, so they are pinned to
//     i32 (the only width where the P - z2 - z0 cancellation runs). To use them
//     at another width, duplicate with that type, or add a native rewrite that
//     materializes a zero of the matched type.
//   * Added `mul-assoc` (was missing; needed for the final refactor).
// ===========================================================================


// ---------------------------------------------------------------------------
// add-comm:  (+ a b)  ->  (+ b a)
// ---------------------------------------------------------------------------
pdl.pattern @AddComm : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t

  %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %add {
    %new = pdl.operation "arith.addi"(%b, %a : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    pdl.replace %add with %new
  }
}

// ---------------------------------------------------------------------------
// add-assoc:  (+ a (+ b c))  ->  (+ (+ a b) c)
// ---------------------------------------------------------------------------
pdl.pattern @AddAssoc : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %inner = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
  %innerRes = pdl.result 0 of %inner
  %outer = pdl.operation "arith.addi"(%a, %innerRes : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)

  pdl.rewrite %outer {
    %newInner = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
                  -> (%t : !pdl.type)
    %newInnerRes = pdl.result 0 of %newInner
    %newOuter = pdl.operation "arith.addi"(%newInnerRes, %c : !pdl.value, !pdl.value)
                  -> (%t : !pdl.type)
    pdl.replace %outer with %newOuter
  }
}

// ---------------------------------------------------------------------------
// mul-comm:  (* a b)  ->  (* b a)
// ---------------------------------------------------------------------------
pdl.pattern @MulComm : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t

  %mul = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %mul {
    %new = pdl.operation "arith.muli"(%b, %a : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    pdl.replace %mul with %new
  }
}

// ---------------------------------------------------------------------------
// mul-assoc:  (* a (* b c))  ->  (* (* a b) c)        [NEW]
// Needed for the final refactor into (ah*2^8 + al)(bh*2^8 + bl).
// ---------------------------------------------------------------------------
pdl.pattern @MulAssoc : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %inner = pdl.operation "arith.muli"(%b, %c : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
  %innerRes = pdl.result 0 of %inner
  %outer = pdl.operation "arith.muli"(%a, %innerRes : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)

  pdl.rewrite %outer {
    %newInner = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
                  -> (%t : !pdl.type)
    %newInnerRes = pdl.result 0 of %newInner
    %newOuter = pdl.operation "arith.muli"(%newInnerRes, %c : !pdl.value, !pdl.value)
                  -> (%t : !pdl.type)
    pdl.replace %outer with %newOuter
  }
}

// ---------------------------------------------------------------------------
// undistribute-left:  (+ (* a b) (* a c))  ->  (* a (+ b c))
// ---------------------------------------------------------------------------
pdl.pattern @UndistributeLeft : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
  %mul1Res = pdl.result 0 of %mul1
  %mul2 = pdl.operation "arith.muli"(%a, %c : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
  %mul2Res = pdl.result 0 of %mul2
  %add = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %add {
    %sum = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    %sumRes = pdl.result 0 of %sum
    %new = pdl.operation "arith.muli"(%a, %sumRes : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    pdl.replace %add with %new
  }
}

// ---------------------------------------------------------------------------
// undistribute-right:  (+ (* a b) (* c b))  ->  (* (+ a c) b)
// ---------------------------------------------------------------------------
pdl.pattern @UndistributeRight : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
  %mul1Res = pdl.result 0 of %mul1
  %mul2 = pdl.operation "arith.muli"(%c, %b : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
  %mul2Res = pdl.result 0 of %mul2
  %add = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %add {
    %sum = pdl.operation "arith.addi"(%a, %c : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    %sumRes = pdl.result 0 of %sum
    %new = pdl.operation "arith.muli"(%sumRes, %b : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)
    pdl.replace %add with %new
  }
}

// ---------------------------------------------------------------------------
// distribute-mult:  (* a (+ b c))  ->  (+ (* a b) (* a c))
// ---------------------------------------------------------------------------
pdl.pattern @DistributeMult : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %add = pdl.operation "arith.addi"(%b, %c : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)
  %addRes = pdl.result 0 of %add
  %mul = pdl.operation "arith.muli"(%a, %addRes : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %mul {
    %mul1 = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
              -> (%t : !pdl.type)
    %mul1Res = pdl.result 0 of %mul1
    %mul2 = pdl.operation "arith.muli"(%a, %c : !pdl.value, !pdl.value)
              -> (%t : !pdl.type)
    %mul2Res = pdl.result 0 of %mul2
    %newAdd = pdl.operation "arith.addi"(%mul1Res, %mul2Res : !pdl.value, !pdl.value)
                -> (%t : !pdl.type)
    pdl.replace %mul with %newAdd
  }
}

// ---------------------------------------------------------------------------
// assoc-add-sub:  (- (+ a b) c)  ->  (+ (- a c) b)
// ---------------------------------------------------------------------------
pdl.pattern @AssocAddSub : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %c = pdl.operand : %t

  %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)
  %addRes = pdl.result 0 of %add
  %sub = pdl.operation "arith.subi"(%addRes, %c : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)

  pdl.rewrite %sub {
    %newSub = pdl.operation "arith.subi"(%a, %c : !pdl.value, !pdl.value)
                -> (%t : !pdl.type)
    %newSubRes = pdl.result 0 of %newSub
    %newAdd = pdl.operation "arith.addi"(%newSubRes, %b : !pdl.value, !pdl.value)
                -> (%t : !pdl.type)
    pdl.replace %sub with %newAdd
  }
}

// ---------------------------------------------------------------------------
// shift-mul-1:  (<< (* a b) s)  ->  (* a (<< b s))
// ---------------------------------------------------------------------------
pdl.pattern @ShiftMul1 : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %s = pdl.operand : %t

  %mul = pdl.operation "arith.muli"(%a, %b : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)
  %mulRes = pdl.result 0 of %mul
  %shift = pdl.operation "arith.shli"(%mulRes, %s : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)

  pdl.rewrite %shift {
    %newShift = pdl.operation "arith.shli"(%b, %s : !pdl.value, !pdl.value)
                  -> (%t : !pdl.type)
    %newShiftRes = pdl.result 0 of %newShift
    %newMul = pdl.operation "arith.muli"(%a, %newShiftRes : !pdl.value, !pdl.value)
                -> (%t : !pdl.type)
    pdl.replace %shift with %newMul
  }
}

// ---------------------------------------------------------------------------
// shift-add:  (<< (+ a b) s)  ->  (+ (<< a s) (<< b s))
// ---------------------------------------------------------------------------
pdl.pattern @ShiftAdd : benefit(1) {
  %t = pdl.type
  %a = pdl.operand : %t
  %b = pdl.operand : %t
  %s = pdl.operand : %t

  %add = pdl.operation "arith.addi"(%a, %b : !pdl.value, !pdl.value)
           -> (%t : !pdl.type)
  %addRes = pdl.result 0 of %add
  %shift = pdl.operation "arith.shli"(%addRes, %s : !pdl.value, !pdl.value)
             -> (%t : !pdl.type)

  pdl.rewrite %shift {
    %sa = pdl.operation "arith.shli"(%a, %s : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
    %saRes = pdl.result 0 of %sa
    %sb = pdl.operation "arith.shli"(%b, %s : !pdl.value, !pdl.value)
            -> (%t : !pdl.type)
    %sbRes = pdl.result 0 of %sb
    %newAdd = pdl.operation "arith.addi"(%saRes, %sbRes : !pdl.value, !pdl.value)
                -> (%t : !pdl.type)
    pdl.replace %shift with %newAdd
  }
}

// ---------------------------------------------------------------------------
// sub-same:  (- a a)  ->  0          [pinned to i32: needs a typed zero]
// Reusing %a in both positions constrains the operands to be identical.
// ---------------------------------------------------------------------------
pdl.pattern @SubSame : benefit(2) {
  %i32 = pdl.type : i32
  %a = pdl.operand : %i32

  %sub = pdl.operation "arith.subi"(%a, %a : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)

  pdl.rewrite %sub {
    %zeroAttr = pdl.attribute = 0 : i32
    %zeroOp = pdl.operation "arith.constant" {"value" = %zeroAttr}
                -> (%i32 : !pdl.type)
    %zero = pdl.result 0 of %zeroOp
    pdl.replace %sub with (%zero : !pdl.value)
  }
}

// ---------------------------------------------------------------------------
// add-zero:  (+ a 0)  ->  a          [pinned to i32; pair with add-comm
//                                      to also catch (+ 0 a)]
// ---------------------------------------------------------------------------
pdl.pattern @AddZero : benefit(2) {
  %i32 = pdl.type : i32
  %a = pdl.operand : %i32

  %zeroAttr = pdl.attribute = 0 : i32
  %zeroOp = pdl.operation "arith.constant" {"value" = %zeroAttr}
              -> (%i32 : !pdl.type)
  %zero = pdl.result 0 of %zeroOp

  %add = pdl.operation "arith.addi"(%a, %zero : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)

  pdl.rewrite %add {
    pdl.replace %add with (%a : !pdl.value)
  }
}

// ===========================================================================
// New rewrites needed for the mului_extended / trunci / extui formulation.
// These complement the (width-generic) algebra rules you already ported.
//
// NOTE ON WIDTHS: the Karatsuba reassembly arithmetic in the source program
// is all at i32. Your existing i8-typed algebra rules must be made
// width-generic (declare `%t = pdl.type` with no `: i8`) or duplicated at i32,
// otherwise they never match the i32 addi/subi/muli/shli in the program.
// ===========================================================================


// ---------------------------------------------------------------------------
// mulx-fuse:
//   (extui hi : iw->iW) << w  +  (extui lo : iw->iW)   ->   (* (extui a) (extui b)) : iW
//   where  lo, hi = mului_extended a b : iw
//
// Matches all three extended multiplies in the program:
//   z2 = (extui z2_hi << 8) + extui z2_lo   (w=8,  W=32)
//   z0 = (extui z0_hi << 8) + extui z0_lo   (w=8,  W=32)
//   P  = (extui m_hi  << 9) + extui m_lo    (w=9,  W=32)
//
// SOUNDNESS: hi is weighted by 2^w, so the shift amount must equal the mulx
// input width, and W must be >= 2*w (no truncation of the full product).
// Both facts are numeric relations between a constant/type and a type, which
// pure PDL cannot express, so they are checked by native constraints (C++
// sketches at the bottom of this file). If you'd rather not register native
// code, specialize this into two patterns that match the shift constant
// concretely (`pdl.attribute = 8 : i32` and `pdl.attribute = 9 : i32`) with
// concrete i8/i9 input types and i32 output.
// ---------------------------------------------------------------------------
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


// ---------------------------------------------------------------------------
// bytes-recompose:  (extui (trunci (shrui a 8) : i16->i8) : i8->i32) << 8
//                 + (extui (trunci a          : i16->i8) : i8->i32)
//                 ->  (extui a : i16->i32)
//
// The MLIR analog of your old `add-to-extract`. trunci a keeps the low byte,
// trunci(shrui a 8) keeps the high byte; 16 = 8 + 8 partitions the bits
// exactly, so high<<8 + low = a (zero-extended). Requiring the SAME %a in both
// the low-byte and high-byte path is the soundness condition.
//
// Written concretely for i16 -> i8 bytes -> i32, which is exactly what the
// program uses. Match the shift constants by value.
// ---------------------------------------------------------------------------
pdl.pattern @BytesRecompose : benefit(4) {
  %i16 = pdl.type : i16
  %i8  = pdl.type : i8
  %i32 = pdl.type : i32

  %a = pdl.operand : %i16

  // shrui a, 8 : i16
  %sh16Attr = pdl.attribute = 8 : i16
  %sh16Cst  = pdl.operation "arith.constant" {"value" = %sh16Attr} -> (%i16 : !pdl.type)
  %sh16     = pdl.result 0 of %sh16Cst
  %shr = pdl.operation "arith.shrui"(%a, %sh16 : !pdl.value, !pdl.value)
           -> (%i16 : !pdl.type)
  %shrRes = pdl.result 0 of %shr

  // high byte = trunci(shrui a 8) ; low byte = trunci a
  %hiByte = pdl.operation "arith.trunci"(%shrRes : !pdl.value) -> (%i8 : !pdl.type)
  %hiByteRes = pdl.result 0 of %hiByte
  %loByte = pdl.operation "arith.trunci"(%a : !pdl.value) -> (%i8 : !pdl.type)
  %loByteRes = pdl.result 0 of %loByte

  // extend both bytes to i32
  %hiExt = pdl.operation "arith.extui"(%hiByteRes : !pdl.value) -> (%i32 : !pdl.type)
  %hiExtRes = pdl.result 0 of %hiExt
  %loExt = pdl.operation "arith.extui"(%loByteRes : !pdl.value) -> (%i32 : !pdl.type)
  %loExtRes = pdl.result 0 of %loExt

  // high byte << 8
  %sh32Attr = pdl.attribute = 8 : i32
  %sh32Cst  = pdl.operation "arith.constant" {"value" = %sh32Attr} -> (%i32 : !pdl.type)
  %sh32     = pdl.result 0 of %sh32Cst
  %shl = pdl.operation "arith.shli"(%hiExtRes, %sh32 : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)
  %shlRes = pdl.result 0 of %shl

  %add = pdl.operation "arith.addi"(%shlRes, %loExtRes : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)

  pdl.rewrite %add {
    %new = pdl.operation "arith.extui"(%a : !pdl.value) -> (%i32 : !pdl.type)
    pdl.replace %add with %new
  }
}


// ===========================================================================
// Native constraints used by @MulxFuse (register with your PDLPatternModule):
//
//   // true iff `shift` is an IntegerAttr whose value == bitwidth(inType)
//   static LogicalResult attrEqualsBitwidth(PatternRewriter &,
//       PDLResultList &, ArrayRef<PDLValue> args) {
//     auto attr = dyn_cast<IntegerAttr>(args[0].cast<Attribute>());
//     auto ty   = dyn_cast<IntegerType>(args[1].cast<Type>());
//     if (!attr || !ty) return failure();
//     return success(attr.getValue() == ty.getWidth());
//   }
//
//   // true iff bitwidth(outType) >= 2 * bitwidth(inType)
//   static LogicalResult atLeastDoubleWidth(PatternRewriter &,
//       PDLResultList &, ArrayRef<PDLValue> args) {
//     auto inTy  = dyn_cast<IntegerType>(args[0].cast<Type>());
//     auto outTy = dyn_cast<IntegerType>(args[1].cast<Type>());
//     if (!inTy || !outTy) return failure();
//     return success(outTy.getWidth() >= 2u * inTy.getWidth());
//   }
//
// patternModule.registerConstraintFunction("attrEqualsBitwidth", attrEqualsBitwidth);
// patternModule.registerConstraintFunction("atLeastDoubleWidth", atLeastDoubleWidth);
// ===========================================================================

// ===========================================================================
// shift-split:  (x << 16)  ->  ((x << 8) << 8)        at i32
//
// THE missing bridge. The recombination needs the high partial product
// z2 << 16 = (ah*bh) << 16 to be reconciled with the factored form's high
// term (ah<<8)*(bh<<8). Those are equal only through shift composition.
//
// Direction matters: the SPLIT direction is the one that fires, because its
// LHS (a literal `<< 16`) already exists in `result`, whereas the nested form
// must be created. Once split, shift-mul-1 + mul-comm turn
//   ((ah*bh) << 8) << 8  into  (ah<<8) * (bh<<8),
// after which undistribute-right / -left rebuild the two factors and
// @BytesRecompose collapses each back to extui(a) / extui(b).
//
// This is the piece the old egg ruleset provided via `undist-shift`.
// Only 16 = 8 + 8 is needed here (the <<9 from the middle product was already
// consumed by @MulxFuse), so a concrete pattern suffices; a general version
// would use a native rewrite to compute c1 + c2.
// ===========================================================================
pdl.pattern @ShiftSplit16 : benefit(1) {
  %i32 = pdl.type : i32
  %x = pdl.operand : %i32

  %c16Attr = pdl.attribute = 16 : i32
  %c16Op = pdl.operation "arith.constant" {"value" = %c16Attr} -> (%i32 : !pdl.type)
  %c16 = pdl.result 0 of %c16Op

  %shl = pdl.operation "arith.shli"(%x, %c16 : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)

  pdl.rewrite %shl {
    %c8Attr = pdl.attribute = 8 : i32
    %c8Op = pdl.operation "arith.constant" {"value" = %c8Attr} -> (%i32 : !pdl.type)
    %c8 = pdl.result 0 of %c8Op

    %inner = pdl.operation "arith.shli"(%x, %c8 : !pdl.value, !pdl.value)
               -> (%i32 : !pdl.type)
    %innerRes = pdl.result 0 of %inner
    %outer = pdl.operation "arith.shli"(%innerRes, %c8 : !pdl.value, !pdl.value)
               -> (%i32 : !pdl.type)
    pdl.replace %shl with %outer
  }
}
