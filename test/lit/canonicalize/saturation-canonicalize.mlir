// RUN: tamagoyaki-opt --test-generate-equivalence-expr=num-vars=2 \
// RUN:   "--test-saturation-canonicalize=patterns-file=%S/patterns.mlir" %s \
// RUN:   | FileCheck %s

// This exercises the test-only passes in test/lib/TestSaturationCanonicalize.cpp
// which are only available when tamagoyaki-opt is built with
// TAMAGOYAKI_INCLUDE_TESTS.
// REQUIRES: tamagoyaki-tests

// The input module is discarded and replaced by the generated expression.
module {}

// For two variables, intertwining canonicalization collapses the program in
// fewer rounds than saturation alone, and keeps the e-graph much smaller.

// CHECK: === saturation vs. canonicalization ===
// CHECK: variables: 2
// CHECK: flow A (saturation + canonicalization):
// CHECK: reduced to 1 after 2 round(s)
// CHECK: flow B (saturation only):
// CHECK: reduced to 1 after 3 round(s)
// CHECK: summary: intertwining canonicalization took 2 round(s) vs. 3 round(s) for saturation only
