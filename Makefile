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
# To pass extra CMake configure flags (e.g. CMAKE_PREFIX_PATH for MLIR):
#   make eval-build CMAKE_EXTRA=-DCMAKE_PREFIX_PATH=/path/to/llvm/build

BUILD_DIR   ?= build-eval
CMAKE_EXTRA ?=

.PHONY: eval-build eval eval-clean

eval-build:
ifndef CMAKE_PREFIX_PATH
	$(error CMAKE_PREFIX_PATH is required (path to your LLVM/MLIR build). Set it via: make eval-build CMAKE_PREFIX_PATH=/path/to/llvm/build)
endif
	cmake --preset eval -DCMAKE_PREFIX_PATH=$(CMAKE_PREFIX_PATH) $(CMAKE_EXTRA)
	cmake --build --preset eval

eval: eval-build
	cd herbie_mlir/eval && \
		uv run snakemake -j1 --config build_dir=$(abspath $(BUILD_DIR))

eval-clean:
	rm -rf $(BUILD_DIR)
	cd herbie_mlir/eval && rm -rf out
