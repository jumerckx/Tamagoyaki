import argparse
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import Patch


def main():
    parser = argparse.ArgumentParser(
        description="Plot eqsat saturation timing speedup (individual vs combined matching)"
    )
    parser.add_argument(
        "csv_path",
        help="Path to evaluation CSV file",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="Path to output PDF file",
    )

    args = parser.parse_args()

    df = pd.read_csv(args.csv_path)

    # Extract match timing columns (already in seconds)
    df["match_s_individual"] = df["match_time_individual"]
    df["match_s_combined"] = df["match_time_joint"]

    # Calculate speedup ratio (individual / combined) based on match times
    df["speedup"] = df["match_s_individual"] / df["match_s_combined"]

    # Separate NMSE and non-NMSE benchmarks
    nmse_mask = df["name"].str.startswith("NMSE")
    df_nmse = df[nmse_mask].copy()
    df_other = df[~nmse_mask].copy()

    # Remove 'NMSE ' prefix from NMSE benchmarks
    df_nmse["name"] = df_nmse["name"].str.replace("NMSE ", "", regex=False)

    # Concatenate: other benchmarks first, then NMSE benchmarks
    merged = pd.concat([df_other, df_nmse], ignore_index=True)

    # Shorten common words in names (copied from accuracy plot)
    merged["name"] = merged["name"].str.replace(
        "Probabilities in a clustering algorithm", "Clustering", regex=False
    )
    merged["name"] = merged["name"].str.replace(
        "Complex square root", "Sqrt", regex=False
    )
    merged["name"] = merged["name"].str.replace(
        "Complex sine and cosine", "Sin, Cos", regex=False
    )
    merged["name"] = merged["name"].str.replace("section", "Sec.", regex=False)
    merged["name"] = merged["name"].str.replace("problem", "Prob.", regex=False)
    merged["name"] = merged["name"].str.replace("positive", "+", regex=False)
    merged["name"] = merged["name"].str.replace("negative", "-", regex=False)
    merged["name"] = merged["name"].str.replace("example", "Ex.", regex=False)

    # Extract the relevant columns
    names = merged["name"]
    individual_times = merged["match_s_individual"]
    combined_times = merged["match_s_combined"]
    speedups = merged["speedup"]
    nmse_start = len(df_other)  # Index where NMSE group starts
    nmse_end = len(merged) - 1  # Index where NMSE group ends

    # Set up the plot with non-LaTeX styling and fonttype 42
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["ps.fonttype"] = 42
    plt.rcParams["font.size"] = 7
    plt.rcParams["axes.linewidth"] = 0.8

    fig, ax = plt.subplots(figsize=(5.5, 2.5))

    # Set up bar positions
    x = np.arange(len(names))
    width = 0.25

    # Define bar colors
    color_individual = "#b2df8a"
    color_combined = "#33a02c"

    # Create bars
    bars1 = ax.bar(x - width / 2, individual_times, width, color=color_individual)
    bars2 = ax.bar(x + width / 2, combined_times, width, color=color_combined)

    # Set symlog scale (linear near zero, log for large values)
    ax.set_yscale("symlog", linthresh=0.01)
    ax.set_ylim(bottom=0)
    ax.set_xlim(-0.5, len(names) - 0.5)
    ax.margins(x=0)

    # Create custom legend
    legend_elements = [
        Patch(facecolor=color_individual, label="Individual Matching"),
        Patch(facecolor=color_combined, label="Combined Matching"),
    ]

    # Add speedup labels on top of individual bar
    label_fontsize = 3
    label_offset = 0.1

    for i, (bar1, bar2) in enumerate(zip(bars1, bars2)):
        height1 = individual_times.iloc[i]
        height2 = combined_times.iloc[i]
        speedup = speedups.iloc[i]

        # Rotate 90 if combined bar is taller, else 0
        rotation = 90 if height2 > height1 * 1.03 else 0
        label_x = bar1.get_x() + bar1.get_width() / 2.0
        label_y = height1 + label_offset

        # Format speedup as "XXXx" with appropriate precision
        if speedup >= 10:
            speedup_str = f"{speedup:.0f}×"
        else:
            speedup_str = f"{speedup:.1f}×"

        ax.text(
            label_x,
            label_y,
            speedup_str,
            ha="center",
            va="bottom",
            fontsize=label_fontsize,
            rotation=rotation,
            color=color_combined,
            alpha=1.0,
        )

    # Remove top and right spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # Store the original y-limits before adding bracket
    ylim = ax.get_ylim()

    # Customize the plot
    y_range = ylim[1] - ylim[0]
    ax.text(
        -0.5,
        ylim[1] + y_range * 0.04,
        "Time (s)",
        fontsize=8,
        ha="left",
        va="bottom",
    )

    ax.set_xticks(x)
    ax.set_xticklabels(names, rotation=35, ha="right", fontsize=6)

    # Smaller tick labels
    ax.tick_params(axis="y", labelsize=6)

    # Legend positioning
    legend_x = 0.45
    legend_y = 1.1
    ax.legend(
        handles=legend_elements,
        loc="upper left",
        bbox_to_anchor=(legend_x, legend_y),
        frameon=False,
        fontsize=6,
        ncol=1,
    )

    # Grid removed (consistent with accuracy plot)
    ax.set_axisbelow(True)

    # Add some padding
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.35, top=0.85)  # Add space at top for legend

    # Add bracket for NMSE group if there are NMSE benchmarks
    if nmse_start < len(names):
        bracked_width = 0.8
        y_range = ylim[1] - ylim[0]

        # Draw a bracket below the x-labels
        bracket_y = ylim[0] - y_range * 0.4
        bracket_height = y_range * 0.03

        # Draw horizontal line
        ax.plot(
            [nmse_start - 0.5, nmse_end + 0.5],
            [bracket_y, bracket_y],
            "k-",
            linewidth=bracked_width,
            clip_on=False,
            transform=ax.transData,
        )
        # Draw vertical ticks at ends
        ax.plot(
            [nmse_start - 0.5, nmse_start - 0.5],
            [bracket_y, bracket_y + bracket_height],
            "k-",
            linewidth=bracked_width,
            clip_on=False,
            transform=ax.transData,
        )
        ax.plot(
            [nmse_end + 0.5, nmse_end + 0.5],
            [bracket_y, bracket_y + bracket_height],
            "k-",
            linewidth=bracked_width,
            clip_on=False,
            transform=ax.transData,
        )

        # Add NMSE label
        ax.text(
            (nmse_start + nmse_end) / 2,
            bracket_y - y_range * 0.015,
            "NMSE",
            ha="center",
            va="top",
            fontsize=6,
            clip_on=False,
            transform=ax.transData,
        )

        # Reset y-limits to original values to prevent axis extension
        ax.set_ylim(ylim)

    # Save as high-resolution PDF
    plt.savefig(args.output, dpi=300, bbox_inches="tight", pad_inches=0)
    plt.close()

    # Calculate geometric mean of speedup
    geomean_speedup = np.exp(np.log(speedups).mean())

    print(f"eqsat comparison plot created successfully with {len(names)} benchmarks")
    print(f"Average speedup (individual/combined): {speedups.mean():.2f}x")
    print(f"Median speedup: {speedups.median():.2f}x")
    print(f"Geometric mean speedup: {geomean_speedup:.2f}x")
    print(f"Saved as: {args.output}")


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
