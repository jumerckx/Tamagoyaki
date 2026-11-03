// RUN: tamagoyaki-opt --equivalence-graph-size %s | FileCheck %s

func.func @main(%arg0: i32) -> i32 {
// CHECK: Graph has 2 e-classes and 3 e-nodes.
  %0 = equivalence.graph -> (i32) {
    %a = arith.muli %arg0, %arg0 : i32
    %c5 = arith.constant 5 : i32
    %k1 = equivalence.class %a, %c5 : i32
    %r = arith.addi %k1, %k1 : i32
    equivalence.yield %r : i32
  }

// CHECK: Graph has 1 e-classes and 2 e-nodes.
  %1 = equivalence.graph -> (i32) {
    %b = arith.muli %arg0, %arg0 : i32
    %c7 = arith.constant 7 : i32
    %k2 = equivalence.class %b, %c7 : i32
    equivalence.yield %k2 : i32
  }

// A refinement edge is an e-node of the class holding it, not an e-class.
// CHECK: Graph has 4 e-classes and 4 e-nodes.
  %2 = equivalence.graph -> (i32) {
    %x = equivalence.class %arg0 : i32
    %c1 = arith.constant 1 : i32
    %s = arith.subi %x, %c1 : i32
    %add = arith.addi %s, %c1 : i32
    %a = equivalence.class %add refines %x : i32
    equivalence.yield %a : i32
  }

  return %0 : i32
}
