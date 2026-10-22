# match dialect (out-of-tree copy)

This directory is a copy of the `match` dialect and the `pdl` -> `match` ->
`pdl_interp` lowering, which are proposed for upstream MLIR but not merged yet.
It lets Tamagoyaki use them against its pinned (upstream) LLVM. Once the dialect
lands upstream and the LLVM pin moves past it, this directory should be deleted
in favour of the upstream libraries.

## Provenance

Copied from `jumerckx/llvm-project`, branch `jm/match-cpp-benchmark`, commit
`9be7fe6ed156`. The directory layout mirrors `mlir/`:

| here | upstream |
|---|---|
| `include/mlir/Dialect/Match/` | the dialect and the `match-combine-matchers` pass |
| `include/mlir/Conversion/PDLToMatch/`, `lib/Conversion/PDLToMatch/` | `convert-pdl-to-match` |
| `include/mlir/Conversion/MatchToPDLInterp/`, `lib/Conversion/MatchToPDLInterp/` | `convert-match-to-pdl-interp` |
| `test/` | the corresponding lit tests |

Only the `pdl` -> `pdl_interp` flow is copied. Not copied:

* the match-to-C++ translation (`mlir/Target/MatchToCpp`, `mlir-match-to-cpp`)
  and its tests and benchmarks;
* the rewrite of `convert-pdl-to-pdl-interp` on top of the match dialect
  (`lib/Conversion/PDLToPDLInterp`). The pinned MLIR registers its own
  `convert-pdl-to-pdl-interp`, so the equivalent pipeline is
  `-convert-pdl-to-match -match-combine-matchers -convert-match-to-pdl-interp`;
* the `RootOrdering` unit test (`unittests/Conversion/PDLToMatch`);
* the `ByteCode.cpp` change that lets native rewrites return a null attribute.

## Local changes

* `include/mlir/Conversion/MatchConversionPasses.{td,h}` declare and register
  `convert-pdl-to-match` and `convert-match-to-pdl-interp`. Upstream they are in
  `mlir/Conversion/Passes.td`, which cannot be extended out of tree; the
  sources include `MatchConversionPasses.h.inc` instead of `Passes.h.inc`.
* `MatchOps.td`: `match.matcher` and `match.rewriter` drop the `SymbolName` and
  `SymbolVisibility` traits, which do not exist in the pinned MLIR. Its
  `SymbolOpInterface` still provides the default implementations they replace.
* The `match.rewriter` verifier only restricts the `match` and `pdl` ops in
  its body: ops of other dialects are allowed, so that a rewriter can hold ops
  that are lowered later (Tamagoyaki's `ematch` ops). Not upstream (yet).
* `match-combine-matchers` has a `defer-loops` option (`combineMatchers(...,
  deferLoops)`), not upstream (yet). It enters a `match.foreach` only after all
  predicates that do not depend on it, so that loops are nested under the
  checks of earlier loops instead of being hoisted above them. E-matching turns
  every navigation to a defining op into a loop over an e-class, and without
  this option the loops of a pattern multiply before any of their checks run.
* The CMake files are adapted to the out-of-tree build, and the tests run
  `tamagoyaki-opt` instead of `mlir-opt`. The `pdl`/`pdl_interp` negated
  constraints in the tests use the pinned MLIR's `{isNegated = true}` syntax,
  and the `PDLToPDLInterp` tests run the three-pass pipeline above.

## E-matching

The e-matching specific parts live in Tamagoyaki proper (`src/Ematchify.cpp`):
`-ematchify` rewrites the per-pattern matchers and rewriters to work on
e-classes, `-convert-ematch-to-match` lowers the ematch ops it puts in the
matchers to native calls after combining, and
`-ematch-convert-pdl-to-pdl-interp` runs the whole lowering.
