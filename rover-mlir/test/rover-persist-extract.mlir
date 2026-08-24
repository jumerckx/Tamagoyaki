// The evaluation's "multi-persist" configuration runs CIRCT passes over a
// persisted e-graph before extracting from it. --canonicalize hoists
// hw.constant out of the equivalence.graph region, so extraction must cost
// operands defined outside the graph as free leaves (like block arguments)
// rather than as unresolved. Getting that wrong stalls the cost fixpoint and
// silently leaves equivalence.class ops in the extracted hw.module, which then
// fails to synthesize.

// RUN: rover-mlir-opt --rover-insert-graph %s \
// RUN:   --rover-saturate="patterns-file=%S/../rules/rewrites_pdl_interp.mlir max-iters=4" \
// RUN: | rover-mlir-opt --canonicalize --comb-int-range-narrowing \
// RUN: | rover-mlir-opt --rover-extract=delay --remove-dead-values \
// RUN: | FileCheck %s

module @ir {
  hw.module @MulSel(in %a : i32, in %b : i32, in %c : i32, in %s : i1, out result : i64) {
    %c0_i32 = hw.constant 0 : i32
    %0 = comb.concat %c0_i32, %a : i32, i32
    %1 = comb.concat %c0_i32, %b : i32, i32
    %2 = comb.mul %0, %1 : i64
    %3 = comb.concat %c0_i32, %c : i32, i32
    %4 = comb.mul %0, %3 : i64
    %5 = comb.mux %s, %2, %4 : i64
    hw.output %5 : i64
  }
}

// The e-graph must be fully resolved: no classes may survive extraction.
// CHECK-NOT: equivalence.class
// CHECK-NOT: equivalence.graph

// CHECK-LABEL: hw.module @MulSel
// CHECK-NOT: comb.mul
// CHECK-DAG: datapath.partial_product
// CHECK-DAG: datapath.compress
// CHECK: comb.add
// CHECK: hw.output %{{.*}} : i64
