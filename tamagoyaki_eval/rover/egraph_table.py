"""Render the e-class counts as the paper's e-graph size table.

One row per benchmark: the single-level count, then the two multi-level counts
each followed by its ratio to the single-level one, and an average of those
ratios at the bottom. Single-level is the baseline because it is the smallest
graph any of the e-graph configurations builds.

E-classes, not e-nodes: the CSV carries both, but one number per configuration
is what the table has room for, and the e-class count is the one the paper
talks about.

The average is the arithmetic mean of the per-benchmark ratios -- every
benchmark counts once, whatever its absolute size.

Emits a bare ``tabular`` -- no preamble -- so it can be dropped into a paper
with ``\\input{}``; the caption and label live in the document.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

# Column order: the baseline column first, then the compared configurations.
BASELINE = ("rover", "Single")
CONFIGS = [
    ("multi", "Multi"),
    ("multi-persist", "Multi+Passes"),
]


def fmt_ratio(value: float) -> str:
    return rf"($\times${value:.1f})"


def ratio_cell(count: int | None, base: int | None) -> str:
    if count is None or not base:
        return "--"
    return fmt_ratio(count / base)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("csv_file", type=Path)
    ap.add_argument("-o", "--output", type=Path, help="default: stdout")
    args = ap.parse_args()

    with args.csv_file.open(newline="") as fh:
        rows = list(csv.DictReader(fh))

    # benchmark -> config -> e-class count, preserving first-seen order.
    by_bench: dict[str, dict[str, int]] = {}
    for row in rows:
        by_bench.setdefault(row["benchmark"], {})[row["config"]] = \
            int(row["eclasses"])

    lines = [
        f"% Generated from {args.csv_file.name} by tamagoyaki_eval/rover/egraph_table.py.",
        "% Counts are e-classes as --equivalence-graph-size reports them;",
        "% ratios and their average are relative to the single-level graph.",
        r"\begin{tabular}{l" + "r" + "rr" * len(CONFIGS) + "}",
        r"\toprule",
        "Benchmark & "
        + " & ".join(
            [BASELINE[1]]
            + [rf"\multicolumn{{2}}{{c}}{{{label}}}" for _, label in CONFIGS]
        )
        + r" \\",
        r"\midrule",
    ]

    ratios: dict[str, list[float]] = {config: [] for config, _ in CONFIGS}
    for bench, counts in by_bench.items():
        base = counts.get(BASELINE[0])
        cells = [bench.replace("_", r"\_"), str(base) if base is not None else "--"]
        for config, _ in CONFIGS:
            count = counts.get(config)
            cells += [str(count) if count is not None else "--",
                      ratio_cell(count, base)]
            if count is not None and base:
                ratios[config].append(count / base)
        lines.append(" & ".join(cells) + r" \\")

    lines.append(r"\midrule")
    average = ["Average", ""]
    for config, _ in CONFIGS:
        seen = ratios[config]
        average += ["", fmt_ratio(sum(seen) / len(seen)) if seen else "--"]
    lines += [" & ".join(average) + r" \\", r"\bottomrule", r"\end{tabular}"]

    text = "\n".join(lines) + "\n"
    if args.output:
        args.output.write_text(text)
    else:
        sys.stdout.write(text)
    return 0


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
