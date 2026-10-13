// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=1" -allow-unregistered-dialect | FileCheck %s

// ematch.get_class_vals on an equivalence.refine result visits the values of
// the refinement target before those of the source, following the whole chain
// of refinements (and the leader chain of each class). Each class and
// refinement is visited once, so cyclic refinements terminate.

// CHECK-LABEL: func.func @chain
// CHECK:         "test.seen"(%arg2)
// CHECK-NEXT:    "test.seen"(%arg1)
// CHECK-NEXT:    "test.seen"(%arg0)
// CHECK-NEXT:    "test.seen"(%arg3)
// CHECK-NEXT:    "test.probe"

// CHECK-LABEL: func.func @cycle
// CHECK:         "test.seen"(%arg1)
// CHECK-NEXT:    "test.seen"(%arg0)
// CHECK-NEXT:    "test.probe"

module @ir {
  func.func @chain(%arg0: i32, %arg1: i32, %arg2: i32, %arg3: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0, %arg3 : i32
      %x = equivalence.class %arg1 : i32
      %y = equivalence.class %arg2 : i32
      %r1 = equivalence.refine %a into %x : i32
      %r2 = equivalence.refine %r1 into %y : i32
      "test.probe"(%r2) : (i32) -> ()
    }
    return
  }

  func.func @cycle(%arg0: i32, %arg1: i32) {
    equivalence.graph {
      %p = equivalence.class %arg0 : i32
      %q = equivalence.class %arg1 : i32
      %r1 = equivalence.refine %p into %r2 : i32
      %r2 = equivalence.refine %q into %r1 : i32
      "test.probe"(%r1) : (i32) -> ()
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
