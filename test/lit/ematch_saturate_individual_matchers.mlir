// RUN: tamagoyaki-opt %s -ematch-saturate | FileCheck %s


// CHECK:      %0 = equivalence.graph -> (i32) {
// CHECK-NEXT:   %c2_i32 = arith.constant 2 : i32
// CHECK-NEXT:   %1 = arith.muli %6, %c2_i32 : i32
// CHECK-NEXT:   %c1_i32 = arith.constant 1 : i32
// CHECK-NEXT:   %2 = arith.divui %c2_i32, %c2_i32 : i32
// CHECK-NEXT:   %3 = equivalence.class %2, %c1_i32 : i32
// CHECK-NEXT:   %4 = arith.muli %6, %3 : i32
// CHECK-NEXT:   %5 = arith.divui %1, %c2_i32 : i32
// CHECK-NEXT:   %6 = equivalence.class %5, %4, %arg0 : i32
// CHECK-NEXT:   equivalence.yield %6 : i32
// CHECK-NEXT: }


module @ir {
    func.func @main(%arg0: i32) -> i32 {
        %0 = equivalence.graph -> (i32) {
            %c2_i32 = arith.constant 2 : i32
            %1 = arith.muli %arg0, %c2_i32 : i32
            %2 = arith.divui %1, %c2_i32 : i32
            equivalence.yield %2 : i32
        }
        return %0 : i32
    }
}

