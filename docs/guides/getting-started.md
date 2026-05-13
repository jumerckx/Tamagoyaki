# Getting started

This page walks through configuring, building, and testing Tamagoyaki from a
fresh checkout.

## Prerequisites

Tamagoyaki uses [`uv`](https://docs.astral.sh/uv/) to manage Python dependencies
(including the [`mlir-wheel`](https://github.com/llvm/eudsl/tree/main/projects/mlir-wheel)
distribution of MLIR) and CMake + Ninja for the C++ build.

```shell
uv sync
uv run pre-commit install
```

## Configuring the build

```shell
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DPython3_EXECUTABLE=$(uv run which python) \
  -DCMAKE_PREFIX_PATH=$(uv run python -m mlir_wheel --root-dir) \
  -DLLVM_EXTERNAL_LIT=$(uv run which lit) \
  -B build \
  -S $PWD
```

:::{tip}
You can also link against a local MLIR build by replacing
`$(python -m mlir_wheel --root-dir)` with the path to your LLVM install
directory.
:::

## Running the test suite

```shell
ninja -C build check-tamagoyaki
```

To run every subproject test (Tamagoyaki, `herbie_mlir`, `rover-mlir`, and
`cranelift-mlir`):

```shell
ninja -C build check-all
```

## Next steps

- Read about the [dialects](dialects.md) Tamagoyaki ships.
- Learn how to [write rewrite patterns](writing-patterns.md) using PDL.
- Browse the [API reference](../api/index.md) for the C++ and Python APIs.
