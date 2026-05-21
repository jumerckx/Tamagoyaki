// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  func.func @MulSel(%a : i32, %b : i32, %c : i32, %s : i1) -> i64 {
    %c0_i32 = hw.constant 0 : i32
    %0 = comb.concat %c0_i32, %a : i32, i32
    %1 = comb.concat %c0_i32, %b : i32, i32
    %2 = comb.mul %0, %1 : i64
    %3 = comb.concat %c0_i32, %c : i32, i32
    %4 = comb.mul %0, %3 : i64
    %5 = comb.mux %s, %2, %4 : i64
    func.return %5 : i64
  }
}

// CHECK-LABEL: func.func @MulSel
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: return %{{.*}} : i64
