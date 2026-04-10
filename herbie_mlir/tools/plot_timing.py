import argparse
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import Patch


def main():
    parser = argparse.ArgumentParser(
        description="Generate timing comparison plot from evaluation CSV"
    )
    parser.add_argument(
        "csv_path",
        nargs="?",
        default="results/evaluation_pi_false.csv",
        help="Path to input CSV file (default: results/evaluation_pi_false.csv)",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="Path to output PDF file",
    )
    parser.add_argument(
        "--no-pdl-loading",
        action="store_true",
        help="Exclude PDL loading time from optimize_ms",
    )

    args = parser.parse_args()

    # Read the CSV file
    if args.csv_path:
        df = pd.read_csv(args.csv_path)
    else:
        df = pd.read_csv(sys.stdin)

    # Calculate Herbie's total time (in milliseconds)
    df["herbie_total_ms"] = (
        df["herbie_wo_sampling"] + (256 / 8256) * df["herbie_sampling"]
    )

    # Sum relevant times and convert from seconds to milliseconds
    if args.no_pdl_loading:
        df["optimize_ms"] = df["optimize_process_functions_time"] * 1000
    else:
        df["optimize_ms"] = (
            df["optimize_load_pdl_time"] + df["optimize_process_functions_time"]
        ) * 1000

    # Calculate speedup ratio
    df["speedup"] = df["herbie_total_ms"] / df["optimize_ms"]

    geomean_slowdown = np.exp(np.log(df["speedup"]).mean())

    # Separate NMSE and non-NMSE benchmarks
    nmse_mask = df["name"].str.startswith("NMSE")
    df_nmse = df[nmse_mask].copy()
    df_other = df[~nmse_mask].copy()

    # Remove 'NMSE ' prefix from NMSE benchmarks
    df_nmse["name"] = df_nmse["name"].str.replace("NMSE ", "", regex=False)

    # Concatenate: other benchmarks first, then NMSE benchmarks
    df = pd.concat([df_other, df_nmse], ignore_index=True)

    # Shorten common words in names (copied from accuracy plot)
    df["name"] = df["name"].str.replace(
        "Probabilities in a clustering algorithm", "Clustering", regex=False
    )
    df["name"] = df["name"].str.replace("Complex square root", "Sqrt", regex=False)
    df["name"] = df["name"].str.replace(
        "Complex sine and cosine", "Sin, Cos", regex=False
    )
    df["name"] = df["name"].str.replace("section", "Sec.", regex=False)
    df["name"] = df["name"].str.replace("problem", "Prob.", regex=False)
    df["name"] = df["name"].str.replace("positive", "+", regex=False)
    df["name"] = df["name"].str.replace("negative", "-", regex=False)
    df["name"] = df["name"].str.replace("example", "Ex.", regex=False)

    # Extract the relevant columns
    names = df["name"]
    optimize_times = df["optimize_ms"]
    herbie_times = df["herbie_total_ms"]
    speedups = df["speedup"]
    # Set up the plot with non-LaTeX styling and fonttype 42
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["ps.fonttype"] = 42
    plt.rcParams["font.size"] = 8
    plt.rcParams["axes.linewidth"] = 0.8

    fig, ax = plt.subplots(figsize=(7.0, 1.8))

    # Set up bar positions
    x = np.arange(len(names))
    width = 0.25

    # Define bar colors (matching accuracy plot style)
    color_eqsat = "#33a02c"  # Green for Herbie-MLIR (ours)
    color_herbie = "#1f78b4"  # Blue for Herbie

    # Create bars (Herbie first, then eqsat)
    bars_herbie_list = []
    bars_eqsat_list = []

    for i in range(len(names)):
        bar_herbie = ax.bar(
            x[i] - width / 2,
            herbie_times.iloc[i],
            width,
            color=color_herbie,
            alpha=0.8,
        )
        bar_eqsat = ax.bar(
            x[i] + width / 2,
            optimize_times.iloc[i],
            width,
            color=color_eqsat,
            alpha=0.8,
        )

        bars_herbie_list.append(bar_herbie[0])
        bars_eqsat_list.append(bar_eqsat[0])

    # Set log scale
    ax.set_yscale("log")
    ax.set_xlim(-0.5, len(names) - 0.5)
    ax.margins(x=0)

    # Create custom legend (Herbie first, then eqsat)
    legend_elements = [
        Patch(facecolor=color_herbie, alpha=0.8, label="Herbie"),
        Patch(facecolor=color_eqsat, alpha=0.8, label="Tamagoyaki"),
    ]

    # Add speedup labels on top of bars
    label_fontsize = 6
    label_offset_factor = 1.05

    for i, (bar_herbie, bar_eqsat) in enumerate(zip(bars_herbie_list, bars_eqsat_list)):
        height_herbie = bar_herbie.get_height()
        height_eqsat = bar_eqsat.get_height()
        speedup = speedups.iloc[i]

        # Format speedup as "XXXx" with appropriate precision
        if speedup >= 10:
            speedup_str = f"{speedup:.0f}×"
        else:
            speedup_str = f"{speedup:.1f}×"

        # Place the label flat if the tamagoyaki bar is sufficiently taller
        # (in log scale) than both bars of the next benchmark.
        if i + 1 < len(bars_herbie_list):
            next_herbie_height = bars_herbie_list[i + 1].get_height()
            next_eqsat_height = bars_eqsat_list[i + 1].get_height()
            log_gap = min(
                np.log10(height_eqsat) - np.log10(next_herbie_height),
                np.log10(height_eqsat) - np.log10(next_eqsat_height),
            )
        else:
            log_gap = np.inf
        if log_gap > 0.5:
            label_x = x[i]
            label_y = height_eqsat * label_offset_factor
            rotation = 0
            label_ha = "left"
        else:
            label_x = x[i] + 0.3
            max_height = max(height_herbie, height_eqsat)
            label_y = max_height * label_offset_factor
            rotation = 60
            label_ha = "center"

        ax.text(
            label_x,
            label_y,
            speedup_str,
            ha=label_ha,
            va="bottom",
            fontsize=label_fontsize,
            rotation=rotation,
            color=color_eqsat,
            alpha=1.0,
        )

    # Remove top and right spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # Customize the plot
    ylim = ax.get_ylim()
    ax.text(
        -0.5,
        ylim[1] * 1.05,
        "Time (ms)",
        fontsize=8,
        ha="left",
        va="bottom",
    )

    ax.set_xticks(x)
    ax.set_xticklabels(names, rotation=35, ha="right", fontsize=8)

    # Smaller tick labels
    ax.tick_params(axis="y", labelsize=8)
    ax.tick_params(axis="x", pad=-1)

    # Legend positioning
    ax.legend(
        handles=legend_elements,
        loc="upper right",
        bbox_to_anchor=(1.0, 1.2),
        frameon=False,
        fontsize=8,
        ncol=2,
    )

    # Grid for log scale
    ax.set_axisbelow(True)
    ax.grid(axis="y", alpha=0.3, which="both", linewidth=0.5)

    # Add some padding
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.45, top=0.88)  # Add space at bottom and top for legend

    # Save as high-resolution PDF
    plt.savefig(args.output, dpi=300, bbox_inches="tight", pad_inches=0)
    plt.close()

    print(f"Timing plot created successfully with {len(names)} benchmarks")
    print(f"Average speedup (eqsat/Herbie): {speedups.mean():.2f}x")
    print(f"Median speedup: {speedups.median():.2f}x")
    print(f"Geometric mean slowdown (eqsat/Herbie): {geomean_slowdown:.2f}x")
    print(f"Saved as: {args.output}")


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
