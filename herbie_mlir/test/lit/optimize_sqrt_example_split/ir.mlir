// RUN: herbie-mlir-opt %s -herbie-optimize="max-saturation-iters=4 patterns-file=%p/patterns.mlir" --remove-dead-values


// CHECK:      func.func @sqrt_example(%arg0: f32) -> f32 {
// CHECK-NEXT:     %cst = arith.constant 1.000000e+00 : f32
// CHECK-NEXT:     %0 = arith.addf %arg0, %cst : f32
// CHECK-NEXT:     %1 = math.sqrt %arg0 : f32
// CHECK-NEXT:     %2 = math.sqrt %0 : f32
// CHECK-NEXT:     %3 = arith.addf %2, %1 : f32
// CHECK-NEXT:     %4 = arith.divf %cst, %3 : f32
// CHECK-NEXT:     return %4 : f32
// CHECK-NEXT: }

func.func @sqrt_example(%x: f32) -> f32 {
    %one = arith.constant 1.000000e+00 : f32
    %x_add_one = arith.addf %x, %one : f32
    %sqrt_x_add_one = math.sqrt %x_add_one : f32
    %sqrt_x = math.sqrt %x : f32
    %out = arith.subf %sqrt_x_add_one, %sqrt_x : f32
    return %out : f32
}
