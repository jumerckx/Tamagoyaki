// RUN: tamagoyaki-opt -ematch-saturate %s -allow-unregistered-dialect | FileCheck %s

// Non-speculatable operations are permitted inside an equivalence.graph but must
// never be hash-consed: deduplicating them could drop or reorder side effects.
// Here the two speculatable duplicates (arith.constant, arith.addi) are collapsed
// by hash-consing, while the two non-speculatable "test.op" duplicates are kept
// distinct.

module @patterns {
    pdl_interp.func @matcher(%arg0: !pdl.operation) {
        pdl_interp.finalize
    }
    module @rewriters {
    }
}

module @ir {
    // CHECK:      func.func @dup(%arg0: i32) -> i32 {
    // CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
    // The two duplicate arith.constant ops are hash-consed into one.
    // CHECK-NEXT:     %c42_i32 = arith.constant 42 : i32
    // The two non-speculatable test.op duplicates are NOT merged.
    // CHECK-NEXT:     %1 = "test.op"() : () -> i32
    // CHECK-NEXT:     %2 = "test.op"() : () -> i32
    // CHECK-NEXT:     %3 = equivalence.class %c42_i32 : i32
    // CHECK-NEXT:     %4 = equivalence.class %1, %2 : i32
    // The two duplicate arith.addi ops are hash-consed into one.
    // CHECK-NEXT:     %5 = arith.addi %3, %4 : i32
    // CHECK-NEXT:     %6 = equivalence.class %5 : i32
    // CHECK-NEXT:     equivalence.yield %6 : i32
    // CHECK-NEXT:   }
    // CHECK-NEXT:   return %0 : i32
    // CHECK-NEXT: }
    func.func @dup(%arg0: i32) -> i32 {
        %0 = equivalence.graph -> (i32) {
            %a = arith.constant 42 : i32
            %b = arith.constant 42 : i32
            %x = "test.op"() : () -> i32
            %y = "test.op"() : () -> i32
            %ca = equivalence.class %a, %b : i32
            %cx = equivalence.class %x, %y : i32
            %add0 = arith.addi %ca, %cx : i32
            %add1 = arith.addi %ca, %cx : i32
            %c = equivalence.class %add0, %add1 : i32
            equivalence.yield %c : i32
        }
        return %0 : i32
    }
}
