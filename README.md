<p align="center" width="100%">
    <img src="tamagoyaki.png" width="200" />
</p>

# Tamagoyaki

[![Nightly Test](https://github.com/jumerckx/tamagoyaki/actions/workflows/test.yml/badge.svg)](https://github.com/jumerckx/tamagoyaki/actions/workflows/test.yml)

Tamagoyaki is an MLIR-based framework for encoding e-graphs directly in IR, and running equality saturation.
It builds on the [`pdl` dialect](https://mlir.llvm.org/docs/Dialects/PDLOps/) for rewrite pattern definitions.

## Dialects

### `equivalence` Dialect

The `equivalence` dialect provides core operations for representing and manipulating e-graphs:

- **`equivalence.graph`**: Defines a graph region—a single-block region containing unordered operations and equivalence classes
- **`equivalence.class`**: Represents an equivalence class containing a set of equivalent values
- **`equivalence.yield`**: Terminator operation for `equivalence.graph` regions

Example:

```mlir
func.func @main(%a: i32) -> (i32) {
  %res = equivalence.graph -> (i32) {
    %one = arith.constant 1 : i32
    %two = arith.constant 2 : i32
    
    %mul = arith.muli %a, %two
    %shift = arith.shli %a, %one : i32
    // `a << 1` is equivalent to `a * 2`
    %result = equivalence.class %mul, %shift : i32
    
    equivalence.yield %result : i32
  }
  return %res: i32
}
```

### `ematch` Dialect

The `ematch` dialect extends the `pdl_interp` dialect to support e-matching for equality saturation. It provides pattern matching and rewriting capabilities built on the PDL (Pattern Description Language) infrastructure.

#### Passes

- **`-ematch-saturate`**: Applies pattern rewriting to the program using equality saturation. This pass takes PDL-defined patterns and repeatedly applies matching and rewriting rules until a fixed point is reached (saturation), ensuring all possible equivalent expressions are explored.

- **`-ematch-saturate-benchmark`**: Runs the equality saturation process N times for benchmarking and profiling. Each iteration clones the input IR to ensure fresh state, making it useful for performance analysis and optimization validation.

- **`-equivalence-graph-contains`**: Reports, for each pattern in a `pdl_interp` patterns module (via `patterns-file=...` or nested `@patterns`/`@ir` submodules), whether it is *contained* in the e-graph — i.e. whether the pattern matches with its root in the e-class of a value returned by an `equivalence.yield`. Rather than rewriting, the pass replaces every `pdl_interp.record_match` with a custom constraint that registers the match and its operands, then runs the matcher once over the graph. Patterns can use the `ematch.is_arg` operation to pin operands to specific block arguments, fully grounding the query (e.g. "is `a * 2` for argument `a` present?" rather than "is some `x * 2` present?").

## Herbie-MLIR

The `herbie-mlir` subproject extends Tamagoyaki with floating-point expression optimization inspired by [Herbie](https://herbie.uwplse.org/). The goal is to use equality saturation with the `ematch` dialect to explore equivalent floating-point expressions and select those with improved numerical accuracy or performance characteristics.

The subproject includes the `herbie-mlir-opt` tool, which combines the `equivalence` and `ematch` dialects with specialized patterns for floating-point arithmetic transformations. This tool builds on the MLIR infrastructure and the [Rival 3](https://github.com/herbie-fp/rival3) arbitrary-precision interval arithmetic library.


## Building

### Prerequisites

The project builds against a local MLIR/LLVM (and CIRCT) build supplied by the
Nix flake, so the only host requirement is [Nix](https://nixos.org/) with flakes
enabled. Enter the development shell — which provides the toolchain, a pinned
LLVM/MLIR + CIRCT, and the full Python environment (xdsl, snakemake, lit,
pre-commit, plotting and docs deps), all built from `pyproject.toml` + `uv.lock`
via [uv2nix](https://github.com/pyproject-nix/uv2nix):

```shell
nix develop          # release toolchain; use `nix develop .#debug` for assertions
pre-commit install
```

The shell exports `CMAKE_PREFIX_PATH` (LLVM/MLIR/CIRCT) and `LLVM_EXTERNAL_LIT`
automatically. `uv` is still available for lockfile maintenance (`uv lock`), but
the Python environment itself comes from Nix.

### CMake Configuration

Configure with the helper that picks up the shell's environment:

```shell
tamagoyaki-configure build      # cmake -G Ninja -B build with the right flags
```

### Running Tests

Build and run the test suite:

```shell
ninja -C build check-tamagoyaki   # or `check-all`
```

## About

This project's build configuration is based on [Max Levental](https://makslevental.github.io/about/)'s [mmlir](https://github.com/makslevental/mmlir) example repository.
