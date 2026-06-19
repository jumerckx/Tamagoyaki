// ===========================================================================
// Goal pattern: the expected fully-simplified expression.
//
// Used (like @CrossTermToKaratsuba) to check whether the saturated e-graph
// contains the faithful 16x16 -> 32 unsigned product of the two i16 function
// arguments:
//
//     muli( extui(a : i16 -> i32), extui(b : i16 -> i32) ) : i32
//
// where %a is the first i16 argument of @karatsuba_mul and %b is the second.
//
// This is the HONEST target: the full 32-bit product. It is NOT
// `extui(muli(a, b) : i16)`, which truncates to 16 bits before extending.
//
// Commutativity note: with mul-comm in the rule set, the e-class also contains
// muli(extui(b), extui(a)), so matching a single operand order is sufficient
// for a containment check.
// ===========================================================================
pdl.pattern @SimplifiedProduct : benefit(1) {
  %i16 = pdl.type : i16
  %i32 = pdl.type : i32

  // The two original i16 inputs of the function.
  %a = pdl.operand : %i16
  pdl.apply_native_constraint "is_arg_0"(%a : !pdl.value)
  %b = pdl.operand : %i16
  pdl.apply_native_constraint "is_arg_1"(%b : !pdl.value)

  // Each input zero-extended to i32.
  %aExt = pdl.operation "arith.extui"(%a : !pdl.value) -> (%i32 : !pdl.type)
  %aExtRes = pdl.result 0 of %aExt
  %bExt = pdl.operation "arith.extui"(%b : !pdl.value) -> (%i32 : !pdl.type)
  %bExtRes = pdl.result 0 of %bExt

  // The full 32-bit product.
  %mul = pdl.operation "arith.muli"(%aExtRes, %bExtRes : !pdl.value, !pdl.value)
           -> (%i32 : !pdl.type)

  pdl.rewrite %mul with "rewriter"
}


