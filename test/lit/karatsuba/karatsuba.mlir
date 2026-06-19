func.func @karatsuba_mul(%a: i16, %b: i16) -> i32 {
  %c8_16  = arith.constant 8  : i16
  %c8_32  = arith.constant 8  : i32
  %c9_32  = arith.constant 9  : i32
  %c16_32 = arith.constant 16 : i32

  %ah_w = arith.shrui  %a, %c8_16 : i16
  %ah   = arith.trunci %ah_w : i16 to i8        // a >> 8
  %al   = arith.trunci %a    : i16 to i8        // a & 0xff  (low byte)
  %bh_w = arith.shrui  %b, %c8_16 : i16
  %bh   = arith.trunci %bh_w : i16 to i8        // b >> 8
  %bl   = arith.trunci %b    : i16 to i8        // b & 0xff

  // --- z2 = ah*bh, z0 = al*bl : real 8x8 -> 16 multiplies ---
  %z2_lo, %z2_hi = arith.mului_extended %ah, %bh : i8
  %z0_lo, %z0_hi = arith.mului_extended %al, %bl : i8

  %ah9 = arith.extui %ah : i8 to i9
  %al9 = arith.extui %al : i8 to i9
  %sa  = arith.addi  %ah9, %al9 : i9            // ah + al  (max 510, fits in i9)
  %bh9 = arith.extui %bh : i8 to i9
  %bl9 = arith.extui %bl : i8 to i9
  %sb  = arith.addi  %bh9, %bl9 : i9            // bh + bl

  // 9x9 -> 18-bit product, splits exactly into i9 lo:hi
  %m_lo, %m_hi = arith.mului_extended %sa, %sb : i9

  // reassemble the three products into i32 (shifts/adds only)
  %z2_hi32 = arith.extui %z2_hi : i8 to i32
  %z2_lo32 = arith.extui %z2_lo : i8 to i32
  %z2_hsh  = arith.shli  %z2_hi32, %c8_32 : i32
  %z2      = arith.addi  %z2_hsh, %z2_lo32 : i32

  %z0_hi32 = arith.extui %z0_hi : i8 to i32
  %z0_lo32 = arith.extui %z0_lo : i8 to i32
  %z0_hsh  = arith.shli  %z0_hi32, %c8_32 : i32
  %z0      = arith.addi  %z0_hsh, %z0_lo32 : i32

  %m_hi32  = arith.extui %m_hi : i9 to i32
  %m_lo32  = arith.extui %m_lo : i9 to i32
  %m_hsh   = arith.shli  %m_hi32, %c9_32 : i32  // hi half is worth 2^9 now
  %P       = arith.addi  %m_hsh, %m_lo32 : i32  // (ah+al)*(bh+bl)

  // z1 = P - z2 - z0  ( = ah*bl + al*bh )
  %t  = arith.subi %P, %z2 : i32
  %z1 = arith.subi %t, %z0 : i32

  // recombine: z2<<16 + z1<<8 + z0
  %hi  = arith.shli %z2, %c16_32 : i32
  %mid = arith.shli %z1, %c8_32  : i32
  %s1  = arith.addi %hi, %mid : i32
  %result = arith.addi %s1, %z0 : i32
  return %result : i32
}
