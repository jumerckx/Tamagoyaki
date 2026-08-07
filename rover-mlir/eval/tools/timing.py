"""Read wall-clock durations out of a timing report.

Both timing writers the evaluation uses emit the same JSON schema to stderr:

  * ``rover-mlir-opt -tamagoyaki-timing -tamagoyaki-timing-output=json``
    (scopes inside the rover passes: ``runSaturation``, ``rebuild``, ...)
  * ``rover-mlir-opt -mlir-timing -mlir-output-format=json``
    (MLIR pass manager: ``CanonicalizerPass``, ``CombIntRangeNarrowing``, ...)

Both write to *stderr* and both would write to the same stream, so only one may
be enabled per process -- which is why the multi-persist configuration is three
invocations rather than one. This module is what stitches their numbers back
together.

Schema::

    [ {"wall": {"duration": 0.0007, "percentage": 42.6},
       "name": "runSaturation",
       "passes": [ ...same shape..., {} ]},
      {} ]

The trailing ``{}`` entries are sentinels with no name and no timing; they are
skipped.
"""

from __future__ import annotations

import json
from pathlib import Path


def load(path: str | Path) -> list:
    """Parse a timing JSON file. An empty file yields an empty report."""
    text = Path(path).read_text().strip()
    if not text:
        return []
    return json.loads(text)


def find_scope(entries, name: str) -> float | None:
    """Return the wall-clock duration in seconds of the first scope called
    `name`, searching depth-first through nested ``passes``. None if absent."""
    if isinstance(entries, dict):
        entries = [entries]
    for entry in entries:
        if not isinstance(entry, dict) or "name" not in entry:
            continue  # {} sentinel
        if entry["name"] == name:
            return float(entry.get("wall", {}).get("duration", 0.0))
        found = find_scope(entry.get("passes", []), name)
        if found is not None:
            return found
    return None


def require_scope(path: str | Path, name: str) -> float:
    """find_scope, but fail loudly. A silently-zero timing column is worse than
    a broken pipeline: it looks like a real measurement."""
    found = find_scope(load(path), name)
    if found is None:
        raise SystemExit(
            f"{path}: no timing scope named {name!r}. "
            f"Did rover-mlir-opt lose its timing registration, "
            f"or did the pass get renamed?"
        )
    return found
