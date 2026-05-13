# Tamagoyaki

**Tamagoyaki** is an [MLIR](https://mlir.llvm.org/)-based framework for encoding
e-graphs directly in IR, and running equality saturation. It builds on the
[`pdl` dialect](https://mlir.llvm.org/docs/Dialects/PDLOps/) for rewrite pattern
definitions.

::::{grid} 1 1 2 2
:gutter: 3
:margin: 4 4 0 0

:::{grid-item-card} 📖 Guides
:link: guides/index
:link-type: doc

Hand-written walkthroughs covering installation, the dialects, and how to write
new rewrite patterns.
:::

:::{grid-item-card} 🔧 API reference
:link: api/index
:link-type: doc

Auto-generated reference for the C++ MLIR dialects, extracted from header
comments via Doxygen.
:::

::::

## At a glance

Tamagoyaki ships two custom MLIR dialects:

- **`equivalence`** — represents e-graphs as IR with `equivalence.graph`,
  `equivalence.class`, and `equivalence.yield` operations.
- **`ematch`** — extends `pdl_interp` to perform e-matching for equality
  saturation, exposed via the `-ematch-saturate` and
  `-ematch-saturate-benchmark` passes.

The `herbie_mlir` subproject specializes the framework for
floating-point optimisation in the spirit of
[Herbie](https://herbie.uwplse.org/), wired up to the
[Rival 3](https://github.com/herbie-fp/rival3) interval-arithmetic library.

## Quick start

```shell
uv sync
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DPython3_EXECUTABLE=$(uv run which python) \
  -DCMAKE_PREFIX_PATH=$(uv run python -m mlir_wheel --root-dir) \
  -DLLVM_EXTERNAL_LIT=$(uv run which lit) \
  -B build -S $PWD
ninja -C build check-tamagoyaki
```

```{toctree}
:hidden:
:maxdepth: 2
:caption: Guides

guides/index
```

```{toctree}
:hidden:
:maxdepth: 2
:caption: Reference

api/index
```
