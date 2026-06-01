// RUN: tamagoyaki-opt --equivalence-graph-size %s | FileCheck %s

// The walk includes the graph op itself, so it contributes one e-node (its
// result) and one implicit e-class (its result is used by `return` / unused,
// not by a class) on top of the classes and nodes in its body.

// First graph body: one explicit e-class wrapping muli + constant, plus the
// addi e-node whose result feeds the yield (implicit e-class). With the graph
// op itself that is 3 e-classes and 4 e-nodes.
// CHECK: Graph has 3 e-classes and 4 e-nodes.

// Second graph body: a single explicit e-class wrapping muli + constant, both
// single-use by the class. With the graph op itself that is 2 e-classes and 3
// e-nodes.
// CHECK: Graph has 2 e-classes and 3 e-nodes.

func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %a = arith.muli %arg0, %arg0 : i32
    %c5 = arith.constant 5 : i32
    %k1 = equivalence.class %a, %c5 : i32
    %r = arith.addi %k1, %k1 : i32
    equivalence.yield %r : i32
  }

  %1 = equivalence.graph -> (i32) {
    %b = arith.muli %arg0, %arg0 : i32
    %c7 = arith.constant 7 : i32
    %k2 = equivalence.class %b, %c7 : i32
    equivalence.yield %k2 : i32
  }

  return %0 : i32
}
