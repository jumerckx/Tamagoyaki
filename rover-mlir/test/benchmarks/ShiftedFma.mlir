// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  hw.module @ShiftedFma(in %a : i32, in %b : i32, in %s : i5, in %c : i64, out result : i65) {
    %g = equivalence.graph -> (i65) {
      %false = hw.constant false
      %c0_i60 = hw.constant 0 : i60
      %c0_i33 = hw.constant 0 : i33
      %0 = comb.concat %c0_i33, %a : i33, i32
      %1 = comb.concat %c0_i33, %b : i33, i32
      %2 = comb.mul %0, %1 {sv.namehint = "d"} : i65
      %3 = comb.concat %c0_i60, %s : i60, i5
      %4 = comb.shl %2, %3 {sv.namehint = "e"} : i65
      %5 = comb.concat %false, %c : i1, i64
      %6 = comb.add %4, %5 : i65
      equivalence.yield %6 : i65
    }
    hw.output %g : i65
  }
}

// CHECK-LABEL: hw.module @ShiftedFma
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i65
