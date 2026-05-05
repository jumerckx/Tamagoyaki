// RUN: tamagoyaki-opt -ematch-saturate %s -allow-unregistered-dialect | FileCheck %s

module @patterns {
    pdl_interp.func @matcher(%arg0: !pdl.operation) {
        %0 = pdl_interp.get_operand 1 of %arg0
        
        pdl_interp.is_not_null %0 : !pdl.value -> ^bb_success, ^bb1
        
        ^bb_success:
        // the pdl_interp bytecode VM cannot be extended with custom operations, except by using
        // pdl_interp.apply_rewrite or apply_constraint:
        // %eqs = ematch.class_vals(%0) : !pdl.range<value>
        %eqvals = pdl_interp.apply_rewrite "get_class_vals"(%0 : !pdl.value) : !pdl.range<value>
        
        pdl_interp.foreach %eqval : !pdl.value in %eqvals {
            %op = pdl_interp.get_defining_op of %eqval : !pdl.value
            pdl_interp.is_not_null %op : !pdl.operation -> ^bb2, ^bb_continue
        ^bb2:
            pdl_interp.check_operation_name of %arg0 is "arith.muli" -> ^bb3, ^bb_continue
        ^bb3:  // pred: ^bb2
            pdl_interp.check_operand_count of %arg0 is 2 -> ^bb4, ^bb_continue
        ^bb4:  // pred: ^bb3
            pdl_interp.check_result_count of %arg0 is 1 -> ^bb5, ^bb_continue
        ^bb5:  // pred: ^bb4
            %2 = pdl_interp.get_operand 0 of %arg0
            pdl_interp.is_not_null %2 : !pdl.value -> ^bb6, ^bb_continue
        ^bb6:  // pred: ^bb5
            pdl_interp.is_not_null %0 : !pdl.value -> ^bb7, ^bb_continue
        ^bb7:  // pred: ^bb6
            %3 = pdl_interp.get_result 0 of %arg0
            pdl_interp.is_not_null %3 : !pdl.value -> ^bb8, ^bb_continue
        ^bb8:  // pred: ^bb7
            %4 = pdl_interp.get_value_type of %2 : !pdl.type
            pdl_interp.check_type %4 is i32 -> ^bb9, ^bb_continue
        ^bb9:  // pred: ^bb8
            %5 = pdl_interp.get_value_type of %3 : !pdl.type
            pdl_interp.are_equal %4, %5 : !pdl.type -> ^bb10, ^bb_continue
        ^bb10:  // pred: ^bb9
            pdl_interp.check_operation_name of %op is "arith.constant" -> ^bb11, ^bb_continue
        ^bb11:  // pred: ^bb10
            pdl_interp.check_operand_count of %op is 0 -> ^bb12, ^bb_continue
        ^bb12:  // pred: ^bb11
            pdl_interp.check_result_count of %op is 1 -> ^bb13, ^bb_continue
        ^bb13:  // pred: ^bb12
            %6 = pdl_interp.get_attribute "value" of %op
            pdl_interp.is_not_null %6 : !pdl.attribute -> ^bb14, ^bb_continue
        ^bb14:  // pred: ^bb13
            pdl_interp.check_attribute %6 is 2 : i32 -> ^bb15, ^bb_continue
        ^bb15:  // pred: ^bb14
            %orig_7 = pdl_interp.get_result 0 of %op
             
            // after every pdl_interp.get_result:
            //%7 = ematch.class_result %orig_7 : !pdl.value
            %7 = pdl_interp.apply_rewrite "get_class_result"(%orig_7 : !pdl.value) : !pdl.value
            
            pdl_interp.is_not_null %7 : !pdl.value -> ^bb16, ^bb_continue
        ^bb16:  // pred: ^bb15
            pdl_interp.are_equal %7, %0 : !pdl.value -> ^bb17, ^bb_continue
        ^bb17:  // pred: ^bb16
            %8 = pdl_interp.get_value_type of %7 : !pdl.type
            pdl_interp.are_equal %8, %4 : !pdl.type -> ^bb18, ^bb_continue
        ^bb18:  // pred: ^bb17
            pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%2, %arg0 : !pdl.value, !pdl.operation) : benefit(1), generatedOps(["arith.constant", "arith.shli"]), loc([%op, %arg0]), root("arith.muli") -> ^bb_continue
        ^bb_continue:
            pdl_interp.continue
        } -> ^bb1
        ^bb1:
            pdl_interp.finalize
    }
    module @rewriters {
        pdl_interp.func @pdl_generated_rewriter(%arg0: !pdl.value, %arg1: !pdl.operation) {
            %0 = pdl_interp.create_attribute 1 : i32
            %1 = pdl_interp.create_type i32
            
            %orig_2 = pdl_interp.create_operation "arith.constant" {"value" = %0}  -> (%1 : !pdl.type)
            %2 = pdl_interp.apply_rewrite "dedup"(%orig_2 : !pdl.operation) : !pdl.operation
            
            %3 = pdl_interp.get_result 0 of %2
             
            %orig_4 = pdl_interp.create_operation "arith.shli"(%arg0, %3 : !pdl.value, !pdl.value)  -> (%1 : !pdl.type)
            
            // %4 = ematch.dedup(%orig_4)
            %4 = pdl_interp.apply_rewrite "dedup"(%orig_4 : !pdl.operation) : !pdl.operation
            
            %5 = pdl_interp.get_results of %4 : !pdl.range<value>
            // pdl_interp.replace %arg1 with (%5 : !pdl.range<value>)
            // becomes:
            // ematch.union(%arg1, %5)
            pdl_interp.apply_rewrite "union"(%arg1, %5 : !pdl.operation, !pdl.range<value>)
            // TODO: note that if the result of the operation (%5) would be used in the further rewrite, this would be incorrect.
            // After a union, uses of the result should be rerouted to the ClassOp result (union should return those).
            
            pdl_interp.finalize
        }
    }
}

