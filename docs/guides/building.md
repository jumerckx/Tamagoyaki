# Building Tamagoyaki

:::{note}
If you're using **Nix** and have time to spare, everything can be built with `nix build`. This will build LLVM and MLIR and finally produce `tamagoyaki-opt` and `cranelift-mlir-opt` in the `result` directory.
If you're not running on a beefy machine, this can easily take multiple hours. Once the initial build is done, subsequent builds should be faster due to dependencies living in the Nix' cache.
CI also builds the project using Nix.
:::


The Tamagoyaki core (`tamagoyaki-opt`) depends on MLIR. You can build it with:
```
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH=PATH_TO_MLIR_INSTALL_DIR \
  -DBUILD_CRANELIFT_MLIR=OFF \
  -B build \
  -S $PWD
ninja -C build
```

Running `ninja -C build check-all` will run the test suites for Tamagoyaki and all the enabled subprojects.

## The case studies

The two case studies -- Herbie-MLIR (floating-point accuracy, needing Rust and
[Rival 3](https://github.com/herbie-fp/rival3)) and ROVER-MLIR (RTL
optimisation, needing [CIRCT](https://github.com/llvm/circt)) -- are built from
[their own repository](https://github.com/jumerckx/tamagoyaki-case-studies),
which pins the Tamagoyaki it was tested against. See its README for the build.

## Building against Tamagoyaki

A project of your own consumes Tamagoyaki through its exported CMake package:

```cmake
find_package(MLIR REQUIRED CONFIG)
find_package(Tamagoyaki REQUIRED CONFIG)

target_link_libraries(my-opt PRIVATE MLIREquivalence MLIREmatch)
```

Configure it with `-DCMAKE_PREFIX_PATH=<prefix>`, where `<prefix>` is either an
install prefix (`cmake --install build --prefix ...`) or a Tamagoyaki build
directory -- both export a config, so the inner loop against a local checkout
needs no install step.
The config finds MLIR and HiGHS itself, defaulting to the ones Tamagoyaki was
compiled against, and provides
`add_dialect_tablegen()` for your own dialect's TableGen and
`TAMAGOYAKI_TOOLS_DIR` for locating `tamagoyaki-opt`.

`cranelift-mlir` in the Tamagoyaki repository is the worked example: it builds
both as a subdirectory and as its own top-level project, and CI does the latter
on every change.
