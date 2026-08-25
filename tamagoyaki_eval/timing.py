"""
Read wall-clock durations out of a timing report.
"""

from __future__ import annotations

import json
from pathlib import Path

__all__ = ["load", "find_scope", "find_scopes", "require_scope", "require_sum"]


def load(path: str | Path) -> list:
    """Parse a timing JSON file. An empty file yields an empty report."""
    text = Path(path).read_text().strip()
    if not text:
        return []
    return json.loads(text)


# ---------------------------------------------------------------------------
# Tree walking
# ---------------------------------------------------------------------------

def _children(node) -> list[dict]:
    """The named child scopes of a node, or of the report itself."""
    entries = node.get("passes", []) if isinstance(node, dict) else node
    if not isinstance(entries, list):
        return []
    return [e for e in entries if isinstance(e, dict) and "name" in e]


def _find(node, name: str) -> dict | None:
    """The first scope called `name` below `node`, depth-first."""
    for child in _children(node):
        if child["name"] == name:
            return child
        found = _find(child, name)
        if found is not None:
            return found
    return None


def _find_all(node, name: str) -> list[dict]:
    """Every scope called `name` below `node`. Does not descend into a match,
    so a scope nested inside a same-named one is counted once."""
    found = []
    for child in _children(node):
        if child["name"] == name:
            found.append(child)
        else:
            found.extend(_find_all(child, name))
    return found


def _resolve(report, path) -> tuple[object, int | None]:
    """Follow `path` down the report. Returns (node, None) on success, or
    (None, i) with `i` indexing the first name that could not be found."""
    node = report
    for i, name in enumerate(path):
        found = _find(node, name)
        if found is None:
            return None, i
        node = found
    return node, None


def _duration(entry: dict) -> float:
    wall = entry.get("wall")
    if not isinstance(wall, dict) or "duration" not in wall:
        raise ValueError(
            f"timing scope {entry.get('name')!r} carries no wall-clock duration"
        )
    return float(wall["duration"])


def _missing(source, path, i: int) -> SystemExit:
    under = " > ".join(path[:i]) if i else "the report root"
    return SystemExit(
        f"{source}: no timing scope named {path[i]!r} under {under}. "
        f"Did the opt tool lose its timing registration, "
        f"or did the pass get renamed?"
    )


# ---------------------------------------------------------------------------
# Lookups
# ---------------------------------------------------------------------------

def find_scope(report, *path: str) -> float | None:
    """Wall-clock seconds of the scope `path` names, or None if it is absent."""
    node, missing = _resolve(report, path)
    return None if missing is not None else _duration(node)


def find_scopes(report, *path: str) -> list[float]:
    """Wall-clock seconds of *every* occurrence of the last name in `path`,
    below the scope the preceding names resolve to. Empty if any of them is."""
    *prefix, name = path
    node, missing = _resolve(report, prefix)
    if missing is not None:
        return []
    return [_duration(e) for e in _find_all(node, name)]


def require_scope(source: str | Path, *path: str) -> float:
    """find_scope over a timing file, raising SystemExit if it is not there."""
    node, missing = _resolve(load(source), path)
    if missing is not None:
        raise _missing(source, path, missing)
    try:
        return _duration(node)
    except ValueError as e:
        raise SystemExit(f"{source}: {e}") from e


def require_sum(source: str | Path, *path: str) -> float:
    """Total wall-clock seconds over every occurrence of the last name in
    `path`. Raises SystemExit if there is not at least one."""
    *prefix, name = path
    report = load(source)
    node, missing = _resolve(report, prefix)
    if missing is not None:
        raise _missing(source, path, missing)
    found = _find_all(node, name)
    if not found:
        raise _missing(source, path, len(prefix))
    try:
        return sum(_duration(e) for e in found)
    except ValueError as e:
        raise SystemExit(f"{source}: {e}") from e
