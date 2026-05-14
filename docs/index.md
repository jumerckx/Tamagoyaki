# Tamagoyaki

**Tamagoyaki** is an [MLIR](https://mlir.llvm.org/)-based framework for encoding
e-graphs directly in IR, and running equality saturation. It builds on the
[`pdl` dialect](https://mlir.llvm.org/docs/Dialects/PDLOps/) for rewrite pattern
definitions.

## At a glance

Tamagoyaki ships two custom MLIR dialects:

- **`equivalence`** — represents e-graphs as IR with `equivalence.graph`,
  `equivalence.class`, and `equivalence.yield` operations.
- **`ematch`** — extends `pdl_interp` to perform e-matching for equality
  saturation.

The `herbie_mlir` subproject specializes the framework for
floating-point optimisation in the spirit of
[Herbie](https://herbie.uwplse.org/), wired up to the
[Rival 3](https://github.com/herbie-fp/rival3) interval-arithmetic library.

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
