// RUN: rover-mlir-opt --rover-saturate="patterns-file=%S/../rewrites_pdl_interp.mlir max-iters=4" %s --rover-extract=delay --remove-dead-values | FileCheck %s

module @ir {
  func.func @FirFilter(%z1 : i32, %z2 : i32, %z3 : i32, %z4 : i32, %add0 : i32, %s : i5) -> i32 {
    %c0_i27 = hw.constant 0 : i27
    %0 = comb.add %add0, %z1 : i32
    %1 = comb.concat %c0_i27, %s : i27, i5
    %2 = comb.shru %0, %1 {sv.namehint = "add1"} : i32
    %3 = comb.add %2, %z2 : i32
    %4 = comb.shru %3, %1 {sv.namehint = "add2"} : i32
    %5 = comb.add %4, %z3 : i32
    %6 = comb.shru %5, %1 {sv.namehint = "add3"} : i32
    %7 = comb.add %6, %z4 {sv.namehint = "add4"} : i32
    func.return %7 : i32
  }
}

// CHECK-LABEL: func.func @FirFilter
// CHECK-NOT: comb.mul
// CHECK: comb.add
// CHECK: return %{{.*}} : i32
