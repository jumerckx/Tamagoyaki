// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=1" -allow-unregistered-dialect | FileCheck %s

// ematch.get_class_vals visits the values of the class (and its leader chain)
// first, then those of the classes it refines into, transitively. Each class
// is visited once, so cyclic refinements terminate. A cycle of refinements is
// unioned when the graph is rebuilt, before matching.

// CHECK-LABEL: func.func @chain
// CHECK:         "test.seen"(%arg0)
// CHECK-NEXT:    "test.seen"(%arg3)
// CHECK-NEXT:    "test.seen"(%arg1)
// CHECK-NEXT:    "test.seen"(%arg2)
// CHECK-NEXT:    "test.probe"

// CHECK-LABEL: func.func @cycle
// CHECK:         %[[C:.*]] = equivalence.class %arg0, %arg1 : i32
// CHECK:         "test.seen"(%arg0)
// CHECK-NEXT:    "test.seen"(%arg1)
// CHECK-NEXT:    "test.probe"(%[[C]])

module @ir {
  func.func @chain(%arg0: i32, %arg1: i32, %arg2: i32, %arg3: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0, %arg3 refines %x : i32
      %x = equivalence.class %arg1 refines %y : i32
      %y = equivalence.class %arg2 : i32
      "test.probe"(%a) : (i32) -> ()
    }
    return
  }

  func.func @cycle(%arg0: i32, %arg1: i32) {
    equivalence.graph {
      %p = equivalence.class %arg0 refines %q : i32
      %q = equivalence.class %arg1 refines %p : i32
      "test.probe"(%p) : (i32) -> ()
    }
    return
  }
}

module @patterns {
  pdl_interp.func @matcher(%root: !pdl.operation) {
    pdl_interp.check_operation_name of %root is "test.probe" -> ^probe, ^end
  ^end:
    pdl_interp.finalize
  ^probe:
    %operand = pdl_interp.get_operand 0 of %root
    %vals = ematch.get_class_vals %operand
    pdl_interp.foreach %v : !pdl.value in %vals {
      pdl_interp.record_match @rewriters::@seen(%v : !pdl.value) : benefit(1), loc([]), root("test.probe") -> ^next
    ^next:
      pdl_interp.continue
    } -> ^end
  }

  builtin.module @rewriters {
    pdl_interp.func @seen(%v: !pdl.value) {
      %op = pdl_interp.create_operation "test.seen"(%v : !pdl.value)
      pdl_interp.finalize
    }
  }
}
