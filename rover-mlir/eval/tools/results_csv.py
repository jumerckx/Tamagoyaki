"""Collect the per-(benchmark, configuration) measurements into one CSV.

Reads the ABC reports from ``08-abc/<config>/<bench>.txt`` and the timing JSON
from ``05-timing/<config>/<bench>.json`` (plus ``.canon.json`` for
multi-persist) and writes::

    benchmark,config,area,delay,egraph_ms

`area` and `delay` are ASAP7-mapped, rounded to integers (they are four-digit
numbers, so the sub-unit part is noise).

`egraph_ms` is the e-graph time in milliseconds, kept to microsecond precision.
The original automate_pipeline.py reported `int(seconds * 1000)`, which was fine
for the workloads it measured but destroys these: saturation on these circuits
takes well under 2 ms, so integer milliseconds quantized almost everything to
"1". Note the floor is not here but upstream -- MLIR's JSON timing writer prints
seconds with four decimals, i.e. 0.1 ms granularity -- so the third decimal
below is headroom rather than signal today.

What counts as `egraph_ms`:

  baseline       0 -- no e-graph is built.
  rover, multi   runSaturation.
  multi-persist  runSaturation + CanonicalizerPass + CombIntRangeNarrowing,
                 summed across the two timing files, because the CIRCT passes
                 run over the persisted e-graph are part of what that
                 configuration costs.

Extraction time is excluded everywhere, matching the original script.
"""

from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

import abc_stats
import timing

# Pass names as they appear in the two timing reports. CanonicalizerPass is the
# MLIR pass-manager's name for --canonicalize (not "Canonicalizer").
SATURATION_SCOPE = "runSaturation"
PERSIST_SCOPES = ("CanonicalizerPass", "CombIntRangeNarrowing")


def egraph_seconds(config: str, timing_dir: Path, bench: str) -> float:
    if config == "baseline":
        return 0.0
    total = timing.require_scope(timing_dir / config / f"{bench}.json",
                                 SATURATION_SCOPE)
    if config == "multi-persist":
        canon = timing_dir / config / f"{bench}.canon.json"
        total += sum(timing.require_scope(canon, s) for s in PERSIST_SCOPES)
    return total


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--abc-dir", required=True, type=Path)
    ap.add_argument("--timing-dir", required=True, type=Path)
    ap.add_argument("--configs", required=True, nargs="+")
    ap.add_argument("--benchmarks", required=True, nargs="+")
    ap.add_argument("-o", "--output", type=Path, help="default: stdout")
    args = ap.parse_args()

    rows = []
    for bench in args.benchmarks:
        for config in args.configs:
            area, delay = abc_stats.parse_file(
                args.abc_dir / config / f"{bench}.txt")
            rows.append({
                "benchmark": bench,
                "config": config,
                "area": round(area),
                "delay": round(delay),
                "egraph_ms": round(
                    egraph_seconds(config, args.timing_dir, bench) * 1000, 3),
            })

    out = args.output.open("w", newline="") if args.output else sys.stdout
    try:
        writer = csv.DictWriter(
            out, fieldnames=["benchmark", "config", "area", "delay", "egraph_ms"])
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
