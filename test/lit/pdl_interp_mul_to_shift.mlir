// RUN: tamagoyaki-opt -ematch-apply-pdl-interp %s | FileCheck %s

module @ir {
    // CHECK:      func.func @main(%arg0: i32) -> i32 {
    // CHECK-NEXT:   %c1_i32 = arith.constant 1 : i32
    // CHECK-NEXT:   %0 = arith.shli %arg0, %c1_i32 : i32
    // CHECK-NEXT:   return %0 : i32
    // CHECK-NEXT: }

    func.func @main(%a: i32) -> i32 {
        %two = arith.constant 2 : i32
        %res = arith.muli %a, %two : i32
        func.return %res : i32
    }
}

module @patterns {
    pdl_interp.func @matcher(%arg0: !pdl.operation) {
        %0 = pdl_interp.get_operand 1 of %arg0
        %1 = pdl_interp.get_defining_op of %0 : !pdl.value
        pdl_interp.is_not_null %1 : !pdl.operation -> ^bb2, ^bb1
        ^bb1:  // 18 preds: ^bb0, ^bb2, ^bb3, ^bb4, ^bb5, ^bb6, ^bb7, ^bb8, ^bb9, ^bb10, ^bb11, ^bb12, ^bb13, ^bb14, ^bb15, ^bb16, ^bb17, ^bb18
        pdl_interp.finalize
        ^bb2:  // pred: ^bb0
        pdl_interp.check_operation_name of %arg0 is "arith.muli" -> ^bb3, ^bb1
        ^bb3:  // pred: ^bb2
        pdl_interp.check_operand_count of %arg0 is 2 -> ^bb4, ^bb1
        ^bb4:  // pred: ^bb3
        pdl_interp.check_result_count of %arg0 is 1 -> ^bb5, ^bb1
        ^bb5:  // pred: ^bb4
        %2 = pdl_interp.get_operand 0 of %arg0
        pdl_interp.is_not_null %2 : !pdl.value -> ^bb6, ^bb1
        ^bb6:  // pred: ^bb5
        pdl_interp.is_not_null %0 : !pdl.value -> ^bb7, ^bb1
        ^bb7:  // pred: ^bb6
        %3 = pdl_interp.get_result 0 of %arg0
        pdl_interp.is_not_null %3 : !pdl.value -> ^bb8, ^bb1
        ^bb8:  // pred: ^bb7
        %4 = pdl_interp.get_value_type of %2 : !pdl.type
        pdl_interp.check_type %4 is i32 -> ^bb9, ^bb1
        ^bb9:  // pred: ^bb8
        %5 = pdl_interp.get_value_type of %3 : !pdl.type
        pdl_interp.are_equal %4, %5 : !pdl.type -> ^bb10, ^bb1
        ^bb10:  // pred: ^bb9
        pdl_interp.check_operation_name of %1 is "arith.constant" -> ^bb11, ^bb1
        ^bb11:  // pred: ^bb10
        pdl_interp.check_operand_count of %1 is 0 -> ^bb12, ^bb1
        ^bb12:  // pred: ^bb11
        pdl_interp.check_result_count of %1 is 1 -> ^bb13, ^bb1
        ^bb13:  // pred: ^bb12
        %6 = pdl_interp.get_attribute "value" of %1
        pdl_interp.is_not_null %6 : !pdl.attribute -> ^bb14, ^bb1
        ^bb14:  // pred: ^bb13
        pdl_interp.check_attribute %6 is 2 : i32 -> ^bb15, ^bb1
        ^bb15:  // pred: ^bb14
        %7 = pdl_interp.get_result 0 of %1
        pdl_interp.is_not_null %7 : !pdl.value -> ^bb16, ^bb1
        ^bb16:  // pred: ^bb15
        pdl_interp.are_equal %7, %0 : !pdl.value -> ^bb17, ^bb1
        ^bb17:  // pred: ^bb16
        %8 = pdl_interp.get_value_type of %7 : !pdl.type
        pdl_interp.are_equal %8, %4 : !pdl.type -> ^bb18, ^bb1
        ^bb18:  // pred: ^bb17
        pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%2, %arg0 : !pdl.value, !pdl.operation) : benefit(1), generatedOps(["arith.constant", "arith.shli"]), loc([%1, %arg0]), root("arith.muli") -> ^bb1
    }
    module @rewriters {
        pdl_interp.func @pdl_generated_rewriter(%arg0: !pdl.value, %arg1: !pdl.operation) {
            %0 = pdl_interp.create_attribute 1 : i32
            %1 = pdl_interp.create_type i32
            %2 = pdl_interp.create_operation "arith.constant" {"value" = %0}  -> (%1 : !pdl.type)
            %3 = pdl_interp.get_result 0 of %2
            %4 = pdl_interp.create_operation "arith.shli"(%arg0, %3 : !pdl.value, !pdl.value)  -> (%1 : !pdl.type)
            %5 = pdl_interp.get_results of %4 : !pdl.range<value>
            pdl_interp.replace %arg1 with (%5 : !pdl.range<value>)
            pdl_interp.finalize
        }
    }
}
