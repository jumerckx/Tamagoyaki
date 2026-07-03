// Exercises the HiGHS integration behind the equivalence-select-ilp pass. Only
// runs when tamagoyaki is built with HiGHS support (TAMAGOYAKI_ENABLE_HIGHS=ON).
// REQUIRES: highs
// RUN: tamagoyaki-opt --equivalence-select-ilp %s | FileCheck %s

// CHECK: HiGHS {{[0-9]+\.[0-9]+\.[0-9]+}} solved ILP: objective = 1
func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %a = arith.muli %arg0, %arg0 : i32
    %c5 = arith.constant 5 : i32
    %k1 = equivalence.class %a, %c5 : i32
    equivalence.yield %k1 : i32
  }
  return %0 : i32
}
