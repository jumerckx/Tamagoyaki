"""Parse area and delay out of an ABC ``print_stats`` report.

After ``read_genlib ...; read x.aig; strash; map``, ABC 0.62 prints one summary
line::

    design: i/o =   97/   64  lat =    0  nd = 14473  edge =  41377  \
area =1605.26  delay =567.14  lev = 26

Only ``area`` and ``delay`` are technology-mapped numbers; the rest describe the
AIG. Note there is no space after the ``=``.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

_AREA = re.compile(r"\barea\s*=\s*([0-9.]+)")
_DELAY = re.compile(r"\bdelay\s*=\s*([0-9.]+)")


def parse(text: str, source: str = "<stdin>") -> tuple[float, float]:
    """Return (area, delay). Raises rather than defaulting to zero: a zero area
    silently ranks as the best cell in the table."""
    area, delay = _AREA.search(text), _DELAY.search(text)
    if not area or not delay:
        missing = "area" if not area else "delay"
        raise SystemExit(
            f"{source}: no {missing} in ABC output. "
            f"Did the mapping step fail? Full output:\n{text.strip()}"
        )
    return float(area.group(1)), float(delay.group(1))


def parse_file(path: str | Path) -> tuple[float, float]:
    return parse(Path(path).read_text(), str(path))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("stats_file", help="captured ABC print_stats output")
    args = ap.parse_args()
    area, delay = parse_file(args.stats_file)
    print(json.dumps({"area": area, "delay": delay}))
    return 0


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