module @patterns {

pdl_interp.func @matcher_0(%0: !pdl.operation) {
    %1 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb0, ^bb1
    ^bb0:
    %2 = ematch.get_class_result %1
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb2, ^bb1
    ^bb1:
    pdl_interp.finalize
    ^bb2:
    pdl_interp.check_operation_name of %0 is "arith.divui" -> ^bb3, ^bb1
    ^bb3:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb4, ^bb1
    ^bb4:
    pdl_interp.check_result_count of %0 is 1 -> ^bb5, ^bb1
    ^bb5:
    %3 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb6, ^bb1
    ^bb6:
    %4 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb7, ^bb1
    ^bb7:
    %5 = ematch.get_class_vals %3
    pdl_interp.foreach %6 : !pdl.value in %5 {
        %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[0].defining_op"}
        pdl_interp.is_not_null %7 : !pdl.operation -> ^bb8, ^bb9
    ^bb9:
        pdl_interp.continue
    ^bb8:
        pdl_interp.check_operation_name of %7 is "arith.muli" -> ^bb10, ^bb9
    ^bb10:
        pdl_interp.check_operand_count of %7 is 2 -> ^bb11, ^bb9
    ^bb11:
        pdl_interp.check_result_count of %7 is 1 -> ^bb12, ^bb9
    ^bb12:
        %8 = pdl_interp.get_operand 0 of %7
        pdl_interp.is_not_null %8 : !pdl.value -> ^bb13, ^bb9
    ^bb13:
        %9 = pdl_interp.get_operand 1 of %7
        pdl_interp.is_not_null %9 : !pdl.value -> ^bb14, ^bb9
    ^bb14:
        %10 = pdl_interp.get_result 0 of %7
        pdl_interp.is_not_null %10 : !pdl.value -> ^bb15, ^bb9
    ^bb15:
        %11 = ematch.get_class_result %10
        pdl_interp.is_not_null %11 : !pdl.value -> ^bb16, ^bb9
    ^bb16:
        pdl_interp.are_equal %11, %3 : !pdl.value -> ^bb17, ^bb9
    ^bb17:
        %12 = pdl_interp.get_value_type of %11 : !pdl.type
        %13 = pdl_interp.get_value_type of %2 : !pdl.type
        pdl_interp.are_equal %12, %13 : !pdl.type -> ^bb18, ^bb9
    ^bb18:
        %14 = ematch.get_class_representative %9
        %15 = ematch.get_class_representative %4
        %16 = ematch.get_class_representative %8
        pdl_interp.record_match @rewriters::@pdl_generated_rewriter(%14, %15, %12, %16, %0 : !pdl.value, !pdl.value, !pdl.type, !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.divui") -> ^bb9
    } -> ^bb1
    }
    pdl_interp.func @matcher_1(%0: !pdl.operation) {
    pdl_interp.check_operation_name of %0 is "arith.divui" -> ^bb0, ^bb1
    ^bb1:
    pdl_interp.finalize
    ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb2, ^bb1
    ^bb2:
    pdl_interp.check_result_count of %0 is 1 -> ^bb3, ^bb1
    ^bb3:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb4, ^bb1
    ^bb4:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.are_equal %1, %2 : !pdl.value -> ^bb5, ^bb1
    ^bb5:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb6, ^bb1
    ^bb6:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb7, ^bb1
    ^bb7:
    %5 = pdl_interp.get_value_type of %4 : !pdl.type
    pdl_interp.record_match @rewriters::@pdl_generated_rewriter_0(%5, %0 : !pdl.type, !pdl.operation) : benefit(1), loc([]), root("arith.divui") -> ^bb1
    }
    pdl_interp.func @matcher_2(%0: !pdl.operation) {
    pdl_interp.check_operation_name of %0 is "arith.muli" -> ^bb0, ^bb1
    ^bb1:
    pdl_interp.finalize
    ^bb0:
    pdl_interp.check_operand_count of %0 is 2 -> ^bb2, ^bb1
    ^bb2:
    pdl_interp.check_result_count of %0 is 1 -> ^bb3, ^bb1
    ^bb3:
    %1 = pdl_interp.get_operand 0 of %0
    pdl_interp.is_not_null %1 : !pdl.value -> ^bb4, ^bb1
    ^bb4:
    %2 = pdl_interp.get_operand 1 of %0
    pdl_interp.is_not_null %2 : !pdl.value -> ^bb5, ^bb1
    ^bb5:
    %3 = pdl_interp.get_result 0 of %0
    pdl_interp.is_not_null %3 : !pdl.value -> ^bb6, ^bb1
    ^bb6:
    %4 = ematch.get_class_result %3
    pdl_interp.is_not_null %4 : !pdl.value -> ^bb7, ^bb1
    ^bb7:
    %5 = ematch.get_class_vals %2
    pdl_interp.foreach %6 : !pdl.value in %5 {
        %7 = pdl_interp.get_defining_op of %6 : !pdl.value {position = "root.operand[1].defining_op"}
        pdl_interp.is_not_null %7 : !pdl.operation -> ^bb8, ^bb9
    ^bb9:
        pdl_interp.continue
    ^bb8:
        pdl_interp.check_operation_name of %7 is "arith.constant" -> ^bb10, ^bb9
    ^bb10:
        pdl_interp.check_operand_count of %7 is 0 -> ^bb11, ^bb9
    ^bb11:
        pdl_interp.check_result_count of %7 is 1 -> ^bb12, ^bb9
    ^bb12:
        %8 = pdl_interp.get_attribute "value" of %7
        pdl_interp.is_not_null %8 : !pdl.attribute -> ^bb13, ^bb9
    ^bb13:
        pdl_interp.check_attribute %8 is 1 : i32 -> ^bb14, ^bb9
    ^bb14:
        %9 = pdl_interp.get_result 0 of %7
        pdl_interp.is_not_null %9 : !pdl.value -> ^bb15, ^bb9
    ^bb15:
        %10 = ematch.get_class_result %9
        pdl_interp.is_not_null %10 : !pdl.value -> ^bb16, ^bb9
    ^bb16:
        pdl_interp.are_equal %10, %2 : !pdl.value -> ^bb17, ^bb9
    ^bb17:
        %11 = pdl_interp.get_value_type of %10 : !pdl.type
        %12 = pdl_interp.get_value_type of %4 : !pdl.type
        pdl_interp.are_equal %11, %12 : !pdl.type -> ^bb18, ^bb9
    ^bb18:
        %13 = ematch.get_class_representative %1
        pdl_interp.record_match @rewriters::@pdl_generated_rewriter_1(%13, %0 : !pdl.value, !pdl.operation) : benefit(1), loc([]), root("arith.muli") -> ^bb9
    } -> ^bb1
    }
    builtin.module @rewriters {
    pdl_interp.func @pdl_generated_rewriter(%0: !pdl.value, %1: !pdl.value, %2: !pdl.type, %3: !pdl.value, %4: !pdl.operation) {
        %5 = ematch.get_class_result %0
        %6 = ematch.get_class_result %1
        %7 = pdl_interp.create_operation "arith.divui"(%5, %6 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
        %8 = ematch.dedup %7
        %9 = pdl_interp.get_result 0 of %8
        %10 = ematch.get_class_result %9
        %11 = ematch.get_class_result %3
        %12 = pdl_interp.create_operation "arith.muli"(%11, %10 : !pdl.value, !pdl.value) -> (%2 : !pdl.type)
        %13 = ematch.dedup %12
        %14 = pdl_interp.get_result 0 of %13
        %15 = ematch.get_class_result %14
        %16 = pdl_interp.get_results of %13 : !pdl.range<value>
        %17 = ematch.get_class_results %16
        ematch.union %4 : !pdl.operation, %17 : !pdl.range<value>
        pdl_interp.finalize
    }
    pdl_interp.func @pdl_generated_rewriter_0(%0: !pdl.type, %1: !pdl.operation) {
        %2 = pdl_interp.create_attribute 1 : i32
        %3 = pdl_interp.create_operation "arith.constant" {"value" = %2} -> (%0 : !pdl.type)
        %4 = ematch.dedup %3
        %5 = pdl_interp.get_results of %4 : !pdl.range<value>
        %6 = ematch.get_class_results %5
        ematch.union %1 : !pdl.operation, %6 : !pdl.range<value>
        pdl_interp.finalize
    }
    pdl_interp.func @pdl_generated_rewriter_1(%0: !pdl.value, %1: !pdl.operation) {
        %2 = ematch.get_class_result %0
        %3 = pdl_interp.create_range %2 : !pdl.value
        ematch.union %1 : !pdl.operation, %3 : !pdl.range<value>
        pdl_interp.finalize
    }
}
    
    //// (x * y) / z -> x * (y/z)
    //pdl.pattern : benefit(1) {
    //  %x = pdl.operand
    //  %y = pdl.operand
    //  %z = pdl.operand
    //  %type = pdl.type
    //  %mulop = pdl.operation "arith.muli" (%x, %y: !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //  %mul = pdl.result 0 of %mulop
    //  %resultop = pdl.operation "arith.divui" (%mul, %z: !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //  %result = pdl.result 0 of %resultop
    //  pdl.rewrite %resultop {
    //    %newdivop = pdl.operation "arith.divui" (%y, %z: !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //    %newdiv = pdl.result 0 of %newdivop
    //    %newresultop = pdl.operation "arith.muli" (%x, %newdiv: !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //    %newresult = pdl.result 0 of %newresultop
    //    pdl.replace %resultop with %newresultop
    //  }
    //}
    
    //// x / x -> 1
    //pdl.pattern : benefit(1) {
    //  %x = pdl.operand
    //  %type = pdl.type
    //  %resultop = pdl.operation "arith.divui" (%x, %x : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //  pdl.rewrite %resultop {
    //    %2 = pdl.attribute = 1 : i32
    //    %3 = pdl.operation "arith.constant" {"value" = %2} -> (%type : !pdl.type)
    //    pdl.replace %resultop with %3
    //  }
    //}
    
    //// x * 1 -> x
    //pdl.pattern : benefit(1) {
    //  %x = pdl.operand
    //  %type = pdl.type
    //  %one = pdl.attribute = 1 : i32
    //  %constop = pdl.operation "arith.constant" {"value" = %one} -> (%type : !pdl.type)
    //  %const = pdl.result 0 of %constop
    //  %mulop = pdl.operation "arith.muli" (%x, %const : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    //  pdl.rewrite %mulop {
    //    pdl.replace %mulop with (%x : !pdl.value)
    //  }
    //}
}
