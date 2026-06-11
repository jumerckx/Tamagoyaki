// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  hw.module @MulSel(in %a : i32, in %b : i32, in %c : i32, in %s : i1, out result : i64) {
    %g = equivalence.graph -> (i64) {
      %c0_i32 = hw.constant 0 : i32
      %0 = comb.concat %c0_i32, %a : i32, i32
      %1 = comb.concat %c0_i32, %b : i32, i32
      %2 = comb.mul %0, %1 : i64
      %3 = comb.concat %c0_i32, %c : i32, i32
      %4 = comb.mul %0, %3 : i64
      %5 = comb.mux %s, %2, %4 : i64
      equivalence.yield %5 : i64
    }
    hw.output %g : i64
  }
}

// CHECK-LABEL: hw.module @MulSel
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i64
