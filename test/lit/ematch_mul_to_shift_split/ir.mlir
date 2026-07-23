// RUN: tamagoyaki-opt -ematch-saturate=patterns-file=%p/patterns.mlir %s -allow-unregistered-dialect | FileCheck %s

// CHECK:      func.func @graph_with_eqs(%arg0: i32) -> i32 {
// CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
// CHECK-NEXT:     %1 = equivalence.class %arg0 : i32
// CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
// CHECK-NEXT:     %2 = equivalence.class %c2_i32 : i32
// CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
// CHECK-NEXT:     %3 = arith.shli %1, %c1_i32 : i32
// CHECK-NEXT:     %4 = arith.muli %1, %2 : i32
// CHECK-NEXT:     %5 = "test.op"() : () -> i32
// CHECK-NEXT:     %6 = equivalence.class %5, %4, %3 : i32
// CHECK-NEXT:     equivalence.yield %6 : i32
// CHECK-NEXT:   }
// CHECK-NEXT:   return %0 : i32
// CHECK-NEXT: }

func.func @graph_with_eqs(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
        %1 = equivalence.class %arg0 : i32
        %c2_i32 = arith.constant 2 : i32
        %2 = equivalence.class %c2_i32 : i32
        %3 = arith.muli %1, %2 : i32
        %someotherval = "test.op"() : () -> (i32)
        %4 = equivalence.class %someotherval, %3 : i32
        equivalence.yield %4 : i32
    }
    return %0 : i32
}


// CHECK:      func.func @graph_without_eqs(%arg0: i32) -> i32 {
// CHECK-NEXT:   %0 = equivalence.graph -> (i32) {
// CHECK-NEXT:     %c2_i32 = arith.constant 2 : i32
// CHECK-NEXT:     %c1_i32 = arith.constant 1 : i32
// CHECK-NEXT:     %1 = arith.shli %arg0, %c1_i32 : i32
// CHECK-NEXT:     %2 = arith.muli %arg0, %c2_i32 : i32
// CHECK-NEXT:     %3 = equivalence.class %2, %1 : i32
// CHECK-NEXT:     equivalence.yield %3 : i32
// CHECK-NEXT:   }
// CHECK-NEXT:   return %0 : i32
// CHECK-NEXT: }
func.func @graph_without_eqs(%arg0: i32) -> i32 {
    %0 = equivalence.graph -> (i32) {
        %c2_i32 = arith.constant 2 : i32
        %3 = arith.muli %arg0, %c2_i32 : i32
        equivalence.yield %3 : i32
    }
    return %0 : i32
}
