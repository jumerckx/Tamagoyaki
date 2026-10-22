// RUN: tamagoyaki-opt --ematch-saturate="max-iters=3" %s -allow-unregistered-dialect | FileCheck %s

// A muli sits inside a nested graph and one of its operands (%arg0) is wrapped
// by a class in the OUTER graph. The pattern below (x * 1 -> x) unions the
// inner muli's result with that outer operand, i.e. an equivalence that
// crosses a graph-scope boundary. The union-find must:
//   * keep every e-class inside a graph (never the func body),
//   * orient the resulting leader operand OUTWARD (inner class -> outer class),
//   * and repoint the inner user of the outer class onto the inner class
//     (deepest-visible rep).

module @patterns {
  // x * 1 -> x
  pdl.pattern @mul_by_one : benefit(1) {
    %type = pdl.type : i32
    %x = pdl.operand : %type
    %one_attr = pdl.attribute = 1 : i32
    %one_op = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
    %one = pdl.result 0 of %one_op
    %mul = pdl.operation "arith.muli"(%x, %one : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    pdl.rewrite %mul {
      pdl.replace %mul with (%x : !pdl.value)
    }
  }
}

// CHECK-LABEL: func.func @nested
// CHECK:         %[[OUT:.*]] = equivalence.class %arg0 : i32
// CHECK:         %[[C2:.*]] = equivalence.class %{{.*}} : i32
// CHECK:         equivalence.graph
// CHECK:           %[[MUL:.*]] = arith.muli %[[IN:.*]], %[[C2]] : i32
// CHECK:           %[[IN]] = equivalence.class %[[MUL]] leader %[[OUT]] : i32

module @ir {
  func.func @nested(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
      %xc = equivalence.class %arg0 : i32
      %c1 = arith.constant 1 : i32
      %c1c = equivalence.class %c1 : i32
      %inner = equivalence.graph -> (i32) {
        %m = arith.muli %xc, %c1c : i32
        equivalence.yield %m : i32
      }
      %ic = equivalence.class %inner : i32
      equivalence.yield %ic : i32
    }
    return %0 : i32
  }
}
