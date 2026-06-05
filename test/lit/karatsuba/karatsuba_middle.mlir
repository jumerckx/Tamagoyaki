// REQUIRES: tamagoyaki-tests

// Run the core saturate-canonicalize loop (one round of saturation followed by
// select-constants / extract / canonicalize, repeated) on the Karatsuba middle
// term, then probe the resulting e-graph with equivalence-graph-contains to see
// whether the cross-term form (ah*bl)+(al*bh) -- matched by
// @CrossTermToKaratsuba -- has been discovered.
//
// Three rounds are not enough; the cross-term form only appears on the fourth.

// RUN: tamagoyaki-opt %s \
// RUN:   --equivalence-insert-graph \
// RUN:   "--test-saturation-canonicalize=patterns-file=%S/patterns.mlir rounds=3" \
// RUN:   "--equivalence-graph-contains=patterns-file=%S/expected_middle.mlir" \
// RUN:   | FileCheck --check-prefix=ROUNDS3 %s

// RUN: tamagoyaki-opt %s \
// RUN:   --equivalence-insert-graph \
// RUN:   "--test-saturation-canonicalize=patterns-file=%S/patterns.mlir rounds=4" \
// RUN:   "--equivalence-graph-contains=patterns-file=%S/expected_middle.mlir" \
// RUN:   | FileCheck --check-prefix=ROUNDS4 %s

// Without canonicalization, it takes 6 iterations:

// RUN: tamagoyaki-opt %s \
// RUN:   --equivalence-insert-graph \
// RUN:   "--ematch-saturate=patterns-file=%S/patterns.mlir max-iters=5" \
// RUN:   "--equivalence-graph-contains=patterns-file=%S/expected_middle.mlir" \
// RUN:   | FileCheck --check-prefix=ROUNDS5 %s

// RUN: tamagoyaki-opt %s \
// RUN:   --equivalence-insert-graph \
// RUN:   "--ematch-saturate=patterns-file=%S/patterns.mlir max-iters=6" \
// RUN:   "--equivalence-graph-contains=patterns-file=%S/expected_middle.mlir" \
// RUN:   | FileCheck --check-prefix=ROUNDS6 %s

func.func @karatsuba_middle(%ah: i8, %al: i8, %bh: i8, %bl: i8) -> i8 {
  %sum_a  = arith.addi %ah, %al : i8        // ah + al
  %sum_b  = arith.addi %bh, %bl : i8        // bh + bl
  %prod   = arith.muli %sum_a, %sum_b : i8  // (ah+al)*(bh+bl)
  %ah_bh  = arith.muli %ah, %bh : i8        // ah*bh
  %al_bl  = arith.muli %al, %bl : i8        // al*bl
  %t      = arith.subi %prod, %ah_bh : i8   // prod - ah*bh
  %result = arith.subi %t, %al_bl : i8      // ... - al*bl
  return %result : i8
}

// After 3 rounds the cross-term form has NOT been found yet.
// ROUNDS3: Pattern containment results:
// ROUNDS3:   @CrossTermToKaratsuba: not contained

// One more round discovers it.
// ROUNDS4: Pattern containment results:
// ROUNDS4:   @CrossTermToKaratsuba: contained


// Without canonicalization, the cross term is not found after 5 iterations:
// ROUNDS5: Pattern containment results:
// ROUNDS5:   @CrossTermToKaratsuba: not contained

// ROUNDS6: Pattern containment results:
// ROUNDS6:   @CrossTermToKaratsuba: contained
