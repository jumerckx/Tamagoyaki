// Exercises the ILP extraction model behind equivalence-select-ilp. Only runs
// when tamagoyaki is built with HiGHS support (TAMAGOYAKI_ENABLE_HIGHS=ON).
// REQUIRES: highs
// RUN: tamagoyaki-opt "--equivalence-select-ilp=default-cost=1" %s | FileCheck %s --check-prefixes=SELECT,CYCLE,PRUNE
// RUN: tamagoyaki-opt "--equivalence-select-ilp=default-cost=1" %s | tamagoyaki-opt --equivalence-extract | FileCheck %s --check-prefix=EXTRACT

// Basic selection: the solver minimises summed local cost (shared sub-terms
// counted once) and records the choice as min_cost_index, so
// equivalence-extract consumes it exactly as it does the greedy selector's.
// The muli branch (muli, default cost 1) is cheaper than the shli branch (shli
// cost 2), so index 1 is selected.
// SELECT:      func.func @main
// SELECT:        equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 1) : i32

// EXTRACT:      func.func @main
// EXTRACT:        %{{.*}} = arith.muli
// EXTRACT-NOT:    arith.shli
// EXTRACT:        equivalence.yield
func.func @main(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %1 = arith.shli %arg0, %c1_i32 {equivalence.cost = #equivalence.cost<2>} : i32
    %2 = arith.muli %arg0, %c2_i32 : i32
    %3 = equivalence.class %1, %2 : i32
    equivalence.yield %3 : i32
  }
  return %0 : i32
}

// Acyclicity, root activation, and dead-class elimination. Selecting `f` for
// clsA and `g` for clsB would cost only 2, but forms a cycle clsA -> clsB ->
// clsA, forbidden by the level constraints. The exact solver therefore selects
// the acyclic leaf `la` (index 0, cost 10) for the root class clsA; clsB is
// never activated and gets no selection.
// CYCLE:      func.func @cyc
// CYCLE:        equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 0) : i32
// CYCLE-NEXT:   equivalence.class %{{.*}}, %{{.*}} : i32
func.func @cyc(%arg0: i32) -> i32 {
  %r = equivalence.graph -> (i32) {
    %la = arith.muli %arg0, %arg0 {equivalence.cost = #equivalence.cost<10>} : i32
    %lb = arith.muli %arg0, %arg0 {equivalence.cost = #equivalence.cost<20>} : i32
    %f = arith.addi %clsB, %arg0 {equivalence.cost = #equivalence.cost<1>} : i32
    %g = arith.subi %clsA, %arg0 {equivalence.cost = #equivalence.cost<1>} : i32
    %clsA = equivalence.class %la, %f : i32
    %clsB = equivalence.class %lb, %g : i32
    equivalence.yield %clsA : i32
  }
  return %r : i32
}

// Pruning (5g): marking the leaf `la` with equivalence.pruned removes it from
// consideration, so the root class must take the `f` branch (index 1), which
// activates clsB; clsB then selects the acyclic leaf `lb` (index 0).
// PRUNE:      func.func @prune
// PRUNE:        equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 1) : i32
// PRUNE-NEXT:   equivalence.class %{{.*}}, %{{.*}} (min_cost_index = 0) : i32
func.func @prune(%arg0: i32) -> i32 {
  %r = equivalence.graph -> (i32) {
    %la = arith.muli %arg0, %arg0 {equivalence.pruned, equivalence.cost = #equivalence.cost<10>} : i32
    %lb = arith.muli %arg0, %arg0 {equivalence.cost = #equivalence.cost<20>} : i32
    %f = arith.addi %clsB, %arg0 {equivalence.cost = #equivalence.cost<1>} : i32
    %g = arith.subi %clsA, %arg0 {equivalence.cost = #equivalence.cost<1>} : i32
    %clsA = equivalence.class %la, %f : i32
    %clsB = equivalence.class %lb, %g : i32
    equivalence.yield %clsA : i32
  }
  return %r : i32
}
