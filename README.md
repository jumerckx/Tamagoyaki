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

## Herbie-MLIR Evaluation

The full Herbie-MLIR evaluation (Snakemake pipeline in
[`herbie_mlir/eval/Snakefile`](herbie_mlir/eval/Snakefile)) is wrapped by a
single reproducible command. It configures and builds an evaluation tree with
Herbie compiled from a pinned source revision — so `racket -l herbie report`
runs against a known Herbie — and then runs the pipeline (fpcore → MLIR →
equality saturation → fpcore → Herbie report → plots):

```shell
nix run .#herbie-eval         # from a checkout; builds + runs end-to-end
```

or, from inside the dev shell:

```shell
nix develop
herbie-eval                   # same thing; extra args pass through to snakemake
herbie-eval -n                # dry-run the pipeline
```

Knobs are environment variables: `BUILD_DIR` (default `build-eval`), `OUT_DIR`
(default `eval-out`, relative to the repo root), `HERBIE_GIT_TAG`, `CORES`
(default `1`), and `HERBIE_EVAL_BUILD_ONLY=1` to stop after the build. The
`make eval` / `make eval-build` targets wrap the same command.

Outputs land in `eval-out/` at the top level of the checkout. Each generated
directory and file is prefixed with its pipeline stage, so the tree reads in
execution order:

```
eval-out/
  01-rules/               PDL and PDL-interp rule sets
  02-mlir/                benchmarks lowered from FPCore to MLIR
  03-optimized/           after equality saturation
  04-optimize_timing/     per-benchmark wall clock for the above
  05-saturation_timing/   joint vs. individual matcher timings
  06-optimized_fpcore/    optimized MLIR back to FPCore
  07-fpcore_merged/       original + optimized alternative per benchmark
  08-herbie_input.fpcore  all merged benchmarks, concatenated
  09-herbie_eval/         Herbie report
  10-evaluation.csv       accuracies + timings extracted from the report
  11-plots/               the five figures
  12-provenance.txt       commit, toolchain versions, parameters
  13-paper-artifact/      figures + CSV + manifest (and .tar.gz alongside)
```

The paper artifact is not built by default; ask for it with `herbie-eval paper`.

## Rover Datapath Evaluation

The Rover evaluation (Snakemake pipeline in
[`rover-mlir/eval/Snakefile`](rover-mlir/eval/Snakefile)) compares four
configurations of the same five datapath circuits on ASAP7-mapped area and
delay, plus the wall clock the e-graph cost:

| configuration | pipeline |
|---|---|
| `baseline` | `circt-synth` on the input as written — no e-graph |
| `rover` | saturate with the base rewrites (comb/hw only), extract |
| `multi` | saturate with base + datapath rewrites, extract |
| `multi-persist` | as `multi`, but run `--canonicalize` and `--comb-int-range-narrowing` over the *persisted e-graph* before extracting |

Every configuration goes through the same backend — `circt-synth` →
`circt-translate --export-aiger` → `abc` technology mapping — so only the input
IR differs.

```shell
nix run .#rover-eval          # from a checkout; builds + runs end-to-end
```

or, from inside the dev shell:

```shell
nix develop
rover-eval                    # same thing; extra args pass through to snakemake
rover-eval -n                 # dry-run the pipeline
```

Knobs are environment variables: `BUILD_DIR` (defaults to the Nix-built
`tamagoyaki-rover-eval`; point it at an in-tree `build` to test a local
compiler), `OUT_DIR` (default `rover-eval-out`, relative to the repo root),
`CIRCT_BIN`, `ABC`, `CORES` (default `1`), and `EXTRA_CONFIG` for Snakefile
parameters, e.g.:

```shell
EXTRA_CONFIG='max_iters=8 synth_until=mapping' rover-eval
EXTRA_CONFIG='genlib=/path/to/other.genlib' rover-eval
```

`make rover-eval` / `make rover-eval-clean` wrap the same command.

Inputs: the benchmarks are plain `hw.module` in
[`rover-mlir/eval/benchmarks/`](rover-mlir/eval/benchmarks) (the e-graph comes
from `--rover-insert-graph`, and the lit suite drives these same files), the
rewrite rules are [`rover-mlir/rules/`](rover-mlir/rules) — `rewrites_base.mlir`
alone for `rover`, concatenated with `rewrites_datapath.mlir` for the rest — and
the cell library is a vendored ASAP7 `genlib`, see
[`rover-mlir/eval/lib/README.md`](rover-mlir/eval/lib/README.md) for its
provenance and the citation it requires.

Outputs land in `rover-eval-out/`, stage-prefixed like the Herbie tree:

```
rover-eval-out/
  01-rules/               base and full rule sets, PDL and PDL-interp
  02-input/               benchmarks as fed to the pipeline
  03-egraph/              persisted e-graph, before and after the CIRCT passes
  04-extracted/           per-configuration IR handed to the backend
  05-timing/              saturation (and, for multi-persist, CIRCT pass) times
  06-synth/               circt-synth output
  07-aiger/               AIGER netlists
  08-abc/                 raw abc print_stats reports
  09-results.csv          area, delay and e-graph time per benchmark+config
  10-table.tex            the comparison table, best area/delay in bold
  11-provenance.txt       commit, toolchain versions, genlib hash, parameters
  12-paper-artifact/      table + CSV + manifest (and .tar.gz alongside)
```

The paper artifact is not built by default; ask for it with `rover-eval paper`.

## Shared Evaluation Infrastructure

The two pipelines are the same skeleton with different payloads -- rule set to
matcher, opt tool over a benchmark corpus capturing IR and a timing report,
domain-specific backend, one tidy CSV, a provenance manifest -- so what they
have in common lives in [`tamagoyaki_eval/`](tamagoyaki_eval):

| | |
|---|---|
| `timing.py` | reading the JSON that `-tamagoyaki-timing` and `-mlir-timing` emit |
| `provenance.py` | the manifest's shared environment block |
| `common.smk` | the PDL-to-PDL-interp rules, the paper artifact, `clean` |
| `rover/` | Rover's result tools, as console scripts (`rover-results-csv`, ...) |

Each Snakefile includes `common.smk` from the checkout at its bottom, where
everything the workflow defines is already in scope. The `mkEval` function in
[`flake.nix`](flake.nix) builds both wrappers, so a third evaluation needs a
Snakefile of its own stages and little else.

## About

This project's build configuration is based on [Max Levental](https://makslevental.github.io/about/)'s [mmlir](https://github.com/makslevental/mmlir) example repository.
