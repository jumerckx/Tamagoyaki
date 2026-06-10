# Reproducible evaluation build & run
# ====================================
#
# Prerequisites (provided automatically if using `nix develop`):
#   cmake, ninja, racket, cargo/rustc, the uv2nix Python env (lit, snakemake, ...)
#
# Usage:
#   make eval-build   # configure + build (into build-eval/)
#   make eval         # build, then run the full evaluation pipeline
#
# The build directory can be overridden:
#   make eval-build BUILD_DIR=build-eval-custom
#
# To pass extra CMake configure flags:
#   make eval-build CMAKE_EXTRA=-DFOO=bar
#
# MLIR/LLVM/CIRCT and the Python tooling come from the Nix dev shell, which
# exports CMAKE_PREFIX_PATH and LLVM_EXTERNAL_LIT (run `make` inside it).

BUILD_DIR   ?= build-eval
CMAKE_EXTRA ?=

# Pinned versions of external dependencies.
HERBIE_GIT_TAG ?= 5500c9684c044bdaca03aee415605f9ac2f05687
RIVAL_GIT_TAG  ?= 8bc5eca5079497a41d37e20a66c833080c92c0ed

# Inherit CMAKE_PREFIX_PATH from the dev shell; lit comes from the same env.
EXTERNAL_LIT := $(shell command -v lit)

.PHONY: eval-build eval eval-clean

eval-build:
	cmake -G Ninja -B $(BUILD_DIR) \
		-DCMAKE_BUILD_TYPE=Release \
		-DBUILD_HERBIE_MLIR=ON \
		-DBUILD_ROVER_MLIR=OFF \
		-DHERBIE_MLIR_BUILD_HERBIE=ON \
		-DRIVAL_LOCAL_PATH= \
		-DHERBIE_GIT_TAG=$(HERBIE_GIT_TAG) \
		-DRIVAL_GIT_TAG=$(RIVAL_GIT_TAG) \
		-DLLVM_EXTERNAL_LIT=$(EXTERNAL_LIT) \
		$(CMAKE_EXTRA)
	cmake --build $(BUILD_DIR)

eval: eval-build
	cd herbie_mlir/eval && \
		snakemake -j1 --config build_dir=$(abspath $(BUILD_DIR)) --forceall

eval-clean:
	rm -rf $(BUILD_DIR)
	cd herbie_mlir/eval && rm -rf out
