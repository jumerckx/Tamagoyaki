// RUN: tamagoyaki-opt %s -allow-unregistered-dialect --ematch-saturate="max-iters=5" | FileCheck %s
// RUN: tamagoyaki-opt %s -allow-unregistered-dialect --ematch-saturate="max-iters=5 eager-rewrite=false" | FileCheck %s

// Rebuilding refinements. "test.refine"(%a, %b) refines %a into %b,
// "test.union"(%a, %b) unions them and "test.mk"(%a, %b) creates a*b.

// Congruence: a <= b implies a*k <= b*k. The two products stay distinct
// e-nodes in distinct e-classes: refinement never merges e-classes.
// CHECK-LABEL: func.func @congruence
// CHECK:         %[[A:.*]] = equivalence.class %arg0 refines %[[B:.*]] : i32
// CHECK-NEXT:    %[[B]] = equivalence.class %arg1 : i32
// CHECK-NEXT:    %[[FA:.*]] = arith.muli %[[A]], %arg2 : i32
// CHECK-NEXT:    %[[FAC:.*]] = equivalence.class %[[FA]] refines %[[FBC:.*]] : i32
// CHECK-NEXT:    %[[FB:.*]] = arith.muli %[[B]], %arg2 : i32
// CHECK-NEXT:    %[[FBC]] = equivalence.class %[[FB]] : i32
// CHECK:         "test.use"(%[[FAC]], %[[FBC]])

// Congruence propagates: a*k <= b*k then gives (a*k)+k <= (b*k)+k.
// CHECK-LABEL: func.func @chained
// CHECK:         arith.addi
// CHECK-NEXT:    %[[GA:.*]] = equivalence.class %{{.*}} refines %[[GB:.*]] : i32
// CHECK-NEXT:    arith.addi
// CHECK-NEXT:    %[[GB]] = equivalence.class %{{.*}} : i32
// CHECK:         "test.use"(%[[GA]], %[[GB]])

// An e-node created after the refinement (b*k, by "test.mk") is still found.
// CHECK-LABEL: func.func @late_node
// CHECK:         %[[FA:.*]] = arith.muli
// CHECK-NEXT:    %[[FAC:.*]] = equivalence.class %[[FA]] refines %[[FBC:.*]] : i32
// CHECK-NEXT:    %[[FB:.*]] = arith.muli
// CHECK-NEXT:    %[[FBC]] = equivalence.class %[[FB]] : i32
// CHECK:         "test.use"(%[[FAC]])

// Merging refined classes: a <= b, a2 <= c and a == a2 leave the merged class
// with all refinements, and a*k and a2*k are congruent.
// CHECK-LABEL: func.func @merge
// CHECK:         equivalence.class %arg0, %arg1 refines %{{.*}}, %{{.*}}, %{{.*}} : i32
// CHECK:         %[[F:.*]] = arith.muli
// CHECK-NOT:     arith.muli
// CHECK:         "test.use"(%[[F]], %[[F]])

// A union can close a cycle of refinements (a <= b <= c, then c <= a unions
// a and c): the whole cycle is one e-class and the refinements disappear.
// CHECK-LABEL: func.func @cycle
// CHECK:         %[[C:.*]] = equivalence.class %{{.*}}, %{{.*}}, %{{.*}} : i32
// CHECK-NOT:     refines
// CHECK:         "test.use"(%[[C]], %[[C]], %[[C]])

// x*0 == 0, with 0 found through a refinement (a <= 0): a*k only refines 0.
// Matched directly, 0*k is unioned with 0.
// CHECK-LABEL: func.func @union_or_refine
// CHECK:         %[[A:.*]] = equivalence.class %arg0 refines %[[Z:.*]] : i32
// CHECK:         %[[FA:.*]] = arith.muli %[[A]]
// CHECK-NEXT:    %[[FAC:.*]] = equivalence.class %[[FA]] refines %[[Z]] : i32
// CHECK-NEXT:    %[[FZ:.*]] = arith.muli %[[Z]]
// CHECK-NEXT:    %[[Z]] = equivalence.class %[[FZ]], %{{.*}} : i32
// CHECK:         "test.use"(%[[FAC]], %[[Z]])

