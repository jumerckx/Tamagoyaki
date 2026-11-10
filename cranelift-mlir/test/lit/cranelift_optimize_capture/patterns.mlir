// RUN: true

// select c, x, x -> x
pdl.pattern @select_same : benefit(1) {
  %type = pdl.type
  %c = pdl.operand
  %x = pdl.operand
  %sel = pdl.operation "arith.select"(%c, %x, %x : !pdl.value, !pdl.value, !pdl.value) -> (%type : !pdl.type)
  pdl.rewrite %sel {
    pdl.replace %sel with (%x : !pdl.value)
  }
}
