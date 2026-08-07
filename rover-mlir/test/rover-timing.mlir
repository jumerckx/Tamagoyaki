// The evaluation reads per-benchmark saturation wall clock out of this JSON
// (rover-mlir/eval/Snakefile, stage 05-timing), so a refactor that drops the
// timing registration from rover-mlir-opt would silently zero every reported
// runtime. Guard both the flag and the scope name.

// RUN: rover-mlir-opt --rover-insert-graph %s \
// RUN:   --rover-saturate="patterns-file=%S/../rules/rewrites_pdl_interp.mlir max-iters=2" \
// RUN:   -tamagoyaki-timing -tamagoyaki-timing-output=json 2>&1 >/dev/null \
// RUN: | FileCheck %s

module @ir {
  hw.module @Timing(in %a : i32, in %b : i32, in %s : i5, out result : i64) {
    %c0_i32 = hw.constant 0 : i32
    %c0_i59 = hw.constant 0 : i59
    %0 = comb.concat %c0_i32, %a : i32, i32
    %1 = comb.concat %c0_i32, %b : i32, i32
    %2 = comb.mul %0, %1 : i64
    %3 = comb.concat %c0_i59, %s : i59, i5
    %4 = comb.shl %2, %3 : i64
    hw.output %4 : i64
  }
}

// CHECK: "wall"
// CHECK: "name": "runSaturation"
