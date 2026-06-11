// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  hw.module @FirFilter(in %z1 : i32, in %z2 : i32, in %z3 : i32, in %z4 : i32, in %add0 : i32, in %s : i5, out result : i32) {
    %g = equivalence.graph -> (i32) {
      %c0_i27 = hw.constant 0 : i27
      %0 = comb.add %add0, %z1 : i32
      %1 = comb.concat %c0_i27, %s : i27, i5
      %2 = comb.shru %0, %1 {sv.namehint = "add1"} : i32
      %3 = comb.add %2, %z2 : i32
      %4 = comb.shru %3, %1 {sv.namehint = "add2"} : i32
      %5 = comb.add %4, %z3 : i32
      %6 = comb.shru %5, %1 {sv.namehint = "add3"} : i32
      %7 = comb.add %6, %z4 {sv.namehint = "add4"} : i32
      equivalence.yield %7 : i32
    }
    hw.output %g : i32
  }
}

// CHECK-LABEL: hw.module @FirFilter
// CHECK-NOT: comb.mul
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i32
