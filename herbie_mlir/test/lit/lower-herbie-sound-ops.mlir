// RUN: herbie-mlir-opt %s --lower-herbie-sound-ops | FileCheck %s

// Test: herbie.sound_div -> arith.divf (fallback dropped)
// CHECK-LABEL: func.func @test_sound_div
func.func @test_sound_div(%a: f64, %b: f64, %fb: f64) -> f64 {
  // CHECK: %[[RES:.*]] = arith.divf %arg0, %arg1 : f64
  // CHECK-NOT: herbie.sound_div
  %0 = herbie.sound_div %a, %b, %fb : f64
  return %0 : f64
}

// Test: herbie.sound_pow -> math.powf (fallback dropped)
// CHECK-LABEL: func.func @test_sound_pow
func.func @test_sound_pow(%base: f64, %exp: f64, %fb: f64) -> f64 {
  // CHECK: %[[RES:.*]] = math.powf %arg0, %arg1 : f64
  // CHECK-NOT: herbie.sound_pow
  %0 = herbie.sound_pow %base, %exp, %fb : f64
  return %0 : f64
}

// Test: herbie.sound_log -> math.log (fallback dropped)
// CHECK-LABEL: func.func @test_sound_log
func.func @test_sound_log(%a: f64, %fb: f64) -> f64 {
  // CHECK: %[[RES:.*]] = math.log %arg0 : f64
  // CHECK-NOT: herbie.sound_log
  %0 = herbie.sound_log %a, %fb : f64
  return %0 : f64
}

// Test: f32 types
// CHECK-LABEL: func.func @test_f32
func.func @test_f32(%a: f32, %b: f32, %fb: f32) -> (f32, f32, f32) {
  // CHECK: %[[DIV:.*]] = arith.divf %arg0, %arg1 : f32
  // CHECK: %[[POW:.*]] = math.powf %arg0, %arg1 : f32
  // CHECK: %[[LOG:.*]] = math.log %arg0 : f32
  // CHECK-NOT: herbie.sound_div
  // CHECK-NOT: herbie.sound_pow
  // CHECK-NOT: herbie.sound_log
  %0 = herbie.sound_div %a, %b, %fb : f32
  %1 = herbie.sound_pow %a, %b, %fb : f32
  %2 = herbie.sound_log %a, %fb : f32
  return %0, %1, %2 : f32, f32, f32
}

// Test: mixed with other operations
// CHECK-LABEL: func.func @test_mixed
func.func @test_mixed(%a: f64, %b: f64, %fb: f64) -> f64 {
  // CHECK: %[[DIV:.*]] = arith.divf %arg0, %arg1 : f64
  // CHECK: %[[LOG:.*]] = math.log %[[DIV]] : f64
  // CHECK: %[[ADD:.*]] = arith.addf %[[LOG]], %arg0 : f64
  %0 = herbie.sound_div %a, %b, %fb : f64
  %1 = herbie.sound_log %0, %fb : f64
  %2 = arith.addf %1, %a : f64
  return %2 : f64
}
