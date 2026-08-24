"""Infrastructure shared by the Tamagoyaki evaluations.

Both pipelines (``herbie_mlir/eval`` and ``rover-mlir/eval``) are Snakemake
workflows of the same shape: turn a PDL rule set into a matcher, run
``*-mlir-opt`` over a benchmark corpus capturing IR and a timing report,
hand the result to a domain-specific backend, and reduce everything to one
tidy CSV plus a provenance manifest. What is genuinely common lives here:

  :mod:`tamagoyaki_eval.timing`      reading the timing JSON both opt tools emit
  :mod:`tamagoyaki_eval.provenance`  the manifest's shared environment prefix
  ``common.smk``                     the rules neither pipeline owns alone

``common.smk`` is part of a workflow rather than an importable module, and each
Snakefile includes it by checkout path::

    include: str(REPO_ROOT / "tamagoyaki_eval" / "common.smk")

not from wherever this package is installed. The wrappers already run the
pipelines out of a checkout -- the main Snakefile, the rule sources and the
benchmarks all come from there -- so a fragment of the same workflow has to as
well, or editing it would have no effect until the environment was rebuilt.

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
    ``out_dir=eval-out`` means the same thing wherever snakemake was started.
    """

    def resolve(value) -> Path:
        path = Path(value)
        return path if path.is_absolute() else (repo_root / path).resolve()

    return resolve