module @ir {
  func.func @congruence(%arg0: i32, %arg1: i32, %arg2: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0 : i32
      %b = equivalence.class %arg1 : i32
      %fa = arith.muli %a, %arg2 : i32
      %fb = arith.muli %b, %arg2 : i32
      "test.refine"(%a, %b) : (i32, i32) -> ()
      "test.use"(%fa, %fb) : (i32, i32) -> ()
    }
    return
  }

  func.func @chained(%arg0: i32, %arg1: i32, %arg2: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0 : i32
      %b = equivalence.class %arg1 : i32
      %fa = arith.muli %a, %arg2 : i32
      %fb = arith.muli %b, %arg2 : i32
      %ga = arith.addi %fa, %arg2 : i32
      %gb = arith.addi %fb, %arg2 : i32
      "test.refine"(%a, %b) : (i32, i32) -> ()
      "test.use"(%ga, %gb) : (i32, i32) -> ()
    }
    return
  }

  func.func @late_node(%arg0: i32, %arg1: i32, %arg2: i32) {
    equivalence.graph {
      %b = equivalence.class %arg1 : i32
      %a = equivalence.class %arg0 refines %b : i32
      %fa = arith.muli %a, %arg2 : i32
      "test.mk"(%b, %arg2) : (i32, i32) -> ()
      "test.use"(%fa) : (i32) -> ()
    }
    return
  }

  func.func @merge(%arg0: i32, %arg1: i32, %arg2: i32, %arg3: i32, %arg4: i32, %arg5: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0 : i32
      %a2 = equivalence.class %arg1 : i32
      %b = equivalence.class %arg2 : i32
      %c = equivalence.class %arg3 : i32
      %d = equivalence.class %arg5 : i32
      %fa = arith.muli %a, %arg4 : i32
      %fa2 = arith.muli %a2, %arg4 : i32
      "test.refine"(%a, %b) : (i32, i32) -> ()
      "test.refine"(%a2, %c) : (i32, i32) -> ()
      "test.union"(%a, %a2) : (i32, i32) -> ()
      "test.refine"(%a2, %d) : (i32, i32) -> ()
      "test.use"(%fa, %fa2) : (i32, i32) -> ()
    }
    return
  }

  func.func @cycle(%arg0: i32, %arg1: i32, %arg2: i32) {
    equivalence.graph {
      %a = equivalence.class %arg0 : i32
      %b = equivalence.class %arg1 : i32
      %c = equivalence.class %arg2 : i32
      "test.refine"(%a, %b) : (i32, i32) -> ()
      "test.refine"(%b, %c) : (i32, i32) -> ()
      "test.refine"(%c, %a) : (i32, i32) -> ()
      "test.use"(%a, %b, %c) : (i32, i32, i32) -> ()
    }
    return
  }

  func.func @union_or_refine(%arg0: i32, %arg1: i32) {
    equivalence.graph {
      %z = arith.constant 0 : i32
      %a = equivalence.class %arg0 : i32
      %fa = arith.muli %a, %arg1 : i32
      %fz = arith.muli %z, %arg1 : i32
      "test.refine"(%a, %z) : (i32, i32) -> ()
      "test.use"(%fa, %fz) : (i32, i32) -> ()
    }
    return
  }
}

module @patterns {
  pdl_interp.func @matcher(%root: !pdl.operation) {
    pdl_interp.switch_operation_name of %root to ["test.refine", "test.union", "test.mk", "arith.muli"](^refine, ^union, ^mk, ^mul) -> ^end
  ^end:
    pdl_interp.finalize
  ^refine:
    pdl_interp.record_match @rewriters::@refine(%root : !pdl.operation) : benefit(1), loc([]), root("test.refine") -> ^end
  ^union:
    pdl_interp.record_match @rewriters::@union(%root : !pdl.operation) : benefit(1), loc([]), root("test.union") -> ^end
  ^mk:
    pdl_interp.record_match @rewriters::@mk(%root : !pdl.operation) : benefit(1), loc([]), root("test.mk") -> ^end

  // x * 0 == 0, where 0 is found among the values of x's e-class.
  ^mul:
    %x = pdl_interp.get_operand 0 of %root
    %xVals = ematch.get_class_vals %x
    pdl_interp.foreach %v : !pdl.value in %xVals {
      %def = pdl_interp.get_defining_op of %v : !pdl.value
      pdl_interp.is_not_null %def : !pdl.operation -> ^cst0, ^next
    ^next:
      pdl_interp.continue
    ^cst0:
      pdl_interp.check_operation_name of %def is "arith.constant" -> ^cst1, ^next
    ^cst1:
      %value = pdl_interp.get_attribute "value" of %def
      pdl_interp.check_attribute %value is 0 : i32 -> ^cst2, ^next
    ^cst2:
      pdl_interp.record_match @rewriters::@mul_zero(%root, %x, %v : !pdl.operation, !pdl.value, !pdl.value) : benefit(1), loc([]), root("arith.muli") -> ^next
    } -> ^end
  }

  builtin.module @rewriters {
    pdl_interp.func @refine(%root: !pdl.operation) {
      %a = pdl_interp.get_operand 0 of %root
      %b = pdl_interp.get_operand 1 of %root
      ematch.refine %a : !pdl.value, %b : !pdl.value
      pdl_interp.finalize
    }
    pdl_interp.func @union(%root: !pdl.operation) {
      %a = pdl_interp.get_operand 0 of %root
      %b = pdl_interp.get_operand 1 of %root
      ematch.union %a : !pdl.value, %b : !pdl.value
      pdl_interp.finalize
    }
    pdl_interp.func @mk(%root: !pdl.operation) {
      %a = pdl_interp.get_operand 0 of %root
      %b = pdl_interp.get_operand 1 of %root
      %i32 = pdl_interp.create_type i32
      %op = pdl_interp.create_operation "arith.muli"(%a, %b : !pdl.value, !pdl.value) -> (%i32 : !pdl.type)
      %dedup = ematch.dedup %op
      pdl_interp.finalize
    }
    pdl_interp.func @mul_zero(%root: !pdl.operation, %x: !pdl.value, %zero: !pdl.value) {
      %zeroClass = ematch.get_class_result %zero
      %range = pdl_interp.create_range %zeroClass : !pdl.value
      ematch.union_or_refine %root : !pdl.operation, %range : !pdl.range<value> checks(%x, %zero : !pdl.value, !pdl.value)
      pdl_interp.finalize
    }
  }
}
