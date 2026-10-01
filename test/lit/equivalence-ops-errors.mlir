// RUN: tamagoyaki-opt --verify-diagnostics -allow-unregistered-dialect %s

// ===----------------------------------------------------------------------===//
// Test equivalence.class verification - error cases
// ===----------------------------------------------------------------------===//

// Test: leader must be the result of a class operation.
func.func @test_class_bad_leader() {
    %0 = arith.constant 1 : i32
    %1 = arith.constant 2 : i32
    // expected-error@+1 {{leader must be the result of a class operation}}
    %2 = equivalence.class %0 leader %1 : i32
    return
}

// ===----------------------------------------------------------------------===//
// Test equivalence.graph verification - error cases
// ===----------------------------------------------------------------------===//

// Test: a graph region may contain non-speculatable operations. They are never
// hash-consed during saturation.
func.func @test_graph_unspeculatable_op() -> i32 {
    %0 = equivalence.graph -> (i32) {
        %1 = "test.op"() : () -> (i32)
        equivalence.yield %1 : i32
    }
    return %0 : i32
}
