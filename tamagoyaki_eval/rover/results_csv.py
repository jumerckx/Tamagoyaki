"""Collect the per-(benchmark, configuration) measurements into one CSV.

Reads the ABC reports from ``08-abc/<config>/<bench>.txt`` and the timing JSON
from ``05-timing/<config>/<bench>.r<rep>.json`` (plus ``.canon.r<rep>.json``
for multi-persist) and writes::

    benchmark,config,area,delay,egraph_ms,egraph_ms_stdev,egraph_ms_min,reps

`area` and `delay` are ASAP7-mapped, rounded to integers (they are four-digit
numbers, so the sub-unit part is noise).

What counts as e-graph time:
  baseline       0 -- no e-graph is built, and no timing file is read.
  rover, multi   runSaturation.
  multi-persist  runSaturation + CanonicalizerPass + CombIntRangeNarrowing,
                 summed across the two timing files of that repetition, because
                 the CIRCT passes run over the persisted e-graph are part of
                 what that configuration costs.
"""

from __future__ import annotations

import argparse
import csv
import statistics
import sys
from pathlib import Path

from tamagoyaki_eval import timing
from tamagoyaki_eval.rover import abc_stats

# Pass names as they appear in the two timing reports. CanonicalizerPass is the
# MLIR pass-manager's name for --canonicalize (not "Canonicalizer").
SATURATION_SCOPE = "runSaturation"
PERSIST_SCOPES = ("CanonicalizerPass", "CombIntRangeNarrowing")


def egraph_seconds(config: str, timing_dir: Path, bench: str, rep: int) -> float:
    """The e-graph wall clock of one repetition, in seconds."""
    total = timing.require_scope(timing_dir / config / f"{bench}.r{rep}.json",
                                 SATURATION_SCOPE)
    if config == "multi-persist":
        canon = timing_dir / config / f"{bench}.canon.r{rep}.json"
        total += sum(timing.require_scope(canon, s) for s in PERSIST_SCOPES)
    return total


def egraph_stats(config: str, timing_dir: Path, bench: str,
                 reps: int) -> dict[str, object]:
    if config == "baseline":
        return {"egraph_ms": 0.0, "egraph_ms_stdev": 0.0,
                "egraph_ms_min": 0.0, "reps": 0}

    ms = [egraph_seconds(config, timing_dir, bench, rep) * 1000
          for rep in range(reps)]
    return {
        "egraph_ms": round(statistics.fmean(ms), 6),
        # stdev is undefined for a single sample; report 0 rather than failing,
        # since reps=1 is the legitimate quick-run configuration.
        "egraph_ms_stdev": round(statistics.stdev(ms), 6) if len(ms) > 1 else 0.0,
        "egraph_ms_min": round(min(ms), 6),
        "reps": len(ms),
    }


FIELDS = ["benchmark", "config", "area", "delay",
          "egraph_ms", "egraph_ms_stdev", "egraph_ms_min", "reps"]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--abc-dir", required=True, type=Path)
    ap.add_argument("--timing-dir", required=True, type=Path)
    ap.add_argument("--configs", required=True, nargs="+")
    ap.add_argument("--benchmarks", required=True, nargs="+")
    ap.add_argument("--reps", type=int, default=20,
                    help="repetitions per measured command (default: 20)")
    ap.add_argument("-o", "--output", type=Path, help="default: stdout")
    args = ap.parse_args()

    if args.reps < 1:
        raise SystemExit(f"--reps must be at least 1, got {args.reps}")

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
                **egraph_stats(config, args.timing_dir, bench, args.reps),
            })

    out = args.output.open("w", newline="") if args.output else sys.stdout
    try:
        writer = csv.DictWriter(out, fieldnames=FIELDS)
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
