import argparse
import sys

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import Patch


def main():
    parser = argparse.ArgumentParser(
        description="Generate accuracy comparison plot from evaluation CSV"
    )
    parser.add_argument(
        "csv_path",
        nargs="?",
        help="Path to input CSV file (default: read from stdin)",
    )
    parser.add_argument(
        "-o",
        "--output",
        required=True,
        help="Path to output PDF file",
    )

    args = parser.parse_args()

    # Read the CSV file
    if args.csv_path:
        df = pd.read_csv(args.csv_path)
    else:
        df = pd.read_csv(sys.stdin)

    # Separate NMSE and non-NMSE benchmarks
    nmse_mask = df["name"].str.startswith("NMSE")
    df_nmse = df[nmse_mask].copy()
    df_other = df[~nmse_mask].copy()

    # Remove 'NMSE ' prefix from NMSE benchmarks
    df_nmse["name"] = df_nmse["name"].str.replace("NMSE ", "", regex=False)

    # Function to identify and reorder benchmarks based on accuracy differences
    def reorder_by_difference(df_subset):
        # Convert bits of error to percentage accuracy
        original = 100 - (df_subset["original_accuracy_bits"] / 64 * 100)
        optimized = 100 - (df_subset["optimized_accuracy_bits"] / 64 * 100)
        target = 100 - (df_subset["target_accuracy_bits"] / 64 * 100)

        # Calculate max difference for each benchmark
        max_diff = pd.DataFrame(
            {"original": original, "optimized": optimized, "target": target}
        ).max(axis=1) - pd.DataFrame(
            {"original": original, "optimized": optimized, "target": target}
        ).min(axis=1)

        # Mark as small difference if max_diff <= 3%
        df_subset["small_diff"] = max_diff <= 1

        # Separate into large and small difference groups
        df_large = df_subset[~df_subset["small_diff"]].copy()
        df_small = df_subset[df_subset["small_diff"]].copy()

        # Concatenate: large differences first, then small
        return pd.concat([df_large, df_small], ignore_index=True)

    # Reorder both groups separately
    df_other = reorder_by_difference(df_other)
    df_nmse = reorder_by_difference(df_nmse)

    # Concatenate: other benchmarks first, then NMSE benchmarks
    df = pd.concat([df_other, df_nmse], ignore_index=True)

    # Shorten common words in names
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
    small_diff_mask = df["small_diff"]
    nmse_start = len(df_other)  # Index where NMSE group starts
    nmse_end = len(df) - 1  # Index where NMSE group ends

    # Convert bits of error to percentage accuracy
    original = 100 - (df["original_accuracy_bits"] / 64 * 100)
    optimized = 100 - (df["optimized_accuracy_bits"] / 64 * 100)
    target = 100 - (df["target_accuracy_bits"] / 64 * 100)

    # Set up the plot with non-LaTeX styling and fonttype 42
    plt.rcParams["pdf.fonttype"] = 42
    plt.rcParams["ps.fonttype"] = 42
    plt.rcParams["font.size"] = 7
    plt.rcParams["axes.linewidth"] = 0.8

    fig, ax = plt.subplots(figsize=(5.5, 2.5))

    # Set up bar positions with slightly reduced width for spacing
    x = np.arange(len(names))
    width = 0.25

    # Define bar colors
    color_original = "#cacaca"
    color_herbie = "#1f78b4"
    color_target = "#33a02c"

    # Define alpha values
    alpha_normal = 1.0
    alpha_faded = 0.3

    # Create bars with conditional alpha
    bars1_list = []
    bars2_list = []
    bars3_list = []

    for i in range(len(names)):
        alpha_orig = alpha_normal if not small_diff_mask.iloc[i] else alpha_faded
        alpha_opt = 0.8 if not small_diff_mask.iloc[i] else alpha_faded * 0.8
        alpha_tgt = 0.8 if not small_diff_mask.iloc[i] else alpha_faded * 0.8

        bar1 = ax.bar(
            x[i] - width,
            original.iloc[i],
            width,
            color=color_original,
            alpha=alpha_orig,
        )
        bar2 = ax.bar(
            x[i], optimized.iloc[i], width, color=color_herbie, alpha=alpha_opt
        )
        bar3 = ax.bar(
            x[i] + width, target.iloc[i], width, color=color_target, alpha=alpha_tgt
        )

        bars1_list.append(bar1[0])
        bars2_list.append(bar2[0])
        bars3_list.append(bar3[0])

    ax.set_xlim(-0.5, len(names) - 0.5)
    ax.margins(x=0)

    # Create custom legend with smaller font
    legend_elements = [
        Patch(facecolor=color_original, alpha=1.0, label="Original"),
        Patch(facecolor=color_herbie, alpha=0.8, label="Herbie"),
        Patch(facecolor=color_target, alpha=0.8, label="Herbie-MLIR (ours)"),
    ]

    # Add data labels on top of bars with smaller font
    label_fontsize = 3
    x_offset_60deg = 0.08
    label_offset = 0.3
    x_offset_outer = 0.04
    for i, (bar1, bar2, bar3) in enumerate(zip(bars1_list, bars2_list, bars3_list)):
        height1 = bar1.get_height()
        height2 = bar2.get_height()
        height3 = bar3.get_height()

        # Use faded alpha for labels of small difference benchmarks
        label_alpha = 1.0 if not small_diff_mask.iloc[i] else 0.5

        # Herbie bar: rotate 90 if target is taller, else 60
        rotation2 = 90 if height3 > height2 * 1.01 else 60
        x_pos2 = bar2.get_x() + bar2.get_width() / 2.0
        y_pos2 = height2 + label_offset
        if rotation2 == 60:
            x_pos2 += x_offset_60deg
        else:
            y_pos2 += 0.5
        ax.text(
            x_pos2,
            y_pos2,
            f"{height2:.1f}",
            ha="center",
            va="bottom",
            fontsize=label_fontsize,
            rotation=rotation2,
            color=color_herbie,
            alpha=label_alpha,
        )

        # Original bar: rotate 90 if herbie is taller or is itself rotated 90, else 60
        rotation1 = 90 if height2 > height1 * 1.01 or rotation2 == 90 else 60
        x_pos1 = bar1.get_x() + bar1.get_width() / 2.0 - x_offset_outer
        y_pos1 = height1 + label_offset
        if rotation1 == 60:
            x_pos1 += x_offset_60deg
        else:
            y_pos1 += 0.5
        ax.text(
            x_pos1,
            y_pos1,
            f"{height1:.1f}",
            ha="center",
            va="bottom",
            fontsize=label_fontsize,
            rotation=rotation1,
            color="#827b7b",
            alpha=label_alpha,
        )

        # Target bar: always 60 degrees (rightmost)
        x_pos3 = bar3.get_x() + bar3.get_width() / 2.0 + x_offset_60deg + x_offset_outer
        ax.text(
            x_pos3,
            height3 + label_offset,
            f"{height3:.1f}",
            ha="center",
            va="bottom",
            fontsize=label_fontsize,
            rotation=60,
            color=color_target,
            alpha=label_alpha,
        )

    # Remove top and right spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # Customize the plot
    ylim = ax.get_ylim()
    y_range = ylim[1] - ylim[0]
    ax.text(
        -0.5,
        ylim[1] + y_range * 0.04,
        "Accuracy (%)",
        fontsize=8,
        ha="left",
        va="bottom",
    )

    ax.set_xticks(x)
    ax.set_xticklabels(names, rotation=35, ha="right", fontsize=6)

    # Smaller tick labels
    ax.tick_params(axis="y", labelsize=6)

    # Fade x-labels for small difference benchmarks
    for i, label in enumerate(ax.get_xticklabels()):
        if small_diff_mask.iloc[i]:
            label.set_alpha(0.3)

    # Legend positioning with smaller font
    legend_x = 0.83
    legend_y = 1.1
    ax.legend(
        handles=legend_elements,
        loc="upper left",
        bbox_to_anchor=(legend_x, legend_y),
        frameon=False,
        fontsize=6,
    )

    # Grid removed
    ax.set_axisbelow(True)

    # Store the original y-limits before adding bracket
    ylim = ax.get_ylim()

    # Add some padding
    plt.tight_layout()
    plt.subplots_adjust(bottom=0.35)  # Make room for bracket and labels

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

    print(f"Plot created successfully with {len(names)} benchmarks")
    print(f"Small difference benchmarks (≤1%): {small_diff_mask.sum()}")
    print(f"Saved as: {args.output}")


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
