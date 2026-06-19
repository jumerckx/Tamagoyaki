// RUN: true
// Input fixture (not a standalone test); see saturation-canonicalize.mlir.

func.func @commutator(%a: f64, %b: f64) -> f64 {
  %one = arith.constant 1.0 : f64

  // inverses
  %a_inv = arith.divf %one, %a : f64   // a^(-1)
  %b_inv = arith.divf %one, %b : f64   // b^(-1)

  // %a_inv_b_inv = arith.mulf %a_inv, %b_inv : f64   // a^(-1)*b^(-1)
  // %a_b = arith.mulf %a, %b : f64   // a*b
  // %t2 = arith.mulf %a_b, %a_inv_b_inv : f64   // a*b*a^(-1)*b^(-1)

  // ((a * b) * a^(-1)) * b^(-1)
  %t0 = arith.mulf %a,  %b     : f64   // a*b
  %t1 = arith.mulf %t0, %a_inv : f64   // a*b*a^(-1)
  %t2 = arith.mulf %t1, %b_inv : f64   // a*b*a^(-1)*b^(-1)

  return %t2 : f64
}
