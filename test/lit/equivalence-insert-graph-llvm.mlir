// RUN: tamagoyaki-opt -equivalence-insert-graph %s | FileCheck %s

// CHECK:      llvm.func @foo(%arg0: i32, %arg1: i32) -> i32 {
// CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
// CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
// CHECK-NEXT:     %2 = equivalence.class %arg1 : i32
// CHECK-NEXT:     %3 = llvm.mlir.constant(0 : i32) : i32
// CHECK-NEXT:     %4 = llvm.sub %3, %1 : i32
// CHECK-NEXT:     %5 = llvm.sub %3, %2 : i32
// CHECK-NEXT:     %6 = llvm.sub %4, %5 : i32
// CHECK-NEXT:     %7 = llvm.add %4, %5 : i32
// CHECK-NEXT:     %8 = llvm.xor %6, %7 : i32
// CHECK-NEXT:     equivalence.yield %8 : i32
// CHECK-NEXT:   }
// CHECK-NEXT:   llvm.return %0 : i32
// CHECK-NEXT: }

llvm.func @foo(%arg0: i32, %arg1: i32) -> i32 {
  %0 = llvm.mlir.constant(0 : i32) : i32
  %1 = llvm.sub %0, %arg0 : i32
  %2 = llvm.sub %0, %arg1 : i32
  %3 = llvm.sub %1, %2 : i32
  %4 = llvm.add %1, %2 : i32
  %5 = llvm.xor %3, %4 : i32
  llvm.return %5 : i32
}
