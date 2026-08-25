"""Render the results CSV as the paper's comparison table.

One row per benchmark, one column group per configuration, with the smallest
area and the smallest delay in each row set in bold (all cells tied for the
minimum are bolded).

Times are milliseconds to one decimal, which is exactly the resolution MLIR's
JSON timing writer offers (it prints seconds to four decimals). The CSV carries
more decimals as headroom; showing them here would imply precision the
measurement does not have.

Emits a bare ``tabular`` -- no preamble, no ``\\usepackage`` -- so it can be
dropped into a paper with ``\\input{}``.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

# Column groups, in table order. "baseline" has no e-graph, hence no time cell.
CONFIGS = [
    ("baseline", "circt-synth", False),
    ("rover", "Rover", True),
    ("multi", "+ datapath", True),
    ("multi-persist", "+ persist", True),
]


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

    lines = [
        f"% Generated from {args.csv_file.name} by tamagoyaki_eval/rover/latex_table.py.",
        "% Bold marks the best area and the best delay in each row.",
        "% Times are e-graph wall clock in ms; circt-synth builds no e-graph.",
        r"\begin{tabular}{l" + "rr" + "rrr" * 3 + "}",
        r"\toprule",
        " & ".join(
            [""]
            + [rf"\multicolumn{{{2 if not t else 3}}}{{c}}{{{label}}}"
               for _, label, t in CONFIGS]
        )
        + r" \\",
        "Benchmark & "
        + " & ".join(
            "Area & Delay" + (" & Time" if t else "") for _, _, t in CONFIGS
        )
        + r" \\",
        r"\midrule",
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

    lines += [r"\bottomrule", r"\end{tabular}"]
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
