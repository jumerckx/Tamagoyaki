// RUN: tamagoyaki-opt -allow-unregistered-dialect \
// RUN:   -ematch-convert-pdl-to-pdl-interp %p/patterns.mlir \
// RUN:   | sed -e 's/apply_rewrite "union"/apply_rewrite "refine"/' \
// RUN:     -e 's/apply_rewrite "union_or_refine"(\([^,]*\), \([^,]*\),[^:]*: \([^,]*\), \([^,]*\),.*/apply_rewrite "refine"(\1, \2 : \3, \4)/' \
// RUN:   > %t.patterns.mlir
// RUN: tamagoyaki-opt -allow-unregistered-dialect -equivalence-insert-graph \
// RUN:   -ematch-saturate="patterns-file=%t.patterns.mlir max-iters=6 max-nodes=4000" \
// RUN:   -equivalence-graph-size %s -o %t.mlir | FileCheck %s
// RUN: tamagoyaki-opt -allow-unregistered-dialect \
// RUN:   --equivalence-select-greedy=default-cost=1 \
// RUN:   --equivalence-extract=remove-graphs %t.mlir -o /dev/null

// The sqrt example with every union in the Herbie ruleset turned into a
// refinement: the PDL patterns are lowered first, so that the "union" and
// "union_or_refine" native rewrites that `pdl.replace` becomes can be swapped
// for "refine".
// Rebuilding refinements creates e-classes while duplicate e-nodes are being
// merged; this used to leave some unions unfused (and later e-classes without
// inputs) when a new class reused an erased e-node's address.

// CHECK: Graph has 2066 e-classes and 4547 e-nodes.
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
