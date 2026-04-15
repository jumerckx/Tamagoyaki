# Reproducible evaluation build & run
# ====================================
#
# Prerequisites (provided automatically if using `nix develop`):
#   cmake, ninja, racket, cargo/rustc, uv
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
# MLIR/LLVM is obtained automatically from the mlir-wheel Python package.

BUILD_DIR   ?= build-eval
CMAKE_EXTRA ?=

# Pinned versions of external dependencies.
HERBIE_GIT_TAG ?= 5500c9684c044bdaca03aee415605f9ac2f05687
RIVAL_GIT_TAG  ?= 8bc5eca5079497a41d37e20a66c833080c92c0ed

# Derive CMAKE_PREFIX_PATH and tool paths from the uv-managed venv.
MLIR_PREFIX  := $(shell uv run python -m mlir_wheel --root-dir)
EXTERNAL_LIT := $(shell uv run which lit)

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
		-DCMAKE_PREFIX_PATH=$(MLIR_PREFIX) \
		-DLLVM_EXTERNAL_LIT=$(EXTERNAL_LIT) \
		$(CMAKE_EXTRA)
	cmake --build $(BUILD_DIR)

eval: eval-build
	cd herbie_mlir/eval && \
		uv run snakemake -j1 --config build_dir=$(abspath $(BUILD_DIR)) --forceall

eval-clean:
	rm -rf $(BUILD_DIR)
	cd herbie_mlir/eval && rm -rf out
