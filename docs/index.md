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

Two case studies build on it -- floating-point accuracy in the spirit of
[Herbie](https://herbie.uwplse.org/), and datapath optimisation over
[CIRCT](https://circt.llvm.org/) -- and live in
[their own repository](https://github.com/jumerckx/tamagoyaki-case-studies),
so that the framework does not carry their dependencies.

```{toctree}
:hidden:
:maxdepth: 2
:caption: Guides

guides/index
```

```{toctree}
:hidden:
:maxdepth: 2
:caption: Dialects

dialects/index
```

```{toctree}
:hidden:
:maxdepth: 2
:caption: Reference

api/index
```
