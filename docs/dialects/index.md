# Dialect reference

These pages are generated from the dialects' TableGen (`.td`) definitions by
`mlir-tblgen` (`-gen-dialect-doc` and `-gen-pass-doc`), the same source of
truth used to build the C++ implementation. They document each dialect's
operations, types, attributes, and the passes it provides.

Rebuild them from the TableGen sources with:

```console
$ cmake --build <build-dir> --target mlir-doc
```

The Sphinx build runs this target automatically when a configured CMake build
directory is available (see `TAMAGOYAKI_BUILD_DIR`).

```{toctree}
:maxdepth: 2

equivalence
ematch
herbie
cranelift
rover
```
