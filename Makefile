# Reproducible Herbie-MLIR evaluation
# ====================================
#
# Thin wrappers around the `herbie-eval` command provided by the Nix dev shell.
# Run them inside `nix develop` (which supplies cmake/ninja, racket, rust, and
# the uv2nix Python env), or use `nix run .#herbie-eval` directly instead.
#
# Usage:
#   make eval-build   # configure + build (into build-eval/), Herbie from source
#   make eval         # build, then run the full evaluation pipeline
#
# Overrides (forwarded to herbie-eval via the environment):
#   make eval BUILD_DIR=build-eval-custom HERBIE_GIT_TAG=<sha> CORES=4
#   make eval SNAKEMAKE_ARGS='-n'         # extra snakemake flags

BUILD_DIR      ?= build-eval
HERBIE_GIT_TAG ?= 5500c9684c044bdaca03aee415605f9ac2f05687
CORES          ?= 1
SNAKEMAKE_ARGS ?= --forceall

export BUILD_DIR HERBIE_GIT_TAG CORES

.PHONY: eval-build eval eval-clean

eval-build:
	HERBIE_EVAL_BUILD_ONLY=1 herbie-eval

eval:
	herbie-eval $(SNAKEMAKE_ARGS)

eval-clean:
	rm -rf $(BUILD_DIR)
	cd herbie_mlir/eval && rm -rf out
