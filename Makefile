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
#   make herbie-eval   # just the Herbie-MLIR pipeline    -> herbie-eval-out/
#   make rover-eval    # just the Rover datapath pipeline -> rover-eval-out/
#   make eval-clean    # remove both output trees
#
# Overrides, forwarded to the wrappers as environment variables:
#   make eval CORES=4
#   make eval SNAKEMAKE_ARGS='-n'                 # dry run
#   make herbie-eval HERBIE_OUT_DIR=herbie-eval-out-alt
#   make rover-eval ROVER_BUILD_DIR=build         # measure a local compiler
#   EXTRA_CONFIG='max_iters=8' make rover-eval    # Snakefile parameters

CORES          ?= 1
SNAKEMAKE_ARGS ?= --forceall

HERBIE_BUILD_DIR ?=
HERBIE_OUT_DIR   ?= herbie-eval-out
ROVER_BUILD_DIR  ?=
ROVER_OUT_DIR    ?= rover-eval-out

.PHONY: eval herbie-eval rover-eval \
        eval-clean herbie-eval-clean rover-eval-clean \
        docker-image docker-eval

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

# The Docker artifact
# -------------------
#
# `nix run .#eval-image` writes the image tar to stdout, so loading it and
# shipping it are the same command with a different sink:
#
#   nix run .#eval-image | gzip -9 > tamagoyaki-eval-$(git rev-parse --short HEAD).tar.gz

DOCKER_IMAGE     ?= tamagoyaki-eval
DOCKER_IMAGE_TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dirty)
DOCKER_OUT_DIR   ?= docker-results

docker-image:
	nix run .#eval-image | docker load

# Whether to pass --user depends on how the daemon runs. Rootful docker maps
# the container's root to the host's, so without --user every result file comes
# out root-owned. Rootless docker (and podman) already map the invoking user to
# the container's root, so --user would land on an unrelated subuid and the
# mount stops being writable -- exactly backwards.
docker-eval:
	mkdir -p $(DOCKER_OUT_DIR)
	@if docker info -f '{{.SecurityOptions}}' 2>/dev/null | grep -q rootless; then \
	  user=; else user="--user $$(id -u):$$(id -g)"; fi; \
	set -x; docker run --rm --network=none $$user \
	  -v '$(abspath $(DOCKER_OUT_DIR)):/results' -e CORES='$(CORES)' \
	  $(DOCKER_IMAGE):$(DOCKER_IMAGE_TAG)
