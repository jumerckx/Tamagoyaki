module @ir {
func.func @nested_for_unstructured(%lo: index, %hi: index, %threshold: f32) -> f32 {
  %step = arith.constant 1 : index
  %init = arith.constant 0.0 : f32
  %r = scf.for %i = %lo to %hi step %step iter_args(%acc_i = %init) -> (f32) {
    %inner = scf.for %j = %lo to %hi step %step iter_args(%acc_j = %acc_i) -> (f32) {
      // scf.for requires a single-block region, so the unstructured
      // CFG lives inside an scf.execute_region.
      %updated = scf.execute_region -> f32 {
        %ii = arith.index_cast %i : index to i32
        %jj = arith.index_cast %j : index to i32
        %iif = arith.sitofp %ii : i32 to f32
        %jjf = arith.sitofp %jj : i32 to f32
        %prod = arith.mulf %iif, %jjf : f32
        %cond = arith.cmpf ogt, %prod, %threshold : f32
        cf.cond_br %cond, ^big, ^small
      ^big:
        %s = math.sin %prod : f32
        %a1 = arith.addf %acc_j, %s : f32
        cf.br ^join(%a1 : f32)
      ^small:
        %c = math.cos %prod : f32
        %a2 = arith.addf %acc_j, %c : f32
        cf.br ^join(%a2 : f32)
      ^join(%v : f32):
        scf.yield %v : f32
      }
      scf.yield %updated : f32
    }
    scf.yield %inner : f32
  }
  return %r : f32
}
}

module @patterns {}
