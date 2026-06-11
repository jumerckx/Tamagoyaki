// RUN: rover-mlir-opt -rover-insert-graph %s | FileCheck %s

// CHECK-LABEL: hw.module @adder
hw.module @adder(in %a : i8, in %b : i8, out c : i8) {
  // CHECK: %[[G:.+]] = equivalence.graph -> (i8) {
  // CHECK:   %[[ADD:.+]] = comb.add %a, %b : i8
  // CHECK:   equivalence.yield %[[ADD]] : i8
  // CHECK: }
  // CHECK: hw.output %[[G]] : i8
  %0 = comb.add %a, %b : i8
  hw.output %0 : i8
}

// CHECK-LABEL: hw.module @two
hw.module @two(in %a : i8, in %b : i8, out x : i8, out y : i8) {
  // CHECK: %[[G:.+]]:2 = equivalence.graph -> (i8, i8) {
  // CHECK:   equivalence.yield {{.+}}, {{.+}} : i8, i8
  // CHECK: }
  // CHECK: hw.output %[[G]]#0, %[[G]]#1 : i8, i8
  %0 = comb.add %a, %b : i8
  %1 = comb.mul %a, %b : i8
  hw.output %0, %1 : i8, i8
}
