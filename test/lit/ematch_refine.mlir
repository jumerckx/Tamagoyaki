// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=3" | FileCheck %s
// RUN: tamagoyaki-opt %s --ematch-saturate="max-iters=3 eager-rewrite=false" | FileCheck %s

// Two rewrites on
//   %s = sub %x, 1
//   %a = add nsw %s, 1
//   %c = icmp sgt %a, %s
// 1. add nsw (sub x, c), c  ~>  x   (a refinement: x is defined where a is
//                                    poison, but not the other way around)
// 2. icmp sgt (add nsw s, 1), s  -->  true
// Rule 2 must still match after rule 1 redirected the icmp to the refinement:
// get_class_vals of the refinement yields both %x and %a. Rule 1 keeps firing
// in later iterations but must not insert a second refinement.

// CHECK-LABEL: func.func @refine
// CHECK:         %[[X:.*]] = equivalence.class %arg0 : i32
// CHECK:         arith.subi %[[X]]
// CHECK-NEXT:    %[[S:.*]] = equivalence.class %{{.*}} : i32
// CHECK:         arith.addi %[[S]], %{{.*}} overflow<nsw>
// CHECK-NEXT:    %[[A:.*]] = equivalence.class %{{.*}} : i32
// CHECK-NEXT:    %[[R:.*]] = equivalence.refine %[[A]] into %[[X]] : i32
// CHECK-NOT:     equivalence.refine
// CHECK:         %[[TRUE:.*]] = arith.constant true
// CHECK:         %[[CMP:.*]] = arith.cmpi sgt, %[[R]], %[[S]] : i32
// CHECK-NEXT:    %[[C:.*]] = equivalence.class %[[CMP]], %[[TRUE]] : i1
// CHECK-NEXT:    equivalence.yield %[[C]] : i1

// Without single-element classes, the refinement uses the add directly rather
// than wrapping it in a class of its own.

// CHECK-LABEL: func.func @refine_no_classes
// CHECK:         %[[X:.*]] = equivalence.class %arg0 : i32
// CHECK:         %[[S:.*]] = arith.subi %[[X]]
// CHECK-NEXT:    %[[A:.*]] = arith.addi %[[S]], %{{.*}} overflow<nsw>
// CHECK-NEXT:    %[[R:.*]] = equivalence.refine %[[A]] into %[[X]] : i32
// CHECK-NOT:     equivalence.refine
// CHECK:         %[[TRUE:.*]] = arith.constant true
// CHECK:         %[[CMP:.*]] = arith.cmpi sgt, %[[R]], %[[S]] : i32
// CHECK-NEXT:    %[[C:.*]] = equivalence.class %[[CMP]], %[[TRUE]] : i1
// CHECK-NEXT:    equivalence.yield %[[C]] : i1

module @ir {
  func.func @refine(%arg0: i32) -> i1 {
    %0 = equivalence.graph -> (i1) {
      %x = equivalence.class %arg0 : i32
      %c1 = arith.constant 1 : i32
      %one = equivalence.class %c1 : i32
      %s0 = arith.subi %x, %one : i32
      %s = equivalence.class %s0 : i32
      %a0 = arith.addi %s, %one overflow<nsw> : i32
      %a = equivalence.class %a0 : i32
      %c0 = arith.cmpi sgt, %a, %s : i32
      %c = equivalence.class %c0 : i1
      equivalence.yield %c : i1
    }
    return %0 : i1
  }

  func.func @refine_no_classes(%arg0: i32) -> i1 {
    %0 = equivalence.graph -> (i1) {
      %x = equivalence.class %arg0 : i32
      %c1 = arith.constant 1 : i32
      %s = arith.subi %x, %c1 : i32
      %a = arith.addi %s, %c1 overflow<nsw> : i32
      %c = arith.cmpi sgt, %a, %s : i32
      equivalence.yield %c : i1
    }
    return %0 : i1
  }
}

