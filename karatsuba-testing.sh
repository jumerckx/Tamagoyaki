#! /usr/bin/bash

echo "With canonicalization:"
build/bin/tamagoyaki-opt test/lit/karatsuba/karatsuba_middle.mlir -equivalence-insert-graph "--test-saturation-canonicalize=patterns-file=test/lit/karatsuba/patterns.mlir rounds=10" -equivalence-graph-contains="patterns-file=test/lit/karatsuba/expected_middle.mlir" -debug-only=test-saturation-canonicalize -mlir-timing | head -n 30

echo "
Without canonicalization:"

build/bin/tamagoyaki-opt test/lit/karatsuba/karatsuba_middle.mlir -equivalence-insert-graph "--ematch-saturate=patterns-file=test/lit/karatsuba/patterns.mlir max-iters=10" -equivalence-graph-contains="patterns-file=test/lit/karatsuba/expected_middle.mlir" -debug-only=ematch -mlir-timing | head -n 10

# echo "With canonicalization: "
# build/bin/tamagoyaki-opt test/lit/karatsuba/karatsuba_middle.mlir -equivalence-insert-graph \
#     -ematch-saturate="patterns-file=test/lit/karatsuba/patterns.mlir max-iters=1" \
#     -equivalence-select-constants -equivalence-extract -canonicalize \
#     -ematch-saturate="patterns-file=test/lit/karatsuba/patterns.mlir max-iters=1" \
#     -equivalence-select-constants -equivalence-extract -canonicalize \
#     -ematch-saturate="patterns-file=test/lit/karatsuba/patterns.mlir max-iters=1" \
#     -equivalence-select-constants -equivalence-extract -canonicalize \
#     -ematch-saturate="patterns-file=test/lit/karatsuba/patterns.mlir max-iters=1" \
#     -equivalence-select-constants -equivalence-extract -canonicalize \
#     -equivalence-graph-contains="patterns-file=test/lit/karatsuba/expected_middle.mlir" | head -n 4

# echo "
# Without canonicalization: "
# build/bin/tamagoyaki-opt test/lit/karatsuba/karatsuba_middle.mlir -equivalence-insert-graph \
#     -ematch-saturate="patterns-file=test/lit/karatsuba/patterns.mlir max-iters=5" \
#     -equivalence-graph-contains="patterns-file=test/lit/karatsuba/expected_middle.mlir" | head -n 4
