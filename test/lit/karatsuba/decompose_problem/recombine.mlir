// Partially-simplified Karatsuba program, exactly as it stands right before the
// recombination steps (ShiftAdd / ShiftSplit16 / ShiftMul1 / Undistribute /
// BytesRecompose) are applied.
//
// Already done:
//   * MulxFuse           : z2, z0, and P folded from mului_extended back to muli
//   * ZextAdd/ZextCompose: the i9 path lifted, so P became (AH+AL)*(BH+BL)
//   * DistributeMult     : P expanded into the four byte products
//   * AssocAddSub/SubSame/AddZero : the two cancellations, giving
//                          z1 = AL*BH + AH*BL  (the cross term)
//
// Still in original form (recombine not yet applied):
//   result = (z2 << 16) + (z1 << 8) + z0
//
// The byte-extraction / extui chains are intentionally preserved: BytesRecompose
// needs AH = extui(trunci(shrui a 8)) etc. to fold the factors back to extui(a).
//
// Saturating FROM THIS input with only the recombine rules is a clean isolation
// test: if it reaches muli(extui a, extui b) here, the front half is fine and the
// failure on the full program is the AC-explosion budget; if it still stalls,
// there is a real matching bug in the recombine rules.
func.func @karatsuba_mul_partial(%a: i16, %b: i16) -> i32 {
  %c8_16  = arith.constant 8  : i16
  %c8_32  = arith.constant 8  : i32
  %c16_32 = arith.constant 16 : i32

  // --- byte extraction (unchanged from the original program) ---
  %ah_w = arith.shrui %a, %c8_16 : i16
  %ah   = arith.trunci %ah_w : i16 to i8        // a >> 8
  %al   = arith.trunci %a    : i16 to i8        // a & 0xff
  %bh_w = arith.shrui %b, %c8_16 : i16
  %bh   = arith.trunci %bh_w : i16 to i8        // b >> 8
  %bl   = arith.trunci %b    : i16 to i8        // b & 0xff

  // --- bytes zero-extended to i32:  AH, AL, BH, BL ---
  %AH = arith.extui %ah : i8 to i32
  %AL = arith.extui %al : i8 to i32
  %BH = arith.extui %bh : i8 to i32
  %BL = arith.extui %bl : i8 to i32

  // --- z2 = AH*BH , z0 = AL*BL   (post-MulxFuse) ---
  %z2 = arith.muli %AH, %BH : i32
  %z0 = arith.muli %AL, %BL : i32

  // --- z1 = AL*BH + AH*BL   (cross term, post-distribute + cancel) ---
  %albh = arith.muli %AL, %BH : i32
  %ahbl = arith.muli %AH, %BL : i32
  %z1   = arith.addi %albh, %ahbl : i32

  // --- result = (z2 << 16) + (z1 << 8) + z0   (recombine NOT yet applied) ---
  %hi  = arith.shli %z2, %c16_32 : i32
  %mid = arith.shli %z1, %c8_32  : i32
  %s1  = arith.addi %hi, %mid : i32
  %result = arith.addi %s1, %z0 : i32
  return %result : i32
}
