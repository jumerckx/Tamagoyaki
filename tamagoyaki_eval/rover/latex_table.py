"""Render the results CSV as the paper's comparison table.

One row per benchmark, one column group per configuration, with the smallest
area and the smallest delay in each row set in bold (all cells tied for the
minimum are bolded).

Times are milliseconds to one decimal, which is exactly the resolution MLIR's
JSON timing writer offers (it prints seconds to four decimals). The CSV carries
more decimals as headroom; showing them here would imply precision the
measurement does not have.

Emits a bare ``tabular`` -- no preamble -- so it can be dropped into a paper
with ``\\input{}``. The header uses ``\\multirow`` and ``\\cmidrule``, so the
document needs ``\\usepackage{multirow}`` and ``\\usepackage{booktabs}``.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

# Column groups, in table order. "baseline" has no e-graph, hence no time cell.
CONFIGS = [
    ("baseline", "No EqSat", False),
    ("rover", "Single-Level", True),
    ("multi", r"\textbf{Multi-Level}", True),
    ("multi-persist", r"\textbf{Multi-Level + CIRCT Passes}", True),
]


def header_lines() -> list[str]:
    """The two header rows plus the cmidrule line beneath them."""
    widths = [3 if has_time else 2 for _, _, has_time in CONFIGS]

    top = " & ".join(
        [r"\multirow{2}{*}{Benchmark}"]
        + [rf"\multicolumn{{{w}}}{{c}}{{{label}}}"
           for w, (_, label, _) in zip(widths, CONFIGS)]
    )
    sub = " & ".join(
        [""]
        + [c for _, _, has_time in CONFIGS
           for c in ("Area", "Delay", *(("Opt. Time",) if has_time else ()))]
    )

    # \cmidrule spans: the benchmark column, then one per config group.
    rules, col = [r"\cmidrule(lr){1-1}"], 2
    for w in widths:
        rules.append(rf"\cmidrule(lr){{{col}-{col + w - 1}}}")
        col += w

    return [top + r" \\", sub + r" \\", "", " ".join(rules)]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("csv_file", type=Path)
    ap.add_argument("-o", "--output", type=Path, help="default: stdout")
    args = ap.parse_args()

    with args.csv_file.open(newline="") as fh:
        rows = list(csv.DictReader(fh))

    # benchmark -> config -> row, preserving first-seen benchmark order.
    by_bench: dict[str, dict[str, dict]] = {}
    for row in rows:
        by_bench.setdefault(row["benchmark"], {})[row["config"]] = row

    ncols = 1 + sum(3 if has_time else 2 for _, _, has_time in CONFIGS)
    lines = [
        f"% Generated from {args.csv_file.name} by tamagoyaki_eval/rover/latex_table.py.",
        "% Bold marks the best area and the best delay in each row.",
        "% Times are e-graph wall clock in ms; the no-eqsat run builds no e-graph.",
        "% Requires \\usepackage{multirow} and \\usepackage{booktabs}.",
        r"\begin{tabular}{" + " ".join(["l"] + ["r"] * (ncols - 1)) + "}",
        r"\toprule",
        *header_lines(),
    ]

    for bench, configs in by_bench.items():
        areas = {c: int(configs[c]["area"]) for c, _, _ in CONFIGS if c in configs}
        delays = {c: int(configs[c]["delay"]) for c, _, _ in CONFIGS if c in configs}
        best_area, best_delay = min(areas.values()), min(delays.values())

        cells = [bench.replace("_", r"\_")]
        for config, _, has_time in CONFIGS:
            row = configs.get(config)
            if row is None:
                cells += ["--", "--"] + (["--"] if has_time else [])
                continue
            area, delay = int(row["area"]), int(row["delay"])
            cells.append(rf"\textbf{{{area}}}" if area == best_area else str(area))
            cells.append(rf"\textbf{{{delay}}}" if delay == best_delay else str(delay))
            if has_time:
                cells.append(f"{float(row['egraph_ms']):.1f}")
        lines.append(" & ".join(cells) + r" \\")

    # The paper's table runs without a bottom rule; uncomment to restore it.
    lines += [r"% \bottomrule", "", r"\end{tabular}"]
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
