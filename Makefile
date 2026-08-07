# Reproducible evaluations
# ========================
#
# Thin wrappers around the `herbie-eval` and `rover-eval` commands provided by
# the Nix dev shell. Run them inside `nix develop` (which supplies cmake/ninja,
# racket, rust, abc, and the uv2nix Python env), or use `nix run .#herbie-eval`
# / `nix run .#rover-eval` directly instead.
#
# Usage:
#   make eval-build   # configure + build (into build-eval/), Herbie from source
#   make eval         # build, then run the full Herbie-MLIR pipeline
#   make rover-eval   # run the Rover datapath pipeline
#
# Overrides (forwarded via the environment):
#   make eval BUILD_DIR=build-eval-custom OUT_DIR=eval-out-custom CORES=4
#   make eval HERBIE_GIT_TAG=<sha>
#   make eval SNAKEMAKE_ARGS='-n'         # extra snakemake flags
#   make rover-eval ROVER_OUT_DIR=rover-out-custom ROVER_BUILD_DIR=build

BUILD_DIR      ?= build-eval
OUT_DIR        ?= eval-out
HERBIE_GIT_TAG ?= 5500c9684c044bdaca03aee415605f9ac2f05687
CORES          ?= 1
SNAKEMAKE_ARGS ?= --forceall

# The rover evaluation has its own build and output directories: BUILD_DIR is
# exported unconditionally below, and build-eval/ is a herbie-only tree with no
# rover-mlir-opt in it. Empty ROVER_BUILD_DIR means "use the Nix store path
# baked into rover-eval", which is the normal case -- set it to an in-tree
# build (e.g. `build`) to test a local compiler.
ROVER_BUILD_DIR ?=
ROVER_OUT_DIR   ?= rover-eval-out

export BUILD_DIR OUT_DIR HERBIE_GIT_TAG CORES

.PHONY: eval-build eval eval-clean rover-eval rover-eval-clean

eval-build:
	HERBIE_EVAL_BUILD_ONLY=1 herbie-eval

eval:
	herbie-eval $(SNAKEMAKE_ARGS)

eval-clean:
	rm -rf $(BUILD_DIR) $(OUT_DIR)

rover-eval: BUILD_DIR = $(ROVER_BUILD_DIR)
rover-eval: OUT_DIR = $(ROVER_OUT_DIR)
rover-eval:
	rover-eval $(SNAKEMAKE_ARGS)

rover-eval-clean:
	rm -rf $(ROVER_OUT_DIR)
