"""Collect the reported e-graph sizes into one CSV.

Reads the ``--equivalence-graph-size`` reports from ``03-egraph/`` and writes::

    benchmark,config,eclasses,enodes

The numbers are the compiler's own accounting, the same metric the saturation
loop prints under ``--debug-only=ematch``: a ClassOp is an e-class, every other
result is an e-node, and a result not already wrapped in a single-use ClassOp
counts as an implicit e-class too. So a multi-result op like
``datapath.partial_product``, which is 63 results wide, is 63 nodes -- which is
what makes the datapath rewrites' effect on graph size visible at all.

Three graphs per benchmark, one per e-graph configuration (`baseline` builds no
e-graph and has no row):

  rover          saturated with the base rule set -- the single-level graph.
  multi          saturated with base + datapath rewrites.
  multi-persist  the `multi` graph after CIRCT's --canonicalize and
                 --comb-int-range-narrowing, which prune it.

`multi` and `multi-persist` share one saturation run -- the persisted graph *is*
the `multi` graph -- so the two columns differ by exactly the CIRCT passes.
"""

from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

# config -> the graph whose report that configuration's row comes from. Keep in
# step with the Snakefile's 03-egraph rules and with CONFIGS in egraph_table.py.
GRAPH_REPORTS = [
    ("rover", "{bench}.base-sat.size.txt"),
    ("multi", "{bench}.full-sat.size.txt"),
    ("multi-persist", "{bench}.canon.size.txt"),
]

# "Graph has 564 e-classes and 588 e-nodes." -- one line per equivalence.graph.
SIZE_RE = re.compile(r"Graph has (\d+) e-classes and (\d+) e-nodes")


def read_size(path: Path) -> tuple[int, int]:
    """Total e-classes and e-nodes reported for a graph file.

    Summed over the report's lines: the benchmarks hold one graph each, but a
    module with several would otherwise be silently reduced to its first.
    """
    sizes = [m.groups() for m in SIZE_RE.finditer(path.read_text())]
    if not sizes:
        raise SystemExit(f"{path}: no graph size reported -- "
                         "did --equivalence-graph-size find a graph?")
    return (sum(int(c) for c, _ in sizes), sum(int(n) for _, n in sizes))


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--egraph-dir", required=True, type=Path)
    ap.add_argument("--benchmarks", required=True, nargs="+")
    ap.add_argument("-o", "--output", type=Path, help="default: stdout")
    args = ap.parse_args()

    rows = []
    for bench in args.benchmarks:
        for config, pattern in GRAPH_REPORTS:
            eclasses, enodes = read_size(
                args.egraph_dir / pattern.format(bench=bench))
            rows.append({
                "benchmark": bench,
                "config": config,
                "eclasses": eclasses,
                "enodes": enodes,
            })

    out = args.output.open("w", newline="") if args.output else sys.stdout
    try:
        writer = csv.DictWriter(
            out, fieldnames=["benchmark", "config", "eclasses", "enodes"])
        writer.writeheader()
        writer.writerows(rows)
    finally:
        if args.output:
            out.close()
    return 0


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
