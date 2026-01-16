# herbie-mlir

Implementation of [Herbie's](https://herbie.uwplse.org/) core in MLIR that leverages the Tamagoyaki e-graph dialect and integrates interval arithmetic via [Rival](https://github.com/herbie-fp/rival-rs).

## Architecture

```
herbie-mlir/
├── include/          # Public headers
│   ├── HerbieMLIR.h  # Main MLIR passes and utilities
│   └── RivalCAPI.h   # C API declarations for Rival
├── src/              # Implementation
│   └── HerbieMLIRPasses.cpp
└── rival/            # Rival C library integration
    └── CMakeLists.txt
```

## Building

### Standard build (pulls Rival from GitHub)

```bash
cd /path/to/tamagoyaki
cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=$PWD/mlir
cd build
ninja
```

The build automatically:
1. Fetches rival-rs from GitHub (specified tag/branch)
2. Builds the C API library via Cargo
3. Links it into herbie-mlir targets

### Development mode (local Rival)

For active development on Rival, use your local checkout:

```bash
cmake -B build \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_PREFIX_PATH=$PWD/mlir \
  -DRIVAL_ENABLE_LOCAL_DEV=ON \
  -DRIVAL_LOCAL_PATH=/path/to/rival-rs
cd build
ninja
```

Incremental cargo rebuilds automatically pick up changes to Rival source.

### Customization

Configure at CMake time:

```bash
# Use a specific Rival commit/tag
-DRIVAL_GIT_TAG=v0.2.0

# Use a different Rival fork
-DRIVAL_REPO_URL=https://github.com/your-fork/rival-rs.git

# Disable herbie-mlir in main build
-DBUILD_HERBIE_MLIR=OFF
```

## Development Workflow

### 1. Adding new MLIR passes

Create your pass in `src/` and declare it in `include/CMakeLists.txt` using TableGen:

```tablegen
def HerbieMyPass : Pass<"herbie-my-pass", "::mlir::ModuleOp"> {
  let summary = "My transformation pass";
  let dependentDialects = ["::mlir::tama::TamaDialect"];
}
```

### 2. Using Rival from C++

```cpp
#include "herbie-mlir/RivalCAPI.h"

// Create context
RivalContext* ctx = rival_context_new();

// Create rationals
RivalRational* lower = rival_rational_new(ctx, 0, 1);
RivalRational* upper = rival_rational_new(ctx, 1, 1);

// Create interval
RivalInterval* interval = rival_interval_from_rationals(ctx, lower, upper);

// Use interval
const char* str = rival_interval_to_string(interval);
printf("Interval: %s\n", str);

// Cleanup
rival_interval_free(interval);
rival_rational_free(lower);
rival_rational_free(upper);
rival_context_free(ctx);
```

### 3. Debugging Cargo builds

If Cargo build fails, check the full output:

```bash
cd build
# View build log
cat rival/CMakeFiles/buildRival.dir/build.log

# Or rebuild with verbose output
CARGO_VERBOSE=1 ninja -v buildRival
```

## Testing

Tests follow the Lit framework (same as tamagoyaki):

```bash
cd build
ninja check-herbie-mlir  # Run herbie-mlir specific tests
```

Create tests in `test/lit/*.mlir`.

## Integration with Tamagoyaki

herbie-mlir builds on top of:
- **Tamagoyaki dialects**: `tama.eq`, `tama.egraph`, `tama.yield`
- **Tamagoyaki passes**: `-tama-insert-egraph`, etc.
- **Core utilities**: Union-find, pattern rewriting, e-graph data structures

Example: Use tamagoyaki e-graphs with Rival interval semantics:

```mlir
func.func @analyze(%arg0: f32) -> f32 {
  %0:2 = tama.egraph %arg0 : f32 -> f32, f32 {
  ^bb0(%arg1: f32):
    // E-graph region with equivalence classes
    %eq = tama.eq %arg1 : f32
    
    // Apply Rival interval analysis here
    // to validate transformations
    
    tama.yield %eq, %eq : f32, f32
  }
  return %0#0 : f32
}
```

## Directory Layout

```
herbie-mlir/
├── CMakeLists.txt          # Subproject root
├── README.md               # This file
├── include/
│   ├── CMakeLists.txt
│   ├── HerbieMLIR.h        # Main header
│   └── RivalCAPI.h         # Rival C API declarations
├── src/
│   ├── CMakeLists.txt
│   ├── HerbieMLIRPasses.cpp
│   └── ...                 # Additional implementations
├── rival/
│   └── CMakeLists.txt      # Cargo + FetchContent orchestration
├── test/
│   └── lit/
│       └── *.mlir          # Lit tests
└── tools/
    └── herbie-mlir-opt.cpp # Optional: optimizer driver
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Cargo not found | Install Rust: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Network timeout fetching Rival | Use local mode: `-DRIVAL_ENABLE_LOCAL_DEV=ON` |
| CMake can't find MLIR | Set `-DCMAKE_PREFIX_PATH=$PWD/mlir` or ensure `MLIRConfig.cmake` is in PATH |
| Incremental Cargo rebuild slow | This is normal for first build; subsequent rebuilds are fast |

## Contributing

When adding new features:

1. Update `include/HerbieMLIR.h` with public APIs
2. Implement in `src/`
3. Add Lit tests in `test/lit/`
4. Update this README

## License

Inherits licenses from:
- Tamagoyaki (TBD)
- Rival (MIT)
