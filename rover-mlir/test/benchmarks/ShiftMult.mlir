// The evaluation drives these designs too (`nix run .#rover-eval`), so the test
// reads the same plain hw.module input and runs the same pipeline: the e-graph
// comes from --rover-insert-graph rather than being baked into the source.
//
// RUN: rover-mlir-opt --rover-insert-graph %S/../../eval/benchmarks/ShiftMult.mlir \
// RUN:   --rover-saturate="patterns-file=%S/../../rules/rewrites_pdl_interp.mlir max-iters=4" \
// RUN:   --rover-extract=delay --remove-dead-values | FileCheck %s

// CHECK-LABEL: hw.module @ShiftMult
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i64
