// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=2" | FileCheck %s

// A pdl pattern may match through a refinement: the e-class members it
// navigates through include those of the e-classes the value refines into.
// Such a match only refines the root, so its replacement refines the root
// instead of being unioned with it. Here `negf(negf X) --> X`, where the inner
// negf is only in the e-class %c refines into.

// CHECK-LABEL: func.func @through_refinement
// CHECK:         %[[B:.*]] = equivalence.class %arg1 : f32
// CHECK:         %[[C:.*]] = equivalence.class %arg0 refines
// CHECK-NEXT:    %[[ROOT:.*]] = arith.negf %[[C]]
// CHECK-NEXT:    equivalence.class %[[ROOT]] refines %[[B]] : f32

// The same match without the refinement is a union.
// CHECK-LABEL: func.func @direct
// CHECK:         %[[C:.*]] = equivalence.class %{{.*}} : f32
// CHECK-NEXT:    %[[ROOT:.*]] = arith.negf %[[C]]
// CHECK-NEXT:    equivalence.class %[[ROOT]], %arg0 : f32

module @ir {
  func.func @through_refinement(%arg0: f32, %arg1: f32) -> f32 {
    %0 = equivalence.graph -> (f32) {
      %b = equivalence.class %arg1 : f32
      %inner = arith.negf %b : f32
      %r = equivalence.class %inner : f32
      %c = equivalence.class %arg0 refines %r : f32
      %root = arith.negf %c : f32
      equivalence.yield %root : f32
    }
    return %0 : f32
  }

  func.func @direct(%arg0: f32) -> f32 {
    %0 = equivalence.graph -> (f32) {
      %a = equivalence.class %arg0 : f32
      %inner = arith.negf %a : f32
      %c = equivalence.class %inner : f32
      %root = arith.negf %c : f32
      equivalence.yield %root : f32
    }
    return %0 : f32
  }
}

module @patterns {
  pdl.pattern @neg_neg : benefit(1) {
    %type = pdl.type
    %x = pdl.operand
    %inner = pdl.operation "arith.negf"(%x : !pdl.value) -> (%type : !pdl.type)
    %y = pdl.result 0 of %inner
    %outer = pdl.operation "arith.negf"(%y : !pdl.value) -> (%type : !pdl.type)
    pdl.rewrite %outer {
      pdl.replace %outer with (%x : !pdl.value)
    }
  }
}
