// RUN: true

// Patterns for ir.mlir: rewrites `x * 2` into `x << 1`.

pdl.pattern @mul_to_shift : benefit(1) {
  %type = pdl.type : i32
  %x = pdl.operand : %type
  %two_attr = pdl.attribute = 2 : i32
  %two_op = pdl.operation "arith.constant" {"value" = %two_attr} -> (%type : !pdl.type)
  %two = pdl.result 0 of %two_op
  %mul = pdl.operation "arith.muli"(%x, %two : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  pdl.rewrite %mul {
    %one_attr = pdl.attribute = 1 : i32
    %one_op = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
    %one = pdl.result 0 of %one_op
    %shl = pdl.operation "arith.shli"(%x, %one : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    pdl.replace %mul with %shl
  }
}
