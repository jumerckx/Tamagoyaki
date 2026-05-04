// RUN: tamagoyaki-opt --ematch-saturate=max-iters=0 %s | FileCheck %s

module @ir {

    // CHECK:      %0:2 = equivalence.graph -> (i32, i32) {
    // CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
    // CHECK-NEXT:     %1 = arith.addi %c1_i32, %c1_i32 : i32
    // CHECK-NEXT:     equivalence.yield %1, %1, %1 : i32, i32, i32
    // CHECK-NEXT: }

    %0:2 = equivalence.graph -> (i32, i32) {
        %a = arith.constant 1 : i32
        %a_dup = arith.constant 1 : i32
        
        %1 = arith.addi %a, %a : i32
        %2 = arith.addi %a_dup, %a_dup : i32
        %3 = arith.addi %a_dup, %a : i32
    
        equivalence.yield %1, %2, %3 : i32, i32, i32
    }
}

module @patterns {}
