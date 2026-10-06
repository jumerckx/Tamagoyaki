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
