func.func @karatsuba_middle(%ah: i8, %al: i8, %bh: i8, %bl: i8) -> i8 {
  %sum_a  = arith.addi %ah, %al : i8        // ah + al
  %sum_b  = arith.addi %bh, %bl : i8        // bh + bl
  %prod   = arith.muli %sum_a, %sum_b : i8  // (ah+al)*(bh+bl)
  %ah_bh  = arith.muli %ah, %bh : i8        // ah*bh
  %al_bl  = arith.muli %al, %bl : i8        // al*bl
  %t      = arith.subi %prod, %ah_bh : i8   // prod - ah*bh
  %result = arith.subi %t, %al_bl : i8      // ... - al*bl
  return %result : i8
}
