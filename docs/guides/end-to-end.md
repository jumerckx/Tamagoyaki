# A Simple End-to-End Example


This guide goes over the hello world example of e-graphs: optimizing `(a * 2) / 2`.
This expression can be translated to MLIR IR:
```text
// input.mlir
func.func @example(%a: i32) -> (i32) {
  %two = arith.constant 2 : i32
  %mul = arith.muli %a, %two : i32
  %div = arith.divui %mul, %two : i32
  return %div : i32
}
```

:::{note}
TLDR:
```text
tamagoyaki-opt input.mlir \
  --equivalence-insert-graph \
  --ematch-saturate=patterns-file=pattern_pdl_interp.mlir \
  --equivalence-select-greedy=default-cost=1 \
  -equivalence-extract=remove-graphs=true
```
:::


## Inserting the Graph
Assuming you have succesfully built Tamagoyaki, we can convert this function body into an e-graph:
```sh
tamagoyaki-opt --equivalence-insert-graph input.mlir
```
```text
// graph.mlir
func.func @example(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %c2_i32 = arith.constant 2 : i32
    %1 = arith.muli %arg0, %c2_i32 : i32
    %2 = arith.divui %1, %c2_i32 : i32
    equivalence.yield %2 : i32
  }
  return %0 : i32
}
```
Note that as long as no equivalences are introduced in the IR, the operations remain unchanged, they are just moved into a graph operation.

:::{note}
While the graph operation is superfluous at this stage, it is required when running equality saturation. During rewriting, cycles can be introduced, these appear in IR as uses of a value before its defining operation. The graph operation contains an MLIR "graph region" which allows this.
:::

## Adding Rewrites
Tamagoyaki uses [`pdl`](https://mlir.llvm.org/docs/Dialects/PDLOps/) as a language for rewrites.
Take for example the rewrite `x * 2 --> x << 1`:
```text
// pattern.mlir
pdl.pattern : benefit(1) {
  %x = pdl.operand
  %type = pdl.type
  %two_attr = pdl.attribute = 2 : i32
  %two_op = pdl.operation "arith.constant" {"value" = %two_attr} -> (%type : !pdl.type)
  %two = pdl.result 0 of %two_op
  %mul_op = pdl.operation "arith.muli" (%x, %two : !pdl.value, !pdl.value) -> (%type : !pdl.type)
  pdl.rewrite %mul_op {
    %one_attr = pdl.attribute = 1 : i32
    %one_op = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
    %one = pdl.result 0 of %one_op
    %shl_op = pdl.operation "arith.shli" (%x, %one : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    %shl = pdl.result 0 of %shl_op
    pdl.replace %mul_op with (%shl : !pdl.value)
  }
}
```
:::{note}
`pdl` is verbose to write. Writing it by hand should be avoided.
The MLIR project also contains the PDLL language, which is higher-level language built on top of `pdl`.
For Tamagoyaki, we have also written custom python tools to convert rewrite rules in a different format to pdl, for example for Herbie-MLIR (`herbie_mlir/tools/herbie_pdl.py`).
:::

To execute `pdl` patterns, the IR first needs to be lowered to [`pdl_interp`](https://mlir.llvm.org/docs/Dialects/PDLInterpOps/).
MLIR has a pass `--convert-pdl-to-pdl-interp`, but that pass is (currently) unaware of the changes to matching logic that need to be made to achieve e-matching.
We have implemented a version of the pdl lowering procedure in [xDSL](https://xdsl.dev), a Python compiler framework that is compatible with MLIR:
```sh
xdsl-opt -p convert-pdl-to-pdl-interp{optimize_for_eqsat=true} pattern.mlir > pattern_pdl_interp.mlir
```
:::{note}
If you're using [`uv`](https://github.com/astral-sh/uv), you don't have to install `xdsl` explicitly and can instead run:
```sh
uv run --with=xdsl xdsl-opt ...
```
:::

## Saturating
To run equality saturation:
```sh
tamagoyaki-opt -ematch-saturate=patterns-file=pattern_pdl_interp.mlir graph.mlir
```
```text
// saturated.mlir
func.func @example(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %1 = arith.shli %arg0, %c1_i32 : i32
    %2 = arith.muli %arg0, %c2_i32 : i32
    %3 = equivalence.class %2, %1 : i32
    %4 = arith.divui %3, %c2_i32 : i32
    equivalence.yield %4 : i32
  }
  return %0 : i32
}
```
The equivalence is introduced: `%3` represents the e-class containing e-nodes `%2` and `%1`!

## Extraction
Extracting a final program from the graph happens in two steps: **selection** and **replacement**

### Selection
```sh
tamagoyaki-opt --equivalence-select-greedy=default-cost=1 saturated.mlir
```
```text
// selected.mlir
func.func @example(%arg0: i32) -> i32 {
  %0 = equivalence.graph -> (i32) {
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %1 = arith.shli %arg0, %c1_i32 : i32
    %2 = arith.muli %arg0, %c2_i32 : i32
    %3 = equivalence.class %2, %1 (min_cost_index = 0) : i32
    %4 = arith.divui %3, %c2_i32 : i32
    equivalence.yield %4 : i32
  }
  return %0 : i32
}
```
This pass has added `min_cost_index=0` to the e-class.
This indicates that the first operand of `class` should be selected.

Instead of using the same cost for each operation, it is possible to specify operation costs as attributes.
Try, for example, changing the shift and multiplication operations to:
```text
%1 = arith.shli %arg0, %c1_i32 {equivalence.cost = #equivalence.cost<2>} : i32
%2 = arith.muli %arg0, %c2_i32 {equivalence.cost = #equivalence.cost<3>} : i32
```
The `min_cost_index` now points to the shift operation.

:::{note}
Tamagoyaki expects users to bring their own cost model. It is also possible to write more complex cost functions by passing a `nodeCostFn` to `selectGreedy` when writing custom passes using Tamagoyaki's infrastructure.
:::

### Replacement
Finally, to extract the selected program from the graph, run:
```sh
tamagoyaki-opt -equivalence-extract=remove-graphs=true selected.mlir
```
```text
module {
  func.func @example(%arg0: i32) -> i32 {
    %c2_i32 = arith.constant 2 : i32
    %c1_i32 = arith.constant 1 : i32
    %0 = arith.muli %arg0, %c2_i32 : i32
    %1 = arith.divui %0, %c2_i32 : i32
    return %1 : i32
  }
}
```
