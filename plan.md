# `rover-mlir`: extending CIRCT out-of-tree

## Goal

Build `rover-mlir` as an out-of-tree MLIR project that defines its own dialects and passes operating on CIRCT IR (`comb`, `hw`, `datapath`), and ships them in two complementary forms from a single source tree:

- A **plugin** `.so` that stock `circt-opt` can `dlopen` via `--load-pass-plugin` / `--load-dialect-plugin`.
- A standalone **`rover-mlir-opt`** binary that registers MLIR + CIRCT + Rover dialects together.

Do **not** vendor or `FetchContent` CIRCT. Consume it via `find_package(CIRCT CONFIG)` against a pre-built install.

## Prerequisites

The agent must confirm three things exist before writing code:

1. An MLIR install with a locatable `MLIRConfig.cmake` (the user has one in a Python wheel under `mlir_wheel/lib/cmake/mlir`).
2. The matching `LLVMConfig.cmake`.
3. A CIRCT install built **against that exact MLIR/LLVM** with a `CIRCTConfig.cmake`. If absent, the agent should produce a small bootstrap script that clones a *pinned* CIRCT SHA, configures it with `-DMLIR_DIR=… -DLLVM_DIR=…` against the user's MLIR, and installs to a prefix — and ask the user to run it. The pinned SHA goes in a tracked file (e.g. `cmake/CIRCTRevision.txt`) and is documented in the README alongside the MLIR version it pairs with.

The agent must not try to build CIRCT inline as part of the project's own configure step.

## Architecture

Three logical pieces, organized however is conventional:

1. **A core library** containing the dialect(s) and pass(es). Built with `add_mlir_dialect_library`, links `MLIRIR`, `MLIRPass`, `CIRCTComb`, `CIRCTHW`, `CIRCTDatapath`, etc. This is where all real code lives.

2. **A plugin shim** — a tiny `.cpp` with only the two `extern "C"` entry points (`mlirGetPassPluginInfo`, `mlirGetDialectPluginInfo`), built as `add_llvm_library(... MODULE PLUGIN_TOOL circt-opt)`. It links **only** the core Rover library, not CIRCT directly. CIRCT symbols are resolved at runtime against the host `circt-opt` process.

3. **A standalone tool** — `rover-mlir-opt`, an `add_llvm_executable` that registers all MLIR dialects, all CIRCT dialects, and the Rover dialect, then calls `MlirOptMain`.

Both consumers (plugin and standalone tool) link the same core library. No logic is duplicated.

## Top-level CMake essentials

- `find_package(MLIR REQUIRED CONFIG)` and `find_package(CIRCT REQUIRED CONFIG)`. Both required, both loud on failure.
- Append `MLIR_CMAKE_DIR`, `LLVM_CMAKE_DIR`, and `CIRCT_CMAKE_DIR` to `CMAKE_MODULE_PATH` and `include(TableGen)`, `include(AddLLVM)`, `include(AddMLIR)`, `include(HandleLLVMOptions)`.
- Include dirs: `LLVM_INCLUDE_DIRS`, `MLIR_INCLUDE_DIRS`, `CIRCT_INCLUDE_DIRS`, the project's own `include/`, and the build-tree `include/` (for tablegen output).
- Options to toggle the standalone tool, the plugin, and tests independently. All on by default.

## Dialect and passes

Standard MLIR out-of-tree pattern, modeled on `mlir/examples/standalone`:

- TableGen-defined dialect with `cppNamespace = "::rover"`. List the CIRCT dialects you depend on in `dependentDialects` so they auto-load when Rover loads.
- TableGen-defined passes with their own `dependentDialects` (the CIRCT dialects + Rover) so the passes can be invoked from a fresh context.
- Generated headers via `add_mlir_dialect`, `mlir_tablegen`, `add_public_tablegen_target` — the same incantations any in-tree MLIR dialect uses.

Start with one trivial op and one no-op pass. Get the full build green end-to-end before writing real logic.

## The plugin entry point

The whole file is roughly:

