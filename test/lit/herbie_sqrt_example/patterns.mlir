// Herbie rewrite ruleset in pdl, copied from the herbie_mlir case study in
// tamagoyaki-case-studies (rules_pdl.mlir). Generated from
// herbie_mlir/rules.rkt with:
//   herbie-pdl herbie_mlir/rules.rkt > rules_pdl.mlir
// Do not edit by hand; regenerate from the case study instead.

// RUN: true

pdl.pattern @add_commutative : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.addf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    pdl.replace %1 with (%4 : !pdl.value)
  }
}
pdl.pattern @mul_commutative : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.mulf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    pdl.replace %1 with (%4 : !pdl.value)
  }
}
pdl.pattern @associate_addradd : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_addladd : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_addr_ : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.subf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_addl_ : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.subf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associatesub_radd : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.subf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associatesub_ladd : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associatesub_l_ : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.subf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associatesub_r_ : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_mulrmul : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_mullmul : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_mulrdiv : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_mulldiv : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_divrmul : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_divrdiv : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_divldiv : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%b, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @associate_divlmul : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%b, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @remove_double_div : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 1.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%6, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%3, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    pdl.replace %9 with (%a : !pdl.value)
  }
}
pdl.pattern @rgt_mult_inverse : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %6 with (%10 : !pdl.value)
  }
}
pdl.pattern @lft_mult_inverse : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%5, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %6 with (%10 : !pdl.value)
  }
}
pdl.pattern @add_inverses : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 0.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    pdl.replace %1 with (%5 : !pdl.value)
  }
}
pdl.pattern @div0 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @mul0_lft : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @mul0_rgt : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @mul_inverses : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 1.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    pdl.replace %1 with (%5 : !pdl.value)
  }
}
pdl.pattern @add_lft_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @add_rgt_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @sub_rgt_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.subf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @sub0_neg : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.subf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @remove_double_neg : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%a : !pdl.value)
  }
}
pdl.pattern @mul_lft_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @mul_rgt_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @div_rgt_identity : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @mul_1_neg : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = -1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @count_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 2.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "arith.mulf" (%5, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %1 with (%7 : !pdl.value)
  }
}
pdl.pattern @_2_split : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 1.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %2 with (%11 : !pdl.value)
  }
}
pdl.pattern @count_2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.addf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @_1_split : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 2.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 5.000000e-01 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.mulf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %2 with (%11 : !pdl.value)
  }
}
pdl.pattern @distribute_lft_in : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt_in : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_lft_out : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_lft_outsub_ : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt_out : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt_outsub_ : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_lft1_in : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%b, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.mulf" (%9, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt1_in : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%c, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.mulf" (%9, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @distribute_lft_neg_in : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt_neg_in : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_lft_neg_out : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_rgt_neg_out : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_neg_in : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_neg_out : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.negf" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @distribute_frac_neg : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_frac_neg2 : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_neg_frac : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @distribute_neg_frac2 : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @fp_cancel_sign_sub : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%a, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @fp_cancel_sub_sign : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%a, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @fp_cancel_sign_sub_inv : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @fp_cancel_sub_sign_inv : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%6, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @sub_flip : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.addf" (%a, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @sub_flip_reverse : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @sub_negate : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @sub_negate_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.subf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @add_flip : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.subf" (%a, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @add_flip_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @swap_sqr : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @unswap_sqr : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @difference_of_squares : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @difference_of_sqr_1 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%a, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 1.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%a, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%12, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %6 with (%19 : !pdl.value)
  }
}
pdl.pattern @difference_of_sqrsub_1 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = -1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%a, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 1.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%a, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%12, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %6 with (%19 : !pdl.value)
  }
}
pdl.pattern @pow_sqr : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.mulf" (%9, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.powf" (%a, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %5 with (%13 : !pdl.value)
  }
}
pdl.pattern @sum_square_pow : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 2.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.powf" (%a, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 2.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.addf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.attribute = 2.000000e+00 : f64
    %23 = pdl.operation "arith.constant" {"value" = %22} -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "math.powf" (%b, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.addf" (%21, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %6 with (%28 : !pdl.value)
  }
}
pdl.pattern @sub_square_pow : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 2.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.powf" (%a, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 2.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.subf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.attribute = 2.000000e+00 : f64
    %23 = pdl.operation "arith.constant" {"value" = %22} -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "math.powf" (%b, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.addf" (%21, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %6 with (%28 : !pdl.value)
  }
}
pdl.pattern @sum_square_pow_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%5, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "math.powf" (%b, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "arith.addf" (%14, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  pdl.rewrite %20 {
    %22 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.attribute = 2.000000e+00 : f64
    %25 = pdl.operation "arith.constant" {"value" = %24} -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "math.powf" (%23, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %20 with (%28 : !pdl.value)
  }
}
pdl.pattern @sub_square_pow_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%5, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "math.powf" (%b, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "arith.addf" (%14, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  pdl.rewrite %20 {
    %22 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.attribute = 2.000000e+00 : f64
    %25 = pdl.operation "arith.constant" {"value" = %24} -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "math.powf" (%23, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %20 with (%28 : !pdl.value)
  }
}
pdl.pattern @difference_of_sqr_1_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 1.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.subf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.subf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %11 with (%19 : !pdl.value)
  }
}
pdl.pattern @difference_of_sqrsub_1_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 1.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.subf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = -1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.addf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %11 with (%19 : !pdl.value)
  }
}
pdl.pattern @difference_of_squares_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.subf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @mult_flip : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 1.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "arith.divf" (%5, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%a, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %1 with (%9 : !pdl.value)
  }
}
pdl.pattern @mult_flip_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %6 with (%9 : !pdl.value)
  }
}
pdl.pattern @div_flip : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 1.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "herbie.sound_div" (%b, %a, %8 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "herbie.sound_div" (%5, %10, %12 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %1 with (%14 : !pdl.value)
  }
}
pdl.pattern @div_flip_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %6 with (%9 : !pdl.value)
  }
}
pdl.pattern @sum_to_mult_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%7, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %8 with (%11 : !pdl.value)
  }
}
pdl.pattern @sub_to_mult_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%7, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %8 with (%11 : !pdl.value)
  }
}
pdl.pattern @add_to_fraction : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %c = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%c, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @add_to_fraction_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %c = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.addf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%4, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%c, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @sub_to_fraction : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %c = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%c, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.subf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @sub_to_fraction_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %c = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.subf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%4, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%c, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @common_denominator : benefit(1) {
  %0 = pdl.type : f64
  %d = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%c, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%c, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%b, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %5 with (%16 : !pdl.value)
  }
}
pdl.pattern @flip_add : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.addf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "herbie.sound_div" (%8, %14, %20 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    pdl.replace %5 with (%22 : !pdl.value)
  }
}
pdl.pattern @flipsub_ : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sqrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "herbie.sound_div" (%8, %14, %20 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    pdl.replace %5 with (%22 : !pdl.value)
  }
}
pdl.pattern @sum_cubes : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 3.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.powf" (%b, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "arith.addf" (%14, %20 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%22, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    pdl.replace %11 with (%26 : !pdl.value)
  }
}
pdl.pattern @difference_cubes : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 3.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.powf" (%b, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.addf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "arith.addf" (%14, %20 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%22, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    pdl.replace %11 with (%26 : !pdl.value)
  }
}
pdl.pattern @difference_cubes_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.addf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%2, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 3.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.powf" (%a, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.attribute = 3.000000e+00 : f64
    %21 = pdl.operation "arith.constant" {"value" = %20} -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.powf" (%b, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.subf" (%19, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    pdl.replace %13 with (%26 : !pdl.value)
  }
}
pdl.pattern @sum_cubes_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%b, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.subf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%2, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 3.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.powf" (%a, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.attribute = 3.000000e+00 : f64
    %21 = pdl.operation "arith.constant" {"value" = %20} -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.powf" (%b, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.addf" (%19, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    pdl.replace %13 with (%26 : !pdl.value)
  }
}
pdl.pattern @flip3_add : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.mulf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%22, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.subf" (%20, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    %29 = pdl.operation "arith.addf" (%14, %28 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %30 = pdl.result 0 of %29
    %31 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %32 = pdl.result 0 of %31
    %33 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %34 = pdl.result 0 of %33
    %35 = pdl.operation "arith.addf" (%32, %34 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %36 = pdl.result 0 of %35
    %37 = pdl.operation "herbie.sound_div" (%8, %30, %36 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %38 = pdl.result 0 of %37
    pdl.replace %5 with (%38 : !pdl.value)
  }
}
pdl.pattern @flip3sub_ : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.mulf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%22, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.addf" (%20, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    %29 = pdl.operation "arith.addf" (%14, %28 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %30 = pdl.result 0 of %29
    %31 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %32 = pdl.result 0 of %31
    %33 = pdl.operation "math.cbrt" (%b : !pdl.value) -> (%0 : !pdl.type)
    %34 = pdl.result 0 of %33
    %35 = pdl.operation "arith.subf" (%32, %34 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %36 = pdl.result 0 of %35
    %37 = pdl.operation "herbie.sound_div" (%8, %30, %36 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %38 = pdl.result 0 of %37
    pdl.replace %5 with (%38 : !pdl.value)
  }
}
pdl.pattern @div_sub : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @times_frac : benefit(1) {
  %0 = pdl.type : f64
  %d = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%c, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%b, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @div_add : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.divf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @div_add_rev : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @sub_div : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @frac_add : benefit(1) {
  %0 = pdl.type : f64
  %d = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%c, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%b, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %5 with (%16 : !pdl.value)
  }
}
pdl.pattern @frac_sub : benefit(1) {
  %0 = pdl.type : f64
  %d = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%c, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.subf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%b, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %5 with (%16 : !pdl.value)
  }
}
pdl.pattern @frac_times : benefit(1) {
  %0 = pdl.type : f64
  %d = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%c, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%b, %d : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.divf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    pdl.replace %5 with (%12 : !pdl.value)
  }
}
pdl.pattern @frac_2neg : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %1 with (%8 : !pdl.value)
  }
}
pdl.pattern @frac_2neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @rem_square_sqrt : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    pdl.replace %5 with (%x : !pdl.value)
  }
}
pdl.pattern @rem_sqrt_square : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @rem_sqrt_square_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.sqrt" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @sqr_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @sqr_abs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @sqr_abs_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %1 with (%8 : !pdl.value)
  }
}
pdl.pattern @sqr_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.mulf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %1 with (%8 : !pdl.value)
  }
}
pdl.pattern @sqrt_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cbrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cbrt_sqrt : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sqrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @fabs_fabs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_sub : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.subf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.absf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @fabs_add : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.absf" (%6 : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  pdl.rewrite %7 {
    %9 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %7 with (%14 : !pdl.value)
  }
}
pdl.pattern @fabs_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_sqr : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_mul : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @fabs_div : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @neg_fabs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.absf" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @mul_fabs : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @div_fabs : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @sqrt_fabs : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @sqrt_fabs_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.absf" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_lhs_div : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.copysign" (%7, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %3 with (%9 : !pdl.value)
  }
}
pdl.pattern @fabs_rhs_div : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%x, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.copysign" (%7, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %3 with (%9 : !pdl.value)
  }
}
pdl.pattern @fabs_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.absf" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @fabs_cbrt_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.divf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%6, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @copysign_neg : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.copysign" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.copysign" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @neg_copysign : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.copysign" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.copysign" (%a, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @copysign_other_neg : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.copysign" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.copysign" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @copysign_fabs : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.copysign" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @copysign_other_fabs : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.copysign" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.copysign" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_copysign : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.copysign" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @sqrt_pow2 : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%2, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 2.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%y, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.powf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @sqrt_unprod : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.sqrt" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @sqrt_undiv : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.sqrt" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @sqrt_prod : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sqrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%y : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sqrt" (%10 : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%8, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %3 with (%14 : !pdl.value)
  }
}
pdl.pattern @sqrt_div : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sqrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%y : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sqrt" (%10 : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.divf" (%8, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %3 with (%14 : !pdl.value)
  }
}
pdl.pattern @rem_cube_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 3.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    pdl.replace %6 with (%x : !pdl.value)
  }
}
pdl.pattern @rem_cbrt_cube : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cbrt" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    pdl.replace %6 with (%x : !pdl.value)
  }
}
pdl.pattern @rem_3cbrt_lft : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    pdl.replace %9 with (%x : !pdl.value)
  }
}
pdl.pattern @rem_3cbrt_rft : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.mulf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.mulf" (%2, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    pdl.replace %9 with (%x : !pdl.value)
  }
}
pdl.pattern @cube_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 3.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 3.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.powf" (%x, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.negf" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %6 with (%14 : !pdl.value)
  }
}
pdl.pattern @cube_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.negf" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 3.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.powf" (%9, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %6 with (%14 : !pdl.value)
  }
}
pdl.pattern @cube_prod : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 3.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 3.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.powf" (%x, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 3.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.powf" (%y, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%12, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %6 with (%19 : !pdl.value)
  }
}
pdl.pattern @cube_div : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 3.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 3.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.powf" (%x, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 3.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.powf" (%y, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.divf" (%12, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %6 with (%19 : !pdl.value)
  }
}
pdl.pattern @cube_mult : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %4 with (%9 : !pdl.value)
  }
}
pdl.pattern @cube_prod_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 3.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.powf" (%y, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 3.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.powf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %11 with (%19 : !pdl.value)
  }
}
pdl.pattern @cube_div_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 3.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.powf" (%y, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.divf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 3.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.powf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %11 with (%19 : !pdl.value)
  }
}
pdl.pattern @cbrt_prod : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cbrt" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @cbrt_div : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cbrt" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @cbrt_unprod : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cbrt" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @cbrt_undiv : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cbrt" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @pow_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%2, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 3.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%y, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.powf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @cbrt_pow : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 3.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%y, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.powf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @cube_unmult : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%x, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 3.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.powf" (%x, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %3 with (%9 : !pdl.value)
  }
}
pdl.pattern @cbrt_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cbrt_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cbrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cbrt_fabs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.absf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cbrt_fabs_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cbrt" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cbrt_div_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.absf" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  pdl.rewrite %7 {
    %9 = pdl.attribute = 1.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.copysign" (%11, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %7 with (%13 : !pdl.value)
  }
}
pdl.pattern @cbrt_div_cbrt2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.cbrt" (%x : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  pdl.rewrite %7 {
    %9 = pdl.attribute = 1.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.copysign" (%11, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %7 with (%13 : !pdl.value)
  }
}
pdl.pattern @fmin_swap : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "fmin" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "fmin" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    pdl.replace %1 with (%4 : !pdl.value)
  }
}
pdl.pattern @fmax_swap : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "fmax" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "fmax" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    pdl.replace %1 with (%4 : !pdl.value)
  }
}
pdl.pattern @rem_exp_log : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.log" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @rem_log_exp : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @exp_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.exp" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @exp_1_e : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.exp" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = #herbie<constant E>
    %7 = pdl.operation "herbie.constant" {"symbol" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @_1_exp : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 0.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %2 with (%8 : !pdl.value)
  }
}
pdl.pattern @e_exp_1 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant E>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 1.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %2 with (%8 : !pdl.value)
  }
}
pdl.pattern @exp_fabs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.absf" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @fabs_exp : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.absf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @exp_sum : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%b : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @exp_neg : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.divf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @exp_diff : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%b : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @prod_exp : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.exp" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @rec_exp : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.exp" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @div_exp : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.exp" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @exp_prod : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.powf" (%6, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @exp_sqrt : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.exp" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sqrt" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @exp_cbrt : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.exp" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.cbrt" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @exp_lft_sqr : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.exp" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%9, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %6 with (%13 : !pdl.value)
  }
}
pdl.pattern @exp_lft_cube : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.exp" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 3.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.powf" (%9, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %6 with (%14 : !pdl.value)
  }
}
pdl.pattern @exp_cbrt_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cbrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 3.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%a, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.exp" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @exp_lft_cube_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 3.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 3.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%a, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.exp" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %6 with (%14 : !pdl.value)
  }
}
pdl.pattern @exp_sqrt_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sqrt" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 2.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%a, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.exp" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @exp_lft_sqr_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.mulf" (%a, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.exp" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %5 with (%13 : !pdl.value)
  }
}
pdl.pattern @unpow_1 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = -1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%8, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %4 with (%10 : !pdl.value)
  }
}
pdl.pattern @unpow1 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    pdl.replace %4 with (%a : !pdl.value)
  }
}
pdl.pattern @unpow0 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @pow_base_1 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @unpow1div2 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 5.000000e-01 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @unpow2 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @unpow3 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%7, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %4 with (%9 : !pdl.value)
  }
}
pdl.pattern @unpow1div3 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.33333333333333331 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %4 with (%7 : !pdl.value)
  }
}
pdl.pattern @pow_base_0 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @inv_pow : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = -1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.powf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %4 with (%10 : !pdl.value)
  }
}
pdl.pattern @pow1div2 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sqrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 5.000000e-01 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "math.powf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %1 with (%7 : !pdl.value)
  }
}
pdl.pattern @pow2 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 2.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "math.powf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %1 with (%7 : !pdl.value)
  }
}
pdl.pattern @pow1div3 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cbrt" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 0.33333333333333331 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "math.powf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    pdl.replace %1 with (%7 : !pdl.value)
  }
}
pdl.pattern @pow3 : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 3.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.powf" (%a, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %3 with (%9 : !pdl.value)
  }
}
pdl.pattern @exp_to_pow : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @pow_plus : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%2, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%b, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.powf" (%a, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @pow_exp : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%2, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @pow_prod_down : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %c = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%b, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%c, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.powf" (%8, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @pow_prod_up : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.powf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @pow_flip : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.powf" (%a, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @pow_div : benefit(1) {
  %0 = pdl.type : f64
  %c = pdl.operand : %0
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%a, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%b, %c : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.powf" (%a, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @pow_plus_rev : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%b, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.powf" (%a, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "herbie.sound_pow" (%a, %b, %10 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%12, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %6 with (%14 : !pdl.value)
  }
}
pdl.pattern @pow_neg : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%b : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.powf" (%a, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 0.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "herbie.sound_pow" (%a, %b, %10 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 0.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "herbie.sound_div" (%7, %12, %15 : !pdl.value, !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %3 with (%17 : !pdl.value)
  }
}
pdl.pattern @log_rec : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%3, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.log" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.negf" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @log_E : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant E>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.log" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @log_pow_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %b = pdl.operand : %0
  %1 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.mulf" (%b, %2 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.log" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @log_prod : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.log" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.log" (%10 : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%8, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %3 with (%14 : !pdl.value)
  }
}
pdl.pattern @log_div : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.log" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.absf" (%b : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.log" (%10 : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%8, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %3 with (%14 : !pdl.value)
  }
}
pdl.pattern @log_pow : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.powf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.absf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 0.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "herbie.sound_log" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%b, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %3 with (%13 : !pdl.value)
  }
}
pdl.pattern @sum_log : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.mulf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.log" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @diff_log : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.log" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.divf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.log" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @neg_log : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.log" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.divf" (%7, %a : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.log" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @sin_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @cos_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @tan_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tan" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @sin_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cos_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @cos_fabs : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @tan_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @cos_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.cos" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @cos_fabs_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.cos" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @sin_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sin" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @tan_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.tan" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @sqr_sin_b : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%9, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %5 with (%17 : !pdl.value)
  }
}
pdl.pattern @sqr_cos_b : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%9, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %5 with (%17 : !pdl.value)
  }
}
pdl.pattern @sqr_cos_b_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @sqr_sin_b_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @sin_asin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @cos_acos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @tan_atan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @atan_tan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.atan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.remf" (%x, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %3 with (%9 : !pdl.value)
  }
}
pdl.pattern @asin_sin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.asin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.divf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%x, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.attribute = #herbie<constant PI>
    %19 = pdl.operation "herbie.constant" {"symbol" = %18} -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "arith.mulf" (%17, %20 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "arith.remf" (%14, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "math.absf" (%24 : !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.attribute = #herbie<constant PI>
    %28 = pdl.operation "herbie.constant" {"symbol" = %27} -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.attribute = 2.000000e+00 : f64
    %31 = pdl.operation "arith.constant" {"value" = %30} -> (%0 : !pdl.type)
    %32 = pdl.result 0 of %31
    %33 = pdl.operation "arith.divf" (%29, %32 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %34 = pdl.result 0 of %33
    %35 = pdl.operation "arith.subf" (%26, %34 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %36 = pdl.result 0 of %35
    pdl.replace %3 with (%36 : !pdl.value)
  }
}
pdl.pattern @acos_cos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.acos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 2.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = #herbie<constant PI>
    %9 = pdl.operation "herbie.constant" {"symbol" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.remf" (%x, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.absf" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %3 with (%16 : !pdl.value)
  }
}
pdl.pattern @acos_cos_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = #herbie<constant PI>
  %5 = pdl.operation "herbie.constant" {"symbol" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.mulf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.remf" (%x, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.absf" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.acos" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %11 with (%16 : !pdl.value)
  }
}
pdl.pattern @asin_sin_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%x, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.attribute = 2.000000e+00 : f64
  %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.attribute = #herbie<constant PI>
  %15 = pdl.operation "herbie.constant" {"symbol" = %14} -> (%0 : !pdl.type)
  %16 = pdl.result 0 of %15
  %17 = pdl.operation "arith.mulf" (%13, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  %19 = pdl.operation "arith.remf" (%10, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %20 = pdl.result 0 of %19
  %21 = pdl.operation "math.absf" (%20 : !pdl.value) -> (%0 : !pdl.type)
  %22 = pdl.result 0 of %21
  %23 = pdl.attribute = #herbie<constant PI>
  %24 = pdl.operation "herbie.constant" {"symbol" = %23} -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  %26 = pdl.attribute = 2.000000e+00 : f64
  %27 = pdl.operation "arith.constant" {"value" = %26} -> (%0 : !pdl.type)
  %28 = pdl.result 0 of %27
  %29 = pdl.operation "arith.divf" (%25, %28 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %30 = pdl.result 0 of %29
  %31 = pdl.operation "arith.subf" (%22, %30 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %32 = pdl.result 0 of %31
  pdl.rewrite %31 {
    %33 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %34 = pdl.result 0 of %33
    %35 = pdl.operation "math.asin" (%34 : !pdl.value) -> (%0 : !pdl.type)
    %36 = pdl.result 0 of %35
    pdl.replace %31 with (%36 : !pdl.value)
  }
}
pdl.pattern @cos_sin_sum : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %13 with (%17 : !pdl.value)
  }
}
pdl.pattern @_1_sub_cos : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @_1_sub_sin : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @_1_add_cos : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = -1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.addf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.negf" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %10 with (%19 : !pdl.value)
  }
}
pdl.pattern @_1_add_sin : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = -1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.addf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.negf" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %10 with (%19 : !pdl.value)
  }
}
pdl.pattern @sub_1_cos : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.negf" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %10 with (%19 : !pdl.value)
  }
}
pdl.pattern @sub_1_sin : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.subf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.negf" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %10 with (%19 : !pdl.value)
  }
}
pdl.pattern @sin_PIdiv6 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 6.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 5.000000e-01 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %9 with (%13 : !pdl.value)
  }
}
pdl.pattern @sin_PIdiv4 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 4.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 2.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sqrt" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %9 with (%20 : !pdl.value)
  }
}
pdl.pattern @sin_PIdiv3 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 3.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 3.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sqrt" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %9 with (%20 : !pdl.value)
  }
}
pdl.pattern @sin_PIdiv2 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 1.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %9 with (%13 : !pdl.value)
  }
}
pdl.pattern @sin_PI : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @sin_addPI : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sin" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.negf" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @sin_addPIdiv2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%x, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sin" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %11 with (%14 : !pdl.value)
  }
}
pdl.pattern @cos_PIdiv6 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 6.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 3.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sqrt" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %9 with (%20 : !pdl.value)
  }
}
pdl.pattern @cos_PIdiv4 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 4.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 2.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sqrt" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %9 with (%20 : !pdl.value)
  }
}
pdl.pattern @cos_PIdiv3 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 3.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 5.000000e-01 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %9 with (%13 : !pdl.value)
  }
}
pdl.pattern @cos_PIdiv2 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 0.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %9 with (%13 : !pdl.value)
  }
}
pdl.pattern @cos_PI : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = -1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @cos_addPI : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.negf" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @cos_addPIdiv2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%x, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.cos" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.negf" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %11 with (%16 : !pdl.value)
  }
}
pdl.pattern @tan_PIdiv6 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 6.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.tan" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 1.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.attribute = 3.000000e+00 : f64
    %15 = pdl.operation "arith.constant" {"value" = %14} -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sqrt" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%13, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %9 with (%20 : !pdl.value)
  }
}
pdl.pattern @tan_PIdiv4 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 4.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.tan" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 1.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %9 with (%13 : !pdl.value)
  }
}
pdl.pattern @tan_PIdiv3 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 3.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.tan" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  pdl.rewrite %9 {
    %11 = pdl.attribute = 3.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sqrt" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %9 with (%15 : !pdl.value)
  }
}
pdl.pattern @tan_PI : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tan" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @tan_addPI : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.tan" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %6 with (%9 : !pdl.value)
  }
}
pdl.pattern @hang_0p_tan : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.addf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%2, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%a, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.tan" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @hang_0m_tan : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.attribute = 1.000000e+00 : f64
  %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.addf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "arith.divf" (%4, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "math.tan" (%20 : !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    pdl.replace %12 with (%22 : !pdl.value)
  }
}
pdl.pattern @hang_p0_tan : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%a, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.tan" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @hang_m0_tan : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.negf" (%9 : !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "arith.divf" (%7, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.attribute = 2.000000e+00 : f64
    %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%15, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "math.tan" (%20 : !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    pdl.replace %12 with (%22 : !pdl.value)
  }
}
pdl.pattern @hang_p_tan : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%b : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.divf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.addf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "math.tan" (%21 : !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %13 with (%23 : !pdl.value)
  }
}
pdl.pattern @hang_m_tan : benefit(1) {
  %0 = pdl.type : f64
  %b = pdl.operand : %0
  %a = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%b : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cos" (%b : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.divf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.subf" (%a, %b : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "math.tan" (%21 : !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %13 with (%23 : !pdl.value)
  }
}
pdl.pattern @_1_sub_sin_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%9, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %5 with (%17 : !pdl.value)
  }
}
pdl.pattern @hang_0m_tan_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%a : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 2.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.tan" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.negf" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.attribute = 1.000000e+00 : f64
    %15 = pdl.operation "arith.constant" {"value" = %14} -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.addf" (%16, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "arith.divf" (%13, %20 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    pdl.replace %8 with (%22 : !pdl.value)
  }
}
pdl.pattern @hang_0p_tan_rev : benefit(1) {
  %0 = pdl.type : f64
  %a = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%a, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.tan" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.sin" (%a : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 1.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cos" (%a : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.addf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.divf" (%9, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %6 with (%18 : !pdl.value)
  }
}
pdl.pattern @tan_addPI_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = #herbie<constant PI>
    %4 = pdl.operation "herbie.constant" {"symbol" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "arith.addf" (%x, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.tan" (%7 : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    pdl.replace %1 with (%9 : !pdl.value)
  }
}
pdl.pattern @cos_addPIdiv2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.divf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%x, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.cos" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    pdl.replace %3 with (%16 : !pdl.value)
  }
}
pdl.pattern @sin_addPIdiv2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = #herbie<constant PI>
    %4 = pdl.operation "herbie.constant" {"symbol" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.attribute = 2.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%x, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %1 with (%14 : !pdl.value)
  }
}
pdl.pattern @sin_addPI_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%x, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sin" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @cos_addPI_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%x, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.cos" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @neg_tan_addPIdiv2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = -1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = #herbie<constant PI>
    %9 = pdl.operation "herbie.constant" {"symbol" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.attribute = 2.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.addf" (%x, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.tan" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    pdl.replace %6 with (%19 : !pdl.value)
  }
}
pdl.pattern @tan_addPIdiv2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.divf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = #herbie<constant PI>
    %11 = pdl.operation "herbie.constant" {"symbol" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 2.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.divf" (%12, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.addf" (%9, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.tan" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %6 with (%21 : !pdl.value)
  }
}
pdl.pattern @sin_sum : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.addf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @cos_sum : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.subf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @sin_diff : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.subf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @cos_diff : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.addf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @sin_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sin" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.mulf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %6 with (%18 : !pdl.value)
  }
}
pdl.pattern @sin_3 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sin" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 3.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 4.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.attribute = 3.000000e+00 : f64
    %21 = pdl.operation "arith.constant" {"value" = %20} -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.powf" (%19, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%17, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.subf" (%14, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %6 with (%28 : !pdl.value)
  }
}
pdl.pattern @_2_sin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.mulf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%14, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @_3_sin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 4.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.attribute = 3.000000e+00 : f64
  %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "math.powf" (%12, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.mulf" (%10, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "arith.subf" (%7, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  pdl.rewrite %20 {
    %22 = pdl.attribute = 3.000000e+00 : f64
    %23 = pdl.operation "arith.constant" {"value" = %22} -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%24, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "math.sin" (%26 : !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %20 with (%28 : !pdl.value)
  }
}
pdl.pattern @cos_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%9, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.subf" (%13, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %6 with (%21 : !pdl.value)
  }
}
pdl.pattern @cos_3 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 3.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cos" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 4.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 3.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.powf" (%12, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%10, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.attribute = 3.000000e+00 : f64
    %21 = pdl.operation "arith.constant" {"value" = %20} -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%22, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.subf" (%19, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %6 with (%28 : !pdl.value)
  }
}
pdl.pattern @_2_cos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%17, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.cos" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %13 with (%21 : !pdl.value)
  }
}
pdl.pattern @_3_cos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 4.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 3.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.powf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%3, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.attribute = 3.000000e+00 : f64
  %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "arith.subf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  pdl.rewrite %20 {
    %22 = pdl.attribute = 3.000000e+00 : f64
    %23 = pdl.operation "arith.constant" {"value" = %22} -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.mulf" (%24, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "math.cos" (%26 : !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %20 with (%28 : !pdl.value)
  }
}
pdl.pattern @cos_diff_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cos" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @sin_diff_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @sin_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @tan_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tan" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.tan" (%y : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "arith.subf" (%9, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%6, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  pdl.rewrite %18 {
    %20 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "math.tan" (%21 : !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %18 with (%23 : !pdl.value)
  }
}
pdl.pattern @cos_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cos" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @sqr_sin_a : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 5.000000e-01 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 5.000000e-01 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 2.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%15, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.cos" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.subf" (%9, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %5 with (%23 : !pdl.value)
  }
}
pdl.pattern @sqr_cos_a : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 5.000000e-01 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 5.000000e-01 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.attribute = 2.000000e+00 : f64
    %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.mulf" (%15, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.cos" (%17 : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.addf" (%9, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %5 with (%23 : !pdl.value)
  }
}
pdl.pattern @diff_sin : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.cos" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_cos : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = -2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.sin" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_sin : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sin" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.cos" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_cos : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cos" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.cos" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @cos_mult : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cos" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.addf" (%10, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %5 with (%21 : !pdl.value)
  }
}
pdl.pattern @sin_mult : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.cos" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cos" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.subf" (%10, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %5 with (%21 : !pdl.value)
  }
}
pdl.pattern @sin_cos_mult : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.sin" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sin" (%12 : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.addf" (%10, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %5 with (%21 : !pdl.value)
  }
}
pdl.pattern @diff_atan : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.atan" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.attribute = 1.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.addf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.atan2" (%8, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %5 with (%17 : !pdl.value)
  }
}
pdl.pattern @sum_atan : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.atan" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.attribute = 1.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.subf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.atan2" (%8, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %5 with (%17 : !pdl.value)
  }
}
pdl.pattern @tan_quot : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.divf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %1 with (%8 : !pdl.value)
  }
}
pdl.pattern @quot_tan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.divf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @_2_tan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 1.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.tan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %16 = pdl.result 0 of %15
  %17 = pdl.operation "arith.subf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  %19 = pdl.operation "arith.divf" (%7, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %20 = pdl.result 0 of %19
  pdl.rewrite %19 {
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.mulf" (%23, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.tan" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    pdl.replace %19 with (%27 : !pdl.value)
  }
}
pdl.pattern @diff_cos_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = -2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sin" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.sin" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.subf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_sin_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sin" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.cos" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.subf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_atan_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.addf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "math.atan2" (%2, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.atan" (%y : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.subf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @sum_sin_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sin" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.cos" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.addf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_cos_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.cos" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.cos" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.addf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_atan_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.subf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "math.atan2" (%2, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.atan" (%y : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "arith.addf" (%13, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %10 with (%17 : !pdl.value)
  }
}
pdl.pattern @sqr_cos_a_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 5.000000e-01 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 5.000000e-01 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 2.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.mulf" (%9, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.cos" (%11 : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.mulf" (%6, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "arith.addf" (%3, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  pdl.rewrite %16 {
    %18 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.mulf" (%19, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %16 with (%23 : !pdl.value)
  }
}
pdl.pattern @sqr_sin_a_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 5.000000e-01 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 5.000000e-01 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 2.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.mulf" (%9, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.cos" (%11 : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.mulf" (%6, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "arith.subf" (%3, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  pdl.rewrite %16 {
    %18 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.mulf" (%19, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %16 with (%23 : !pdl.value)
  }
}
pdl.pattern @cos_mult_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%6 : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.attribute = 2.000000e+00 : f64
  %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  pdl.rewrite %14 {
    %16 = pdl.operation "math.cos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%17, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %14 with (%21 : !pdl.value)
  }
}
pdl.pattern @sin_mult_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cos" (%6 : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.subf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.attribute = 2.000000e+00 : f64
  %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  pdl.rewrite %14 {
    %16 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.sin" (%y : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%17, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %14 with (%21 : !pdl.value)
  }
}
pdl.pattern @sin_cos_mult_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sin" (%6 : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.attribute = 2.000000e+00 : f64
  %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  pdl.rewrite %14 {
    %16 = pdl.operation "math.sin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.cos" (%y : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%17, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %14 with (%21 : !pdl.value)
  }
}
pdl.pattern @cos_asin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %3 with (%13 : !pdl.value)
  }
}
pdl.pattern @tan_asin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%x, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @sin_acos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %3 with (%13 : !pdl.value)
  }
}
pdl.pattern @tan_acos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%13, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @sin_atan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%x, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @cos_atan : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.sqrt" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.divf" (%7, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @asin_acos : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = #herbie<constant PI>
    %4 = pdl.operation "herbie.constant" {"symbol" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.attribute = 2.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %1 with (%14 : !pdl.value)
  }
}
pdl.pattern @acos_asin : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = #herbie<constant PI>
    %4 = pdl.operation "herbie.constant" {"symbol" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.attribute = 2.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %1 with (%14 : !pdl.value)
  }
}
pdl.pattern @asin_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.asin" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @acos_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.acos" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = #herbie<constant PI>
    %6 = pdl.operation "herbie.constant" {"symbol" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %3 with (%11 : !pdl.value)
  }
}
pdl.pattern @atan_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.atan" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @acos_asin_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %11 with (%14 : !pdl.value)
  }
}
pdl.pattern @asin_acos_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.divf" (%3, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  pdl.rewrite %11 {
    %13 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    pdl.replace %11 with (%14 : !pdl.value)
  }
}
pdl.pattern @asin_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.asin" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @atan_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.atan" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @acos_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = #herbie<constant PI>
  %2 = pdl.operation "herbie.constant" {"symbol" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.acos" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    pdl.replace %6 with (%11 : !pdl.value)
  }
}
pdl.pattern @cos_atan_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 1.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sqrt" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.divf" (%3, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cos" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @tan_acos_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%9, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.tan" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %10 with (%15 : !pdl.value)
  }
}
pdl.pattern @tan_asin_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.tan" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %10 with (%15 : !pdl.value)
  }
}
pdl.pattern @cos_asin_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "math.asin" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.cos" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %8 with (%13 : !pdl.value)
  }
}
pdl.pattern @sin_atan_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.atan" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sin" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %10 with (%15 : !pdl.value)
  }
}
pdl.pattern @sin_acos_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "math.acos" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sin" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %8 with (%13 : !pdl.value)
  }
}
pdl.pattern @sinh_def : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.attribute = 2.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %1 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_def : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.attribute = 2.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%10, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %1 with (%15 : !pdl.value)
  }
}
pdl.pattern @tanh_def_a : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.exp" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%4, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.exp" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.addf" (%12, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.divf" (%10, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %1 with (%20 : !pdl.value)
  }
}
pdl.pattern @tanh_def_b : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 2.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "arith.mulf" (%5, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "math.exp" (%7 : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 1.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%9, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%17, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.exp" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.attribute = 1.000000e+00 : f64
    %23 = pdl.operation "arith.constant" {"value" = %22} -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.addf" (%21, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.divf" (%14, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %1 with (%28 : !pdl.value)
  }
}
pdl.pattern @tanh_def_c : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 1.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.attribute = -2.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%8, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.exp" (%10 : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%5, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.attribute = -2.000000e+00 : f64
    %19 = pdl.operation "arith.constant" {"value" = %18} -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.operation "arith.mulf" (%20, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %22 = pdl.result 0 of %21
    %23 = pdl.operation "math.exp" (%22 : !pdl.value) -> (%0 : !pdl.type)
    %24 = pdl.result 0 of %23
    %25 = pdl.operation "arith.addf" (%17, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %26 = pdl.result 0 of %25
    %27 = pdl.operation "arith.divf" (%14, %26 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %1 with (%28 : !pdl.value)
  }
}
pdl.pattern @sinh_cosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    pdl.replace %13 with (%17 : !pdl.value)
  }
}
pdl.pattern @sinh_add_cosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %5 with (%8 : !pdl.value)
  }
}
pdl.pattern @sinhsub__cosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "math.exp" (%8 : !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %5 with (%10 : !pdl.value)
  }
}
pdl.pattern @tanh_def_b_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.exp" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 1.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.attribute = 2.000000e+00 : f64
  %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "arith.mulf" (%15, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "math.exp" (%17 : !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.attribute = 1.000000e+00 : f64
  %21 = pdl.operation "arith.constant" {"value" = %20} -> (%0 : !pdl.type)
  %22 = pdl.result 0 of %21
  %23 = pdl.operation "arith.addf" (%19, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %24 = pdl.result 0 of %23
  %25 = pdl.operation "arith.divf" (%12, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %26 = pdl.result 0 of %25
  pdl.rewrite %25 {
    %27 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %25 with (%28 : !pdl.value)
  }
}
pdl.pattern @tanh_def_c_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = -2.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.mulf" (%6, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.exp" (%8 : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.subf" (%3, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.attribute = 1.000000e+00 : f64
  %14 = pdl.operation "arith.constant" {"value" = %13} -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.attribute = -2.000000e+00 : f64
  %17 = pdl.operation "arith.constant" {"value" = %16} -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  %19 = pdl.operation "arith.mulf" (%18, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %20 = pdl.result 0 of %19
  %21 = pdl.operation "math.exp" (%20 : !pdl.value) -> (%0 : !pdl.type)
  %22 = pdl.result 0 of %21
  %23 = pdl.operation "arith.addf" (%15, %22 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %24 = pdl.result 0 of %23
  %25 = pdl.operation "arith.divf" (%12, %24 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %26 = pdl.result 0 of %25
  pdl.rewrite %25 {
    %27 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %28 = pdl.result 0 of %27
    pdl.replace %25 with (%28 : !pdl.value)
  }
}
pdl.pattern @sinh_def_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.subf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.attribute = 2.000000e+00 : f64
  %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "arith.divf" (%8, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %12 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_def_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.addf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.attribute = 2.000000e+00 : f64
  %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "arith.divf" (%8, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %12 with (%15 : !pdl.value)
  }
}
pdl.pattern @sinh_add_cosh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.addf" (%4, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %1 with (%8 : !pdl.value)
  }
}
pdl.pattern @sinhsub__cosh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.exp" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.subf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    pdl.replace %3 with (%10 : !pdl.value)
  }
}
pdl.pattern @sinh_undef : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.subf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  pdl.rewrite %7 {
    %9 = pdl.attribute = 2.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %7 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_undef : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.addf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  pdl.rewrite %7 {
    %9 = pdl.attribute = 2.000000e+00 : f64
    %10 = pdl.operation "arith.constant" {"value" = %9} -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %7 with (%15 : !pdl.value)
  }
}
pdl.pattern @tanh_undef : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "math.exp" (%4 : !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.subf" (%2, %6 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.exp" (%12 : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.operation "arith.addf" (%10, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %16 = pdl.result 0 of %15
  %17 = pdl.operation "arith.divf" (%8, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  pdl.rewrite %17 {
    %19 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    pdl.replace %17 with (%20 : !pdl.value)
  }
}
pdl.pattern @cosh_sum : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.addf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @cosh_diff : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.subf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @cosh_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cosh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.mulf" (%9, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.addf" (%13, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %6 with (%21 : !pdl.value)
  }
}
pdl.pattern @cosh_1div2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cosh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 1.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.addf" (%9, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.sqrt" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %6 with (%21 : !pdl.value)
  }
}
pdl.pattern @sinh_sum : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.addf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @sinh_diff : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.mulf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.subf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @sinh_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sinh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.mulf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %6 with (%18 : !pdl.value)
  }
}
pdl.pattern @sinh_1div2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.sinh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.attribute = 2.000000e+00 : f64
    %11 = pdl.operation "arith.constant" {"value" = %10} -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.addf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.mulf" (%12, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "math.sqrt" (%21 : !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%9, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    pdl.replace %6 with (%25 : !pdl.value)
  }
}
pdl.pattern @tanh_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.tanh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.mulf" (%19, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.addf" (%17, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "arith.divf" (%14, %25 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    pdl.replace %6 with (%27 : !pdl.value)
  }
}
pdl.pattern @tanh_1div2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.divf" (%x, %3 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.tanh" (%5 : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 1.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.addf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.divf" (%9, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %6 with (%18 : !pdl.value)
  }
}
pdl.pattern @sum_sinh : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sinh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.cosh" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_cosh : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cosh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.cosh" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_sinh : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cosh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.sinh" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_cosh : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.subf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  pdl.rewrite %5 {
    %7 = pdl.attribute = 2.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%11, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sinh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    %19 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %20 = pdl.result 0 of %19
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.divf" (%20, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.sinh" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "arith.mulf" (%18, %27 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.mulf" (%9, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %5 with (%31 : !pdl.value)
  }
}
pdl.pattern @tanh_sum : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tanh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.tanh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    %9 = pdl.operation "arith.addf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.attribute = 1.000000e+00 : f64
    %12 = pdl.operation "arith.constant" {"value" = %11} -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    %16 = pdl.operation "math.tanh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%15, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.addf" (%13, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.divf" (%10, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %3 with (%23 : !pdl.value)
  }
}
pdl.pattern @sinh_undef_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.exp" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.subf" (%9, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %6 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_undef_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.operation "math.exp" (%x : !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.exp" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.addf" (%9, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %6 with (%15 : !pdl.value)
  }
}
pdl.pattern @diff_cosh_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sinh" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.sinh" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.subf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @diff_sinh_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.cosh" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.sinh" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.subf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @cosh_diff_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cosh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @sinh_diff_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sinh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @tanh_1div2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.attribute = 1.000000e+00 : f64
  %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.addf" (%4, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%2, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%x, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.tanh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @tanh_1div2mul_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.divf" (%x, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.tanh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @tanh_2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 1.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.operation "arith.mulf" (%12, %14 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %16 = pdl.result 0 of %15
  %17 = pdl.operation "arith.addf" (%10, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  %19 = pdl.operation "arith.divf" (%7, %18 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %20 = pdl.result 0 of %19
  pdl.rewrite %19 {
    %21 = pdl.attribute = 2.000000e+00 : f64
    %22 = pdl.operation "arith.constant" {"value" = %21} -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "arith.mulf" (%23, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    %26 = pdl.operation "math.tanh" (%25 : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    pdl.replace %19 with (%27 : !pdl.value)
  }
}
pdl.pattern @sinh_1div2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 2.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 1.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.mulf" (%5, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.operation "math.sqrt" (%14 : !pdl.value) -> (%0 : !pdl.type)
  %16 = pdl.result 0 of %15
  %17 = pdl.operation "arith.divf" (%2, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %18 = pdl.result 0 of %17
  pdl.rewrite %17 {
    %19 = pdl.attribute = 2.000000e+00 : f64
    %20 = pdl.operation "arith.constant" {"value" = %19} -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.divf" (%x, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    %24 = pdl.operation "math.sinh" (%23 : !pdl.value) -> (%0 : !pdl.type)
    %25 = pdl.result 0 of %24
    pdl.replace %17 with (%25 : !pdl.value)
  }
}
pdl.pattern @cosh_1div2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 2.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.divf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.sqrt" (%12 : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.divf" (%x, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.cosh" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %13 with (%21 : !pdl.value)
  }
}
pdl.pattern @sinh_2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "arith.mulf" (%5, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.mulf" (%3, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.attribute = 2.000000e+00 : f64
    %13 = pdl.operation "arith.constant" {"value" = %12} -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "arith.mulf" (%14, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sinh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %10 with (%18 : !pdl.value)
  }
}
pdl.pattern @cosh_2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.mulf" (%17, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.cosh" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %13 with (%21 : !pdl.value)
  }
}
pdl.pattern @sinh_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.sinh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @tanh_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tanh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.addf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.attribute = 1.000000e+00 : f64
  %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "math.tanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.tanh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  %14 = pdl.operation "arith.mulf" (%11, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %15 = pdl.result 0 of %14
  %16 = pdl.operation "arith.addf" (%9, %15 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%6, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  pdl.rewrite %18 {
    %20 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "math.tanh" (%21 : !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %18 with (%23 : !pdl.value)
  }
}
pdl.pattern @cosh_sum_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  %5 = pdl.operation "arith.mulf" (%2, %4 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.mulf" (%8, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.addf" (%6, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cosh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @sum_cosh_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.cosh" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.cosh" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.cosh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.addf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @sum_sinh_rev : benefit(1) {
  %0 = pdl.type : f64
  %y = pdl.operand : %0
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 2.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.divf" (%5, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sinh" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.subf" (%x, %y : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  %20 = pdl.operation "math.cosh" (%19 : !pdl.value) -> (%0 : !pdl.type)
  %21 = pdl.result 0 of %20
  %22 = pdl.operation "arith.mulf" (%12, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %23 = pdl.result 0 of %22
  %24 = pdl.operation "arith.mulf" (%3, %23 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %25 = pdl.result 0 of %24
  pdl.rewrite %24 {
    %26 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %27 = pdl.result 0 of %26
    %28 = pdl.operation "math.sinh" (%y : !pdl.value) -> (%0 : !pdl.type)
    %29 = pdl.result 0 of %28
    %30 = pdl.operation "arith.addf" (%27, %29 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %31 = pdl.result 0 of %30
    pdl.replace %24 with (%31 : !pdl.value)
  }
}
pdl.pattern @sinh_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "arith.negf" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @sinh_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.sinh" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 0.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @sinh_0_rev : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 0.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sinh" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %2 with (%8 : !pdl.value)
  }
}
pdl.pattern @cosh_neg : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %3 with (%6 : !pdl.value)
  }
}
pdl.pattern @cosh_0 : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 0.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.cosh" (%3 : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  pdl.rewrite %4 {
    %6 = pdl.attribute = 1.000000e+00 : f64
    %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %4 with (%8 : !pdl.value)
  }
}
pdl.pattern @cosh_0_rev : benefit(1) {
  %0 = pdl.type : f64
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  pdl.rewrite %2 {
    %4 = pdl.attribute = 0.000000e+00 : f64
    %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.cosh" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %2 with (%8 : !pdl.value)
  }
}
pdl.pattern @cosh_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.cosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.operation "math.cosh" (%4 : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    pdl.replace %1 with (%6 : !pdl.value)
  }
}
pdl.pattern @sinh_neg_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.sinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "arith.negf" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.negf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.operation "math.sinh" (%6 : !pdl.value) -> (%0 : !pdl.type)
    %8 = pdl.result 0 of %7
    pdl.replace %3 with (%8 : !pdl.value)
  }
}
pdl.pattern @asinh_def : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.addf" (%4, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sqrt" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.addf" (%x, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.log" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %1 with (%15 : !pdl.value)
  }
}
pdl.pattern @acosh_def : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %4 = pdl.result 0 of %3
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.subf" (%4, %7 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "math.sqrt" (%9 : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "arith.addf" (%x, %11 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.log" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %1 with (%15 : !pdl.value)
  }
}
pdl.pattern @atanh_def : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  pdl.rewrite %1 {
    %3 = pdl.attribute = 1.000000e+00 : f64
    %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
    %5 = pdl.result 0 of %4
    %6 = pdl.operation "arith.addf" (%5, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.subf" (%10, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.divf" (%7, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.log" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.attribute = 2.000000e+00 : f64
    %18 = pdl.operation "arith.constant" {"value" = %17} -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "arith.divf" (%16, %19 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %1 with (%21 : !pdl.value)
  }
}
pdl.pattern @sinh_asinh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @sinh_acosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %3 with (%13 : !pdl.value)
  }
}
pdl.pattern @sinh_atanh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.sinh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%x, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_asinh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %3 with (%13 : !pdl.value)
  }
}
pdl.pattern @cosh_acosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @cosh_atanh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.cosh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.attribute = 1.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.subf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.operation "math.sqrt" (%14 : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "arith.divf" (%7, %16 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %3 with (%18 : !pdl.value)
  }
}
pdl.pattern @tanh_asinh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tanh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.attribute = 1.000000e+00 : f64
    %6 = pdl.operation "arith.constant" {"value" = %5} -> (%0 : !pdl.type)
    %7 = pdl.result 0 of %6
    %8 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.addf" (%7, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%x, %13 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @tanh_acosh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tanh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    %5 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %6 = pdl.result 0 of %5
    %7 = pdl.attribute = 1.000000e+00 : f64
    %8 = pdl.operation "arith.constant" {"value" = %7} -> (%0 : !pdl.type)
    %9 = pdl.result 0 of %8
    %10 = pdl.operation "arith.subf" (%6, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.sqrt" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "arith.divf" (%13, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %3 with (%15 : !pdl.value)
  }
}
pdl.pattern @tanh_atanh : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.operation "math.tanh" (%2 : !pdl.value) -> (%0 : !pdl.type)
  %4 = pdl.result 0 of %3
  pdl.rewrite %3 {
    pdl.replace %3 with (%x : !pdl.value)
  }
}
pdl.pattern @asinh_def_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.addf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.log" (%11 : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %12 with (%15 : !pdl.value)
  }
}
pdl.pattern @atanh_def_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.addf" (%3, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.attribute = 1.000000e+00 : f64
  %7 = pdl.operation "arith.constant" {"value" = %6} -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.subf" (%8, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.divf" (%5, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.log" (%12 : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  %15 = pdl.attribute = 2.000000e+00 : f64
  %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
  %17 = pdl.result 0 of %16
  %18 = pdl.operation "arith.divf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %19 = pdl.result 0 of %18
  pdl.rewrite %18 {
    %20 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %18 with (%21 : !pdl.value)
  }
}
pdl.pattern @acosh_def_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.addf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  %12 = pdl.operation "math.log" (%11 : !pdl.value) -> (%0 : !pdl.type)
  %13 = pdl.result 0 of %12
  pdl.rewrite %12 {
    %14 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %12 with (%15 : !pdl.value)
  }
}
pdl.pattern @tanh_asinh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.tanh" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %10 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_asinh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %2 = pdl.result 0 of %1
  %3 = pdl.attribute = 1.000000e+00 : f64
  %4 = pdl.operation "arith.constant" {"value" = %3} -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.addf" (%2, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  pdl.rewrite %8 {
    %10 = pdl.operation "math.asinh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %11 = pdl.result 0 of %10
    %12 = pdl.operation "math.cosh" (%11 : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    pdl.replace %8 with (%13 : !pdl.value)
  }
}
pdl.pattern @sinh_atanh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.subf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.operation "math.sqrt" (%7 : !pdl.value) -> (%0 : !pdl.type)
  %9 = pdl.result 0 of %8
  %10 = pdl.operation "arith.divf" (%x, %9 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %11 = pdl.result 0 of %10
  pdl.rewrite %10 {
    %12 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %13 = pdl.result 0 of %12
    %14 = pdl.operation "math.sinh" (%13 : !pdl.value) -> (%0 : !pdl.type)
    %15 = pdl.result 0 of %14
    pdl.replace %10 with (%15 : !pdl.value)
  }
}
pdl.pattern @cosh_atanh_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 1.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.attribute = 1.000000e+00 : f64
  %5 = pdl.operation "arith.constant" {"value" = %4} -> (%0 : !pdl.type)
  %6 = pdl.result 0 of %5
  %7 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %8 = pdl.result 0 of %7
  %9 = pdl.operation "arith.subf" (%6, %8 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "math.sqrt" (%10 : !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "arith.divf" (%3, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.operation "math.atanh" (%x : !pdl.value) -> (%0 : !pdl.type)
    %16 = pdl.result 0 of %15
    %17 = pdl.operation "math.cosh" (%16 : !pdl.value) -> (%0 : !pdl.type)
    %18 = pdl.result 0 of %17
    pdl.replace %13 with (%18 : !pdl.value)
  }
}
pdl.pattern @asinh_2 : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  %8 = pdl.attribute = 1.000000e+00 : f64
  %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
  %10 = pdl.result 0 of %9
  %11 = pdl.operation "arith.addf" (%7, %10 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %12 = pdl.result 0 of %11
  %13 = pdl.operation "math.acosh" (%12 : !pdl.value) -> (%0 : !pdl.type)
  %14 = pdl.result 0 of %13
  pdl.rewrite %13 {
    %15 = pdl.attribute = 2.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "math.absf" (%x : !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.asinh" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    %22 = pdl.operation "arith.mulf" (%17, %21 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %23 = pdl.result 0 of %22
    pdl.replace %13 with (%23 : !pdl.value)
  }
}
pdl.pattern @acosh_2_rev : benefit(1) {
  %0 = pdl.type : f64
  %x = pdl.operand : %0
  %1 = pdl.attribute = 2.000000e+00 : f64
  %2 = pdl.operation "arith.constant" {"value" = %1} -> (%0 : !pdl.type)
  %3 = pdl.result 0 of %2
  %4 = pdl.operation "math.acosh" (%x : !pdl.value) -> (%0 : !pdl.type)
  %5 = pdl.result 0 of %4
  %6 = pdl.operation "arith.mulf" (%3, %5 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
  %7 = pdl.result 0 of %6
  pdl.rewrite %6 {
    %8 = pdl.attribute = 2.000000e+00 : f64
    %9 = pdl.operation "arith.constant" {"value" = %8} -> (%0 : !pdl.type)
    %10 = pdl.result 0 of %9
    %11 = pdl.operation "arith.mulf" (%x, %x : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %12 = pdl.result 0 of %11
    %13 = pdl.operation "arith.mulf" (%10, %12 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %14 = pdl.result 0 of %13
    %15 = pdl.attribute = 1.000000e+00 : f64
    %16 = pdl.operation "arith.constant" {"value" = %15} -> (%0 : !pdl.type)
    %17 = pdl.result 0 of %16
    %18 = pdl.operation "arith.subf" (%14, %17 : !pdl.value, !pdl.value) -> (%0 : !pdl.type)
    %19 = pdl.result 0 of %18
    %20 = pdl.operation "math.acosh" (%19 : !pdl.value) -> (%0 : !pdl.type)
    %21 = pdl.result 0 of %20
    pdl.replace %6 with (%21 : !pdl.value)
  }
}
