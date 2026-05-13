module @ir {
func.func @nested_for_yield(%arg0 : index, %arg1 : index, %arg2 : index) -> f32 {
  %step = arith.constant 2 : index
  %s0 = arith.constant 1.0 : f32
  %r = scf.for %i0 = %arg0 to %arg1 step %step iter_args(%iter = %s0) -> (f32) {
    %result = scf.for %i1 = %arg0 to %arg1 step %step iter_args(%si = %iter) -> (f32) {
      %sn = arith.addf %si, %si : f32
      scf.yield %sn : f32
    }
    scf.yield %result : f32
  }
  return %r : f32
}
}

module @patterns {}
