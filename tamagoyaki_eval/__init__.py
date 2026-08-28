"""Infrastructure shared by the Tamagoyaki evaluations.

Both pipelines (``herbie_mlir/eval`` and ``rover-mlir/eval``) are Snakemake
workflows of the same shape: turn a PDL rule set into a matcher, run
``*-mlir-opt`` over a benchmark corpus capturing IR and a timing report,
hand the result to a domain-specific backend, and reduce everything to one
tidy CSV plus a provenance manifest. What is genuinely common lives here:

  :mod:`tamagoyaki_eval.timing`      reading the timing JSON both opt tools emit
  :mod:`tamagoyaki_eval.provenance`  the manifest's shared environment prefix
  ``common.smk``                     the rules neither pipeline owns alone

Two consumers, resolved from two places
---------------------------------------

There is no editable install of this package: what lands in the environment is
a *copy* of the checkout, rebuilt only when Nix rebuilds the environment. So a
Snakefile read from the checkout paired with a module imported from the
environment is two versions of the same thing, and they drift apart the moment
either is edited -- an edit here does nothing until a rebuild, and after a
rebuild a stale shell sees a Snakefile calling something its copy lacks.

The split is therefore drawn where it does not hurt, at a stable boundary:

  *The workflow* -- the Snakefile, ``common.smk`` it includes, and the helpers
  they call -- is one unit, and all of it comes from the checkout. Snakemake
  already reads the main Snakefile from there, so the rest follows::

      sys.path.insert(0, str(REPO_ROOT))
      from tamagoyaki_eval import dir_resolver, provenance
      ...
      include: str(REPO_ROOT / "tamagoyaki_eval" / "common.smk")

  *The tools* -- ``herbie-pdl``, ``fpcore-mlir``, ``rover-results-csv`` and the
  rest -- stay installed, as they have always been. They are separate processes
  whose interface to the workflow is their command line, so an installed tool
  and a checkout Snakefile cannot disagree about a Python signature.

Rover's result-analysis tools live in :mod:`tamagoyaki_eval.rover` -- they are
here rather than under ``rover-mlir/eval`` only because ``rover-mlir`` has a
hyphen in it and cannot be a Python package; Herbie's equivalents sit in
``herbie_mlir/tools`` for the same reason in reverse.
"""

from __future__ import annotations

from pathlib import Path

__all__ = ["dir_resolver"]


def dir_resolver(repo_root: Path):
    """Return a function that interprets a config path against `repo_root`.

    Both pipelines take their directories from ``--config`` and want the same
    rule: absolute values are used as given, relative ones are resolved against
    the checkout root rather than the current directory, so that
    ``out_dir=herbie-eval-out`` means the same thing wherever snakemake was started.
    """

    def resolve(value) -> Path:
        path = Path(value)
        return path if path.is_absolute() else (repo_root / path).resolve()

    return resolve
