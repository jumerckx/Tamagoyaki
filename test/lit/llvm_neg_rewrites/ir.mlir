// RUN: tamagoyaki-opt -equivalence-insert-graph -ematch-saturate=patterns-file=%p/patterns.mlir %s | FileCheck %s

// Saturating with the two negation rewrites (see patterns.pdl.mlir):
//   -a - -b  ->  b - a         (introduces %6, an e-node of %4-%5's e-class)
//   -a + -b  ->  -(a - b)      (introduces 0 - (a - b), an e-node of %4+%5's e-class)

// CHECK:      llvm.func @foo(%arg0: i32, %arg1: i32) -> i32 {
// CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
// CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
// CHECK-NEXT:     %2 = equivalence.class %arg1 : i32
// CHECK-NEXT:     %3 = llvm.mlir.constant(0 : i32) : i32
// CHECK-NEXT:     %4 = llvm.sub %3, %1 : i32
// CHECK-NEXT:     %5 = llvm.sub %3, %2 : i32
// CHECK-NEXT:     %6 = llvm.sub %2, %1 : i32
// CHECK-NEXT:     %7 = llvm.sub %4, %5 : i32
// CHECK-NEXT:     %8 = equivalence.class %7, %6 : i32
// CHECK-NEXT:     %9 = llvm.sub %1, %2 : i32
// CHECK-NEXT:     %10 = llvm.sub %3, %9 : i32
// CHECK-NEXT:     %11 = llvm.add %4, %5 : i32
// CHECK-NEXT:     %12 = equivalence.class %11, %10 : i32
// CHECK-NEXT:     %13 = llvm.xor %8, %12 : i32
// CHECK-NEXT:     equivalence.yield %13 : i32
// CHECK-NEXT:   }
// CHECK-NEXT:   llvm.return %0 : i32
// CHECK-NEXT: }

module attributes {dlti.dl_spec = #dlti.dl_spec<!llvm.ptr = dense<64> : vector<4xi64>, i1 = dense<8> : vector<2xi64>, i8 = dense<8> : vector<2xi64>, i16 = dense<16> : vector<2xi64>, i32 = dense<32> : vector<2xi64>, i64 = dense<[32, 64]> : vector<2xi64>, f16 = dense<16> : vector<2xi64>, f64 = dense<64> : vector<2xi64>, f128 = dense<128> : vector<2xi64>, "dlti.endianness" = "little">, llvm.module_asm = [], llvm.target_triple = ""} {
  llvm.func @foo(%arg0: i32, %arg1: i32) -> i32 {
    %0 = llvm.mlir.constant(0 : i32) : i32
    %1 = llvm.sub %0, %arg0 : i32
    %2 = llvm.sub %0, %arg1 : i32
    %3 = llvm.sub %1, %2 : i32
    %4 = llvm.add %1, %2 : i32
    %5 = llvm.xor %3, %4 : i32
    llvm.return %5 : i32
  }
}
