# Artifact Evaluation for E-Graphs as a Persistent Compiler Abstraction

Our paper contains two evaluations: one replicating Herbie (Sec. 5, Herbie), and one for a hardware design case study using CIRCT (Sec. 6, ROVER).

Our project, [Tamagoyaki](https://jumerckx.github.io/Tamagoyaki/guides/building.html), uses MLIR. But for these evaluations, additional dependencies are required.
We declare all dependencies in a Nix flake, allowing users to build the project in a reproducible environment and run the evaluations.
This nix flake will build MLIR, CIRCT, and more, which leads to long build times. For the evaluation specifically, we offer a Docker image that contains only the necessary dependencies.

## What you need

|              |                                                                              |
|--------------|------------------------------------------------------------------------------|
| Docker       | any recent version; Podman works too (`podman run` in place of `docker run`) |
| Architecture | `linux/amd64`                                                                |
| Download     | 1.3 GiB compressed                                                           |
| Disk         | 4.9 GiB for the loaded image, plus a few hundred MB of results               |
| Time         | ~5 minutes for both evaluations                                              |

## Running the evaluation

```shell
docker load --input tamagoyaki-eval-<rev>.tar.gz
mkdir -p results
docker run --rm -v "$PWD/results:/results" tamagoyaki-eval:<rev>
```

The container's default command--invoked when running `docker run`--is `make eval`, which runs both evaluations one after the other. Results land in
`results/herbie-eval-out/` and `results/rover-eval-out/` on the host.

Note: the docker container works fully offline so you can optionally pass `--network=none` to `docker run`.

Note: under *rootful* Docker the results come out
root-owned; add `--user "$(id -u):$(id -g)"` there, but not when rootless.

Both evaluations use [snakemake](https://snakemake.github.io) for workflow management. All the steps of the evaluations are declared in `herbie_mlir/eval/Snakefile` and `rover-mlir/eval/Snakefile`.

## Reading the output

Running the evaluation writes intermediate results and measurements to directories in `results/`. The files containing actual results are:

| file | what it is |
|---|---|
| `results/herbie-eval-out/10-evaluation.csv` | accuracies and timings, one row per benchmark |
| `results/herbie-eval-out/11-plots/` | the five figures, as PDF |
| `results/herbie-eval-out/12-provenance.txt` | commit, toolchain versions, parameters |
| `results/rover-eval-out/09-results.csv` | area, delay and e-graph time per benchmark × configuration |
| `results/rover-eval-out/10-table.tex` | the comparison table, best area/delay in bold |
| `results/rover-eval-out/11-egraph.csv` | e-classes and e-nodes per benchmark × configuration |
| `results/rover-eval-out/12-egraph-table.tex` | the e-graph size table, ratios against single-level |
| `results/rover-eval-out/13-provenance.txt` | as above, plus the cell library's hash |

## Interacting with the framework

```shell
docker run --rm -it -v "$PWD/results:/results" tamagoyaki-eval:<rev> bash
```

You land in `/work/Tamagoyaki`, a writable copy of the source tree that the
container materialises at startup. `herbie-eval` and `rover-eval` are on `PATH`
and take snakemake arguments directly, which is the way to run part of a
pipeline:

```shell
OUT_DIR=/results/herbie-eval-out herbie-eval --until saturation_timing_joint
OUT_DIR=/results/rover-eval-out rover-eval --until abc_map
```

Note `OUT_DIR`: the wrappers default it to a path *inside* `/work`, and it is the
`make` targets — via `HERBIE_OUT_DIR` and `ROVER_OUT_DIR` — that point it at the
mount. Bind-mounting `/work` instead of `/results` gives you the tree, the
snakemake logs and the results on the host together.

Furthermore, you can access the tools themselves as `tamagoyaki-opt`, `herbie-mlir-opt`, and`rover-mlir-opt`. These tools are MLIR opt-like tools (see pass options using `--help`).

## Rebuilding the image

(This should not be required for artifact evaluation itself.)

The image is built from the flake, so this needs Nix — but not a container
runtime:

```shell
nix run .#eval-image | docker load
nix run .#eval-image | gzip -9 > tamagoyaki-eval-$(git rev-parse --short HEAD).tar.gz
```

Build it from a clean checkout: the recorded revision comes from the flake's own
`self.rev`, which only exists when the tree has no local modifications. The
`Makefile` wraps both of these as `make docker-image` and `make docker-eval`.
