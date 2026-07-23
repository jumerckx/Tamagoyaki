// High-level `pdl` source for the negation rewrites on `llvm` arithmetic.
// This is the authoring format; it is lowered to the e-match-aware
// `pdl_interp` in patterns.mlir with:
//
//   uv run --with=xdsl xdsl-opt \
//     -p 'convert-pdl-to-pdl-interp{optimize_for_eqsat=true}' \
//     patterns.pdl.mlir -o patterns.mlir
//
// Negation is expressed as `0 - x` (`llvm.sub` against an `llvm.mlir.constant`
// of 0), matching how the front-end emits unary minus.

// RUN: true

// -a - -b  ->  b - a
pdl.pattern @neg_sub_neg : benefit(1) {
  %type = pdl.type
  %a = pdl.operand
  %b = pdl.operand

  %zero_attr = pdl.attribute = 0 : i32
  %zero_a_op = pdl.operation "llvm.mlir.constant" {"value" = %zero_attr} -> (%type : !pdl.type)
  %zero_a = pdl.result 0 of %zero_a_op
  %zero_b_op = pdl.operation "llvm.mlir.constant" {"value" = %zero_attr} -> (%type : !pdl.type)
  %zero_b = pdl.result 0 of %zero_b_op

  %neg_a_op = pdl.operation "llvm.sub" (%zero_a, %a : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %neg_a = pdl.result 0 of %neg_a_op
  %neg_b_op = pdl.operation "llvm.sub" (%zero_b, %b : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %neg_b = pdl.result 0 of %neg_b_op

  %root = pdl.operation "llvm.sub" (%neg_a, %neg_b : !pdl.value, !pdl.value) -> (%type : !pdl.type)

  pdl.rewrite %root {
    // b - a
    %new_op = pdl.operation "llvm.sub" (%b, %a : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %new = pdl.result 0 of %new_op
    pdl.replace %root with (%new : !pdl.value)
  }
}

// -a + -b  ->  -(a - b)
pdl.pattern @neg_add_neg : benefit(1) {
  %type = pdl.type
  %a = pdl.operand
  %b = pdl.operand

  %zero_attr = pdl.attribute = 0 : i32
  %zero_a_op = pdl.operation "llvm.mlir.constant" {"value" = %zero_attr} -> (%type : !pdl.type)
  %zero_a = pdl.result 0 of %zero_a_op
  %zero_b_op = pdl.operation "llvm.mlir.constant" {"value" = %zero_attr} -> (%type : !pdl.type)
  %zero_b = pdl.result 0 of %zero_b_op

  %neg_a_op = pdl.operation "llvm.sub" (%zero_a, %a : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %neg_a = pdl.result 0 of %neg_a_op
  %neg_b_op = pdl.operation "llvm.sub" (%zero_b, %b : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %neg_b = pdl.result 0 of %neg_b_op

  %root = pdl.operation "llvm.add" (%neg_a, %neg_b : !pdl.value, !pdl.value) -> (%type : !pdl.type)

  pdl.rewrite %root {
    // -(a - b)  ==  0 - (a - b)
    %sub_op = pdl.operation "llvm.sub" (%a, %b : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %sub = pdl.result 0 of %sub_op
    %zero_r_op = pdl.operation "llvm.mlir.constant" {"value" = %zero_attr} -> (%type : !pdl.type)
    %zero_r = pdl.result 0 of %zero_r_op
    %new_op = pdl.operation "llvm.sub" (%zero_r, %sub : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %new = pdl.result 0 of %new_op
    pdl.replace %root with (%new : !pdl.value)
  }
}
