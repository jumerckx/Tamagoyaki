# Reproducible evaluations
# ========================
#
# Thin wrappers around the `herbie-eval` and `rover-eval` commands provided by
# the Nix dev shell. Run them inside `nix develop` (which supplies cmake/ninja,
# racket, rust, abc, and the uv2nix Python env), or use `nix run .#herbie-eval`
# / `nix run .#rover-eval` directly instead.
#
# Usage:
#   make eval          # both evaluations, one after the other
#   make herbie-eval   # just the Herbie-MLIR pipeline    -> eval-out/
#   make rover-eval    # just the Rover datapath pipeline -> rover-eval-out/
#   make eval-clean    # remove both output trees
#
# Overrides, forwarded to the wrappers as environment variables:
#   make eval CORES=4
#   make eval SNAKEMAKE_ARGS='-n'                 # dry run
#   make herbie-eval HERBIE_OUT_DIR=eval-out-alt
#   make rover-eval ROVER_BUILD_DIR=build         # measure a local compiler
#   EXTRA_CONFIG='max_iters=8' make rover-eval    # Snakefile parameters

CORES          ?= 1
SNAKEMAKE_ARGS ?= --forceall

HERBIE_BUILD_DIR ?=
HERBIE_OUT_DIR   ?= eval-out
ROVER_BUILD_DIR  ?=
ROVER_OUT_DIR    ?= rover-eval-out

.PHONY: eval herbie-eval rover-eval \
        eval-clean herbie-eval-clean rover-eval-clean

.NOTPARALLEL:
eval: herbie-eval rover-eval

herbie-eval:
	BUILD_DIR='$(HERBIE_BUILD_DIR)' OUT_DIR='$(HERBIE_OUT_DIR)' CORES='$(CORES)' \
	  herbie-eval $(SNAKEMAKE_ARGS)

rover-eval:
	BUILD_DIR='$(ROVER_BUILD_DIR)' OUT_DIR='$(ROVER_OUT_DIR)' CORES='$(CORES)' \
	  rover-eval $(SNAKEMAKE_ARGS)

herbie-eval-clean:
	rm -rf $(HERBIE_OUT_DIR)

rover-eval-clean:
	rm -rf $(ROVER_OUT_DIR)

eval-clean: herbie-eval-clean rover-eval-clean
