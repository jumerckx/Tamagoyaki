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

# Derive CMAKE_PREFIX_PATH and tool paths from the uv-managed venv.
MLIR_PREFIX  := $(shell uv run python -m mlir_wheel --root-dir)
EXTERNAL_LIT := $(shell uv run which lit)

.PHONY: eval-build eval eval-clean

eval-build:
	cmake --preset eval -DCMAKE_PREFIX_PATH=$(MLIR_PREFIX) -DLLVM_EXTERNAL_LIT=$(EXTERNAL_LIT) $(CMAKE_EXTRA)
	cmake --build --preset eval

eval: eval-build
	cd herbie_mlir/eval && \
		uv run snakemake -j1 --config build_dir=$(abspath $(BUILD_DIR))

eval-clean:
	rm -rf $(BUILD_DIR)
	cd herbie_mlir/eval && rm -rf out
