// RUN: cranelift-mlir-opt %s --pass-pipeline="builtin.module(func.func(cranelift-optimize{patterns-file=%p/patterns.mlir}))" | FileCheck %s

// CHECK:      func.func @f(%arg0: memref<f32>) -> f32 {
// CHECK-NEXT:   %0 = memref.load %arg0[] : memref<f32>
// CHECK-NEXT:   %cst = arith.constant 5.000000e-01 : f32
// CHECK-NEXT:   %1 = arith.cmpf ogt, %0, %cst : f32
// CHECK-NEXT:   cf.cond_br %1, ^bb1, ^bb2
// CHECK-NEXT: ^bb1:
// CHECK-NEXT:   %cst_0 = arith.constant 1.000000e+00 : f32
// CHECK-NEXT:   cf.br ^bb3(%cst_0 : f32)
// CHECK-NEXT: ^bb2:
// CHECK-NEXT:   %cst_1 = arith.constant 4.200000e+01 : f32
// CHECK-NEXT:   cf.br ^bb3(%cst_1 : f32)
// CHECK-NEXT: ^bb3(%2: f32):
// CHECK-NEXT:   return %2 : f32
// CHECK-NEXT: }

func.func @f(%p: memref<f32>) -> f32 {
    %x = memref.load %p[] : memref<f32>
    %sx = math.sin %x : f32
    %sx_sq = arith.mulf %sx, %sx : f32
    %c0_5 = arith.constant 5.000000e-01 : f32
    %cond = arith.cmpf ogt, %x, %c0_5 : f32
    cf.cond_br %cond, ^bb1, ^bb2
^bb1:
    %cx = math.cos %x : f32
    %cx_sq = arith.mulf %cx, %cx : f32
    %sum = arith.addf %sx_sq, %cx_sq : f32
    cf.br ^bb3(%sum : f32)
^bb2:
    %z = arith.constant 42.0 : f32
    cf.br ^bb3(%z : f32)
^bb3(%a: f32):
    func.return %a : f32
}
