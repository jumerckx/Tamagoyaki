// RUN: tamagoyaki-opt -allow-unregistered-dialect -equivalence-insert-graph \
// RUN:   -ematch-saturate="patterns-file=%p/patterns.mlir max-nodes=4000" \
// RUN:   -equivalence-graph-size %s -o /dev/null | FileCheck %s


// CHECK: Graph has 441 e-classes and 1328 e-nodes.
builtin.module {
  func.func @NMSE_example_3.1(%0: f64) -> f64 {
    %1 = arith.constant 1.000000e+00 : f64
    %2 = arith.addf %0, %1 : f64
    %3 = math.sqrt %2 : f64
    %4 = math.sqrt %0 : f64
    %5 = arith.subf %3, %4 : f64
    func.return %5 : f64
  }
}
