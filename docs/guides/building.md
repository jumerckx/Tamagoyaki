# Building Tamagoyaki

:::{note}
If you're using **Nix** and have time to spare, all the tools can be built with `nix build`. This will build LLVM, MLIR, CIRCT, and Rival and finally produce `tamagoyaki-opt`, `herbie-mlir-opt`, `rover-mlir-opt`, and `cranelift-mlir-opt` in the `result` directory.
If you're not running on a beefy machine, this can easily take multiple hours. Once the initial build is done, subsequent builds should be faster due to dependencies living in the Nix' cache.
CI also builds the project using Nix.
:::


The Tamagoyaki core (`tamagoyaki-opt`) depends on MLIR. You can build it with:
```
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH=PATH_TO_MLIR_INSTALL_DIR \
  -BUILD_HERBIE_MLIR=OFF \
  -BUILD_ROVER_MLIR=OFF \
  -BUILD_CRANELIFT_MLIR=OFF \
  -B build \
  -S $PWD
ninja -C build
```

Running `ninja -C build check-all` will run the test suites for Tamagoyaki and all the enabled subprojects.

## Building Subprojects

For some of the existing Tamagoyaki subprojects, you need additional dependencies:

* **Herbie-MLIR**

[Herbie](https://herbie.uwplse.org) is a tool for automatically increasing the precision of floating point expressions.
We implemented Herbie's core optimization procedure in MLIR using Tamagoyaki.
When enabling Herbie-MLIR, you are expected to have a (sufficiently recent) Rust/Cargo toolchain available. The build process will pull, compile, and link against [Rival3](https://github.com/herbie-fp/rival3), an interval and arbitrary precision execution framework that's also used by the original Herbie project.

* **ROVER-MLIR**

[ROVER](https://arxiv.org/abs/2406.12421) is a tool for RTL optimization using equality saturation.
To build ROVER-MLIR, an implementation of the procedure in MLIR, you need an installation of [CIRCT](https://github.com/llvm/circt).
