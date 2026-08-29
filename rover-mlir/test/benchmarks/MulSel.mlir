// Unlike its neighbours, this design is test-only: it is not part of the
// evaluation corpus, so its input lives in Inputs/ rather than in
// rover-mlir/eval/benchmarks. The pipeline exercised is the same one the
// evaluation runs -- the e-graph comes from --rover-insert-graph rather than
// being baked into the source.
//
// RUN: rover-mlir-opt --rover-insert-graph %S/Inputs/MulSel.mlir \
// RUN:   --rover-saturate="patterns-file=%S/../../rules/rewrites_pdl_interp.mlir max-iters=4" \
// RUN:   --rover-extract=delay --remove-dead-values | FileCheck %s

// CHECK-LABEL: hw.module @MulSel
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i64