module @patterns {
  pdl_interp.func @matcher(%root: !pdl.operation) {
    pdl_interp.switch_operation_name of %root to ["arith.addi", "arith.cmpi"](^add, ^cmp) -> ^end
  ^end:
    pdl_interp.finalize

  // add nsw (sub x, c), c  ~>  x
  ^add:
    %flags = pdl_interp.get_attribute "overflowFlags" of %root
    pdl_interp.check_attribute %flags is #arith.overflow<nsw> -> ^add1, ^end
  ^add1:
    %lhs = pdl_interp.get_operand 0 of %root
    %rhs = pdl_interp.get_operand 1 of %root
    %lhsVals = ematch.get_class_vals %lhs
    pdl_interp.foreach %v : !pdl.value in %lhsVals {
      %sub = pdl_interp.get_defining_op of %v : !pdl.value
      pdl_interp.is_not_null %sub : !pdl.operation -> ^sub0, ^subNext
    ^subNext:
      pdl_interp.continue
    ^sub0:
      pdl_interp.check_operation_name of %sub is "arith.subi" -> ^sub1, ^subNext
    ^sub1:
      %subRhs = pdl_interp.get_operand 1 of %sub
      ematch.are_equivalent %subRhs, %rhs -> ^sub2, ^subNext
    ^sub2:
      %x = pdl_interp.get_operand 0 of %sub
      pdl_interp.record_match @rewriters::@add_sub(%root, %x : !pdl.operation, !pdl.value) : benefit(1), loc([]), root("arith.addi") -> ^subNext
    } -> ^end

  // icmp sgt (add nsw s, 1), s  -->  true
  ^cmp:
    %pred = pdl_interp.get_attribute "predicate" of %root
    pdl_interp.check_attribute %pred is 4 : i64 -> ^cmp1, ^end
  ^cmp1:
    %cmpLhs = pdl_interp.get_operand 0 of %root
    %cmpRhs = pdl_interp.get_operand 1 of %root
    %cmpLhsVals = ematch.get_class_vals %cmpLhs
    pdl_interp.foreach %w : !pdl.value in %cmpLhsVals {
      %add = pdl_interp.get_defining_op of %w : !pdl.value
      pdl_interp.is_not_null %add : !pdl.operation -> ^addOp0, ^addNext
    ^addNext:
      pdl_interp.continue
    ^addOp0:
      pdl_interp.check_operation_name of %add is "arith.addi" -> ^addOp1, ^addNext
    ^addOp1:
      %addFlags = pdl_interp.get_attribute "overflowFlags" of %add
      pdl_interp.check_attribute %addFlags is #arith.overflow<nsw> -> ^addOp2, ^addNext
    ^addOp2:
      %addLhs = pdl_interp.get_operand 0 of %add
      ematch.are_equivalent %addLhs, %cmpRhs -> ^addOp3, ^addNext
    ^addOp3:
      %addRhs = pdl_interp.get_operand 1 of %add
      %addRhsVals = ematch.get_class_vals %addRhs
      pdl_interp.foreach %k : !pdl.value in %addRhsVals {
        %cst = pdl_interp.get_defining_op of %k : !pdl.value
        pdl_interp.is_not_null %cst : !pdl.operation -> ^cst0, ^cstNext
      ^cstNext:
        pdl_interp.continue
      ^cst0:
        pdl_interp.check_operation_name of %cst is "arith.constant" -> ^cst1, ^cstNext
      ^cst1:
        %value = pdl_interp.get_attribute "value" of %cst
        pdl_interp.check_attribute %value is 1 : i32 -> ^cst2, ^cstNext
      ^cst2:
        pdl_interp.record_match @rewriters::@sgt_true(%root : !pdl.operation) : benefit(1), loc([]), root("arith.cmpi") -> ^cstNext
      } -> ^addNext
    } -> ^end
  }

  builtin.module @rewriters {
    pdl_interp.func @add_sub(%root: !pdl.operation, %x: !pdl.value) {
      %res = pdl_interp.get_result 0 of %root
      %xClass = ematch.get_class_result %x
      ematch.refine %res : !pdl.value, %xClass : !pdl.value
      pdl_interp.finalize
    }
    pdl_interp.func @sgt_true(%root: !pdl.operation) {
      %i1 = pdl_interp.create_type i1
      %true = pdl_interp.create_attribute true
      %op = pdl_interp.create_operation "arith.constant" {"value" = %true} -> (%i1 : !pdl.type)
      %dedup = ematch.dedup %op
      %res = pdl_interp.get_result 0 of %dedup
      %range = pdl_interp.create_range %res : !pdl.value
      ematch.union %root : !pdl.operation, %range : !pdl.range<value>
      pdl_interp.finalize
    }
  }
}
