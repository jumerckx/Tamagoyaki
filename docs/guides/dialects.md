# Dialects

Tamagoyaki ships two MLIR dialects.

## `equivalence`

The `equivalence` dialect provides core operations for representing and
manipulating e-graphs:

- **`equivalence.graph`** — defines a graph region: a single-block region
  containing unordered operations and equivalence classes.
- **`equivalence.class`** — represents an equivalence class containing a set of
  equivalent values.
- **`equivalence.yield`** — terminator operation for `equivalence.graph`
  regions.

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

## `ematch`

The `ematch` dialect extends the `pdl_interp` dialect to support e-matching for
equality saturation. It provides pattern matching and rewriting capabilities
built on the PDL (Pattern Description Language) infrastructure.

### Passes

- **`-ematch-saturate`** — applies pattern rewriting using equality saturation.
  This pass takes PDL-defined patterns and repeatedly applies matching and
  rewriting rules until a fixed point is reached.
- **`-ematch-saturate-benchmark`** — runs the saturation process N times for
  benchmarking and profiling. Each iteration clones the input IR to ensure
  fresh state.
