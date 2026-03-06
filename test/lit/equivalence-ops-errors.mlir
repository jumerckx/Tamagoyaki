// RUN: tamagoyaki-opt --verify-diagnostics %s

// ===----------------------------------------------------------------------===//
// Test equivalence.class verification - error cases
// ===----------------------------------------------------------------------===//

// Test: class operand cannot be result of another class operation
func.func @test_class_nested_class() {
    %0 = arith.constant 1 : i32
    %1 = equivalence.class %0 : i32
    // expected-error@+1 {{result of a class operation cannot be used as an operand of another class}}
    %2 = equivalence.class %1 : i32
    return
}

// Test: class operand must only be used by the class operation
func.func @test_class_operand_reuse() {
    %0 = arith.constant 1 : i32
    %1 = arith.constant 2 : i32
    // expected-error@+1 {{operands must only be used by the class operation}}
    %2 = equivalence.class %0 : i32
    %3 = arith.addi %0, %1 : i32
    return
}

// Test: class operand used in multiple class operations
func.func @test_class_operand_multiple_users() {
    %0 = arith.constant 1 : i32
    // expected-error@+1 {{operands must only be used by the class operation}}
    %1 = equivalence.class %0 : i32
    %2 = equivalence.class %0 : i32
    return
}
