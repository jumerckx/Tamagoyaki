// RUN: true

// sin(x)^2 + cos(x)^2 -> 1
pdl.pattern @sin_cos_squared : benefit(1) {
  %type = pdl.type : f32
  %x = pdl.operand : %type
  %sin_op = pdl.operation "math.sin"(%x : !pdl.value) -> (%type : !pdl.type)
  %sin = pdl.result 0 of %sin_op
  %sin_sq_op = pdl.operation "arith.mulf"(%sin, %sin : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %sin_sq = pdl.result 0 of %sin_sq_op
  %cos_op = pdl.operation "math.cos"(%x : !pdl.value) -> (%type : !pdl.type)
  %cos = pdl.result 0 of %cos_op
  %cos_sq_op = pdl.operation "arith.mulf"(%cos, %cos : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  %cos_sq = pdl.result 0 of %cos_sq_op
  %sum = pdl.operation "arith.addf"(%sin_sq, %cos_sq : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  pdl.rewrite %sum {
    %one_attr = pdl.attribute = 1.0 : f32
    %one = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
    pdl.replace %sum with %one
  }
}