```cpp
#include "mlir/Tools/Plugins/DialectPlugin.h"
#include "mlir/Tools/Plugins/PassPlugin.h"
#include "rover-mlir/Dialect/Rover/RoverDialect.h"
#include "rover-mlir/Transforms/Passes.h"

extern "C" LLVM_ATTRIBUTE_WEAK ::mlir::PassPluginLibraryInfo
mlirGetPassPluginInfo() {
  return {MLIR_PLUGIN_API_VERSION, "RoverMLIR", LLVM_VERSION_STRING,
          []() { ::rover::registerRoverPasses(); }};
}

extern "C" LLVM_ATTRIBUTE_WEAK ::mlir::DialectPluginLibraryInfo
mlirGetDialectPluginInfo() {
  return {MLIR_PLUGIN_API_VERSION, "RoverMLIR", LLVM_VERSION_STRING,
          [](::mlir::DialectRegistry *registry) {
            registry->insert<::rover::RoverDialect>();
          }};
}
```

CMake side:

```cmake
add_llvm_library(RoverPlugin
  MODULE
  RoverPlugin.cpp
  PLUGIN_TOOL circt-opt
  LINK_LIBS MLIRRoverDialect MLIRRoverTransforms)
```

`MODULE` and `PLUGIN_TOOL circt-opt` are both essential. `MODULE` makes it a dlopen target rather than a link target. `PLUGIN_TOOL` tells LLVM's CMake that the host process is `circt-opt` so symbols already in the host aren't duplicated into the plugin — this is what prevents TypeID mismatches at runtime.

## The standalone tool

A vanilla `MlirOptMain` driver:

```cpp
int main(int argc, char **argv) {
  mlir::DialectRegistry registry;
  mlir::registerAllDialects(registry);
  mlir::registerAllPasses();
  circt::registerAllDialects(registry);   // or per-dialect inserts if absent
  circt::registerAllPasses();
  registry.insert<rover::RoverDialect>();
  rover::registerRoverPasses();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "rover-mlir-opt\n", registry));
}
```

If the installed CIRCT doesn't expose `circt::registerAllDialects` / `registerAllPasses`, fall back to including the individual dialect headers and inserting them by hand.

## Verification

Before declaring done, the agent must confirm:

1. CMake configures cleanly with `-DMLIR_DIR=… -DLLVM_DIR=… -DCIRCT_DIR=…`.
2. The core Rover library builds.
3. `rover-mlir-opt` builds and `mlir_check_all_link_libraries` passes.
4. The plugin `.so` builds.
5. `rover-mlir-opt --help` lists the Rover pass.
6. `circt-opt --load-pass-plugin=…/RoverPlugin.so --help` lists the same pass.
7. A minimal lit test exercising the pass works through both `rover-mlir-opt` and through `circt-opt + RoverPlugin.so`.

## Pitfalls to actively avoid

1. **No `FetchContent` of CIRCT.** It pulls in the LLVM submodule and forces CIRCT into in-tree-monorepo build mode, which doesn't match this setup.
2. **Don't link CIRCT into the plugin.** Only link the core Rover library. CIRCT comes from the host process at load time. Direct linkage causes duplicated symbols and TypeID mismatches that look like "unknown dialect" errors.
3. **Don't omit `PLUGIN_TOOL circt-opt`** on the plugin's `add_llvm_library`. Same failure mode as above.
4. **Don't pin to `main`** anywhere. Always a SHA. Bumping MLIR requires bumping CIRCT in the same commit.
5. **Don't use `find_package(CIRCT QUIET)`.** Missing CIRCT must be a hard, loud error pointing at the bootstrap script.
6. **Don't re-register CIRCT dialects from inside the plugin.** Listing them in the Rover dialect's `dependentDialects` is the correct mechanism.
7. **C++ ABI flags must match the `circt-opt` build** — same libstdc++/libc++, same `_GLIBCXX_USE_CXX11_ABI`, same RTTI/exceptions settings. Document the host's flags if non-default.