module @ir {

    // CHECK:      func.func @graph_with_eqs(%arg0: i32) -> i32 {
    // CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
    // CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
    // CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
    // CHECK-NEXT:     %2 = equivalence.class %c2_i32 : i32
    // CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
    // CHECK-NEXT:     %3 = arith.shli %1, %c1_i32 : i32
    // CHECK-NEXT:     %4 = arith.muli %1, %2 : i32
    // CHECK-NEXT:     %5 = "test.op"() {equivalence.allow_unspeculatable} : () -> i32
    // CHECK-NEXT:     %6 = equivalence.class %5, %4, %3 : i32
    // CHECK-NEXT:     equivalence.yield %6 : i32
    // CHECK-NEXT:   }
    // CHECK-NEXT:   return %0 : i32
    // CHECK-NEXT: }

    func.func @graph_with_eqs(%arg0: i32) -> i32 {
        %0 = equivalence.graph -> (i32) {
            %1 = equivalence.class %arg0 : i32
            %c2_i32 = arith.constant 2 : i32
            %2 = equivalence.class %c2_i32 : i32
            %3 = arith.muli %1, %2 : i32
            %someotherval = "test.op"() {equivalence.allow_unspeculatable} : () -> (i32)
            %4 = equivalence.class %someotherval, %3 : i32
            equivalence.yield %4 : i32
        }
        return %0 : i32
    }
    
    
    // CHECK:      func.func @graph_without_eqs(%arg0: i32) -> i32 {
    // CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
    // CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
    // CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
    // CHECK-NEXT:     %1 = arith.shli %arg0, %c1_i32 : i32
    // CHECK-NEXT:     %2 = arith.muli %arg0, %c2_i32 : i32
    // CHECK-NEXT:     %3 = equivalence.class %2, %1 : i32
    // CHECK-NEXT:     equivalence.yield %3 : i32
    // CHECK-NEXT:   }
    // CHECK-NEXT:   return %0 : i32
    // CHECK-NEXT: }
    func.func @graph_without_eqs(%arg0: i32) -> i32 {
        %0 = equivalence.graph -> (i32) {
            %c2_i32 = arith.constant 2 : i32
            %3 = arith.muli %arg0, %c2_i32 : i32
            equivalence.yield %3 : i32
        }
        return %0 : i32
    }
    
}