// ===========================================================================
// Containment probe: has saturation reached the stage right before recombine?
//
// Matches (rooted at the final addi, so "contained" == present at root):
//
//   result = ((z2 << 16) + (z1 << 8)) + z0
//     z2 = AH*BH
//     z0 = AL*BL
//     z1 = AL*BH + AH*BL
//   with  AH = extui(trunci(shrui a 8)), AL = extui(trunci a)
//         BH = extui(trunci(shrui b 8)), BL = extui(trunci b)
//
// A "contained" result here proves MulxFuse (z2/z0/P), ZextAdd/ZextCompose
// (the i9 path), DistributeMult, and the AssocAddSub/SubSame/AddZero
// cancellation all completed -- i.e. the front half is done and only the
// recombine rules still need to fire.
//
// This is an EXACT-structure probe. The e-graph is closed under AddComm/MulComm,
// so the commutative variants of every node below are also present and a single
// ordering should match. If it reports "not contained", first try swapping
// operand orders (z1's two products; s1's hi/mid; result's s1/z0; each muli's
// factors) to rule out an ordering artifact before concluding the cancellation
// or fusion genuinely did not complete.
//
// NOTE on is_arg_*: as with @SimplifiedProduct, this assumes is_arg_0/is_arg_1
// identify the two i16 block arguments %a and %b. If your is_arg_* family is
// byte-indexed instead, drop these constraints (the byte-extraction tree already
// pins %a/%b) or swap in the constraint that recognizes the i16 inputs.
// ===========================================================================
pdl.pattern @PreRecombineStage : benefit(1) {
  %i16 = pdl.type : i16
  %i8  = pdl.type : i8
  %i32 = pdl.type : i32

  // --- function arguments ---
  %a = pdl.operand : %i16
  pdl.apply_native_constraint "is_arg_0"(%a : !pdl.value)
  %b = pdl.operand : %i16
  pdl.apply_native_constraint "is_arg_1"(%b : !pdl.value)

  // --- constants ---
  %c8_16Attr = pdl.attribute = 8 : i16
  %c8_16Op = pdl.operation "arith.constant" {"value" = %c8_16Attr} -> (%i16 : !pdl.type)
  %c8_16 = pdl.result 0 of %c8_16Op

  %c8_32Attr = pdl.attribute = 8 : i32
  %c8_32Op = pdl.operation "arith.constant" {"value" = %c8_32Attr} -> (%i32 : !pdl.type)
  %c8_32 = pdl.result 0 of %c8_32Op

  %c16_32Attr = pdl.attribute = 16 : i32
  %c16_32Op = pdl.operation "arith.constant" {"value" = %c16_32Attr} -> (%i32 : !pdl.type)
  %c16_32 = pdl.result 0 of %c16_32Op

  // --- AH = extui(trunci(shrui a 8)) , AL = extui(trunci a) ---
  %ah_w = pdl.operation "arith.shrui"(%a, %c8_16 : !pdl.value, !pdl.value) -> (%i16 : !pdl.type)
  %ah_wRes = pdl.result 0 of %ah_w
  %ahOp = pdl.operation "arith.trunci"(%ah_wRes : !pdl.value) -> (%i8 : !pdl.type)
  %ah = pdl.result 0 of %ahOp
  %alOp = pdl.operation "arith.trunci"(%a : !pdl.value) -> (%i8 : !pdl.type)
  %al = pdl.result 0 of %alOp

  // --- BH = extui(trunci(shrui b 8)) , BL = extui(trunci b) ---
  %bh_w = pdl.operation "arith.shrui"(%b, %c8_16 : !pdl.value, !pdl.value) -> (%i16 : !pdl.type)
  %bh_wRes = pdl.result 0 of %bh_w
  %bhOp = pdl.operation "arith.trunci"(%bh_wRes : !pdl.value) -> (%i8 : !pdl.type)
  %bh = pdl.result 0 of %bhOp
  %blOp = pdl.operation "arith.trunci"(%b : !pdl.value) -> (%i8 : !pdl.type)
  %bl = pdl.result 0 of %blOp

  // --- zero-extend the four bytes to i32 ---
  %AHOp = pdl.operation "arith.extui"(%ah : !pdl.value) -> (%i32 : !pdl.type)
  %AH = pdl.result 0 of %AHOp
  %ALOp = pdl.operation "arith.extui"(%al : !pdl.value) -> (%i32 : !pdl.type)
  %AL = pdl.result 0 of %ALOp
  %BHOp = pdl.operation "arith.extui"(%bh : !pdl.value) -> (%i32 : !pdl.type)
  %BH = pdl.result 0 of %BHOp
  %BLOp = pdl.operation "arith.extui"(%bl : !pdl.value) -> (%i32 : !pdl.type)
  %BL = pdl.result 0 of %BLOp

  // --- z2 = AH*BH , z0 = AL*BL ---
  %z2Op = pdl.operation "arith.muli"(%AH, %BH : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %z2 = pdl.result 0 of %z2Op
  %z0Op = pdl.operation "arith.muli"(%AL, %BL : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %z0 = pdl.result 0 of %z0Op

  // --- z1 = AL*BH + AH*BL  (cross term) ---
  %albhOp = pdl.operation "arith.muli"(%AL, %BH : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %albh = pdl.result 0 of %albhOp
  %ahblOp = pdl.operation "arith.muli"(%AH, %BL : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %ahbl = pdl.result 0 of %ahblOp
  %z1Op = pdl.operation "arith.addi"(%albh, %ahbl : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %z1 = pdl.result 0 of %z1Op

  // --- result = (z2 << 16) + (z1 << 8) + z0   (recombine NOT yet applied) ---
  %hiOp = pdl.operation "arith.shli"(%z2, %c16_32 : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %hi = pdl.result 0 of %hiOp
  %midOp = pdl.operation "arith.shli"(%z1, %c8_32 : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %mid = pdl.result 0 of %midOp
  %s1Op = pdl.operation "arith.addi"(%hi, %mid : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
  %s1 = pdl.result 0 of %s1Op
  %result = pdl.operation "arith.addi"(%s1, %z0 : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)

  pdl.rewrite %result with "rewriter"
}
