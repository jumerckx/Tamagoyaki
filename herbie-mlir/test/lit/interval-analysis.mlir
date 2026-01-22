// RUN: %herbie-mlir-opt -herbie-interval-analysis %s 2>&1 | FileCheck %s

// CHECK: arith.constant
// CHECK-SAME: -> [1
// CHECK: arith.constant
// CHECK-SAME: -> [2
// CHECK: arith.addi
// CHECK-SAME: -> [3

func.func @test_addi() -> i32 {
  %c1 = arith.constant 1 : i32
  %c2 = arith.constant 2 : i32
  %sum = arith.addi %c1, %c2 : i32
  return %sum : i32
}

// CHECK: arith.constant
// CHECK-SAME: -> [10
// CHECK: arith.constant
// CHECK-SAME: -> [3
// CHECK: arith.subi
// CHECK-SAME: -> [7

func.func @test_subi() -> i32 {
  %c10 = arith.constant 10 : i32
  %c3 = arith.constant 3 : i32
  %diff = arith.subi %c10, %c3 : i32
  return %diff : i32
}

// CHECK: arith.constant
// CHECK-SAME: -> [4
// CHECK: arith.constant
// CHECK-SAME: -> [5
// CHECK: arith.muli
// CHECK-SAME: -> [20

func.func @test_muli() -> i32 {
  %c4 = arith.constant 4 : i32
  %c5 = arith.constant 5 : i32
  %prod = arith.muli %c4, %c5 : i32
  return %prod : i32
}

// CHECK: arith.constant
// CHECK-SAME: -> [1.5
// CHECK: arith.constant
// CHECK-SAME: -> [2.5
// CHECK: arith.addf
// CHECK-SAME: -> [4

func.func @test_addf() -> f64 {
  %c1 = arith.constant 1.5 : f64
  %c2 = arith.constant 2.5 : f64
  %sum = arith.addf %c1, %c2 : f64
  return %sum : f64
}
