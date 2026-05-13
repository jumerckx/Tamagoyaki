# Building Tamagoyaki

> [!NOTE]
> 
> If you're using **Nix** and have time to spare, all the tools can be built with `nix build`. This will build LLVM, MLIR, CIRCT, and Rival and finally produce tamagoyaki-opt, herbie-mlir-opt, rover-mlir-opt, and cranelift-mlir-opt in the `result` directory.
> If you're not running on a beefy machine, this can easily take multiple hours. Once the initial build is done, subsequent builds should be faster due to dependencies living in the Nix' cache.


The Tamagoyaki core (`tamagoyaki-opt`) depends on MLIR. You can build it with:
```
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH=PATH_TO_LLVM_INSTALL_DIR \
  -BUILD_HERBIE_MLIR=OFF \
  -BUILD_ROVER_MLIR=OFF \
  -BUILD_CRANELIFT_MLIR=OFF \
  -B build \
  -S $PWD
```
(or by passing llvm and mlir cmake directories through `-DLLVM_DIR`, `-DMLIR_DIR`)

For some of the existing Tamagoyaki subprojects, you need additional dependencies:

* **herbie-mlir**
test
