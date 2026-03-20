// RUN: herbie-mlir-opt %s --lower-herbie-constant -allow-unregistered-dialect | FileCheck %s

// Test: herbie.constant E -> arith.constant
// E ≈ 2.718281828...
// CHECK-LABEL: func.func @test_e
func.func @test_e() -> f64 {
  // CHECK: %[[E:.*]] = arith.constant 2.718281828{{.*}} : f64
  // CHECK-NOT: herbie.constant
  %0 = herbie.constant E : f64
  return %0 : f64
}

// Test: herbie.constant PI -> arith.constant
// PI ≈ 3.141592653...
// CHECK-LABEL: func.func @test_pi
func.func @test_pi() -> f32 {
  // CHECK: %[[PI:.*]] = arith.constant 3.14159274 : f32
  // CHECK-NOT: herbie.constant
  %0 = herbie.constant PI : f32
  return %0 : f32
}

// Test: herbie.constant SQRT2 -> arith.constant
// SQRT2 ≈ 1.414213562...
// CHECK-LABEL: func.func @test_sqrt2
func.func @test_sqrt2() -> f64 {
  // CHECK: %[[SQRT2:.*]] = arith.constant 1.414213562{{.*}} : f64
  // CHECK-NOT: herbie.constant
  %0 = herbie.constant SQRT2 : f64
  return %0 : f64
}

// Test: herbie.constant INFINITY -> arith.constant
// CHECK-LABEL: func.func @test_infinity
func.func @test_infinity() -> f64 {
  // CHECK: %[[INF:.*]] = arith.constant 0x7FF0000000000000 : f64
  // CHECK-NOT: herbie.constant
  %0 = herbie.constant INFINITY : f64
  return %0 : f64
}

// Test: multiple constants in same function
// CHECK-LABEL: func.func @test_multiple
func.func @test_multiple() -> f64 {
  // CHECK: %[[PI:.*]] = arith.constant 3.141592653{{.*}} : f64
  // CHECK: %[[E:.*]] = arith.constant 2.718281828{{.*}} : f64
  // CHECK-NOT: herbie.constant
  %pi = herbie.constant PI : f64
  %e = herbie.constant E : f64
  %result = arith.addf %pi, %e : f64
  return %result : f64
}

// Test: herbie.constant with arith operations
// CHECK-LABEL: func.func @test_with_ops
func.func @test_with_ops(%arg0: f64) -> f64 {
  // CHECK: %[[PI:.*]] = arith.constant {{.*}} : f64
  // CHECK: %[[RES:.*]] = arith.mulf %arg0, %[[PI]] : f64
  // CHECK-NOT: herbie.constant
  %pi = herbie.constant PI : f64
  %result = arith.mulf %arg0, %pi : f64
  return %result : f64
}

// Test: all supported constants are lowered
// CHECK-LABEL: func.func @test_all_constants
func.func @test_all_constants() {
  // All herbie.constant should be replaced with arith.constant
  // E ≈ 2.718..., PI ≈ 3.141..., SQRT2 ≈ 1.414..., etc.
  // CHECK: %{{.*}} = arith.constant 2.718281828{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 3.141592653{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 1.128379167{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 1.442695040{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 1.570796326{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 1.414213562{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.434294481{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.785398163{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.707106781{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.693147180{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.318309886{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0x7FF0000000000000 : f64
  // CHECK: %{{.*}} = arith.constant 2.302585092{{.*}} : f64
  // CHECK: %{{.*}} = arith.constant 0.636619772{{.*}} : f64
  // CHECK-NOT: herbie.constant
  %0 = herbie.constant E : f64
  %1 = herbie.constant PI : f64
  %2 = herbie.constant M_2_SQRTPI : f64
  %3 = herbie.constant LOG2E : f64
  %4 = herbie.constant PI_2 : f64
  %5 = herbie.constant SQRT2 : f64
  %6 = herbie.constant LOG10E : f64
  %7 = herbie.constant PI_4 : f64
  %8 = herbie.constant SQRT1_2 : f64
  %9 = herbie.constant LN2 : f64
  %10 = herbie.constant M_1_PI : f64
  %11 = herbie.constant INFINITY : f64
  %12 = herbie.constant LN10 : f64
  %13 = herbie.constant M_2_PI : f64
  "test.op"(%0, %1, %2, %3, %4, %5, %6, %7, %8, %9, %10, %11, %12, %13) : (f64, f64, f64, f64, f64, f64, f64, f64, f64, f64, f64, f64, f64, f64) -> ()
  return
  }
