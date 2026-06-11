// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  hw.module @ShiftMult(in %a : i32, in %b : i32, in %m : i5, in %n : i5, out result : i64) {
    %g = equivalence.graph -> (i64) {
      %c0_i59 = hw.constant 0 : i59
      %c0_i32 = hw.constant 0 : i32
      %0 = comb.concat %c0_i32, %a : i32, i32
      %1 = comb.concat %c0_i59, %m : i59, i5
      %2 = comb.shl %0, %1 {sv.namehint = "d"} : i64
      %3 = comb.concat %c0_i32, %b : i32, i32
      %4 = comb.concat %c0_i59, %n : i59, i5
      %5 = comb.shl %3, %4 {sv.namehint = "e"} : i64
      %6 = comb.mul %2, %5 : i64
      equivalence.yield %6 : i64
    }
    hw.output %g : i64
  }
}

// CHECK-LABEL: hw.module @ShiftMult
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i64
