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
    parser.add_argument(
        "--compact",
        action="store_true",
        help="Remove benchmarks with small differences instead of graying them out",
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

        # Mark as small difference if max_diff <= 1%
        df_subset["small_diff"] = max_diff <= 1

        # Separate into large and small difference groups
        df_large = df_subset[~df_subset["small_diff"]].copy()
        df_small = df_subset[df_subset["small_diff"]].copy()

        # Concatenate: large differences first, then small
        return pd.concat([df_large, df_small], ignore_index=True)

    # Reorder both groups separately
    df_other = reorder_by_difference(df_other)
    df_nmse = reorder_by_difference(df_nmse)

    # Count total benchmarks before compacting (for width calculation)
    total_before_compact = len(df_other) + len(df_nmse)

    # Concatenate: other benchmarks first, then NMSE benchmarks
    df = pd.concat([df_other, df_nmse], ignore_index=True)

    # Optionally remove benchmarks with small differences
    if args.compact:
        df_other = df_other[~df_other["small_diff"]].reset_index(drop=True)
        df_nmse = df_nmse[~df_nmse["small_diff"]].reset_index(drop=True)
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

    # Scale figure width so bars have consistent physical size.
    # Normal mode: 3 bars × 0.25 = 0.75 data-units per benchmark
    # Compact mode: 2 bars × 0.30 = 0.60 data-units per benchmark
    full_width = 5.5  # width when all benchmarks are present (normal mode)
    footprint_normal = 3 * 0.25
    footprint_compact = 2 * 0.38
    if args.compact:
        fig_width = (
            full_width
            * (len(names) / max(total_before_compact, 1))
            * (footprint_compact / footprint_normal)
        )
    else:
        fig_width = full_width
    fig_width = max(fig_width, 1.5)  # enforce a minimum so the plot isn't tiny
    fig, ax = plt.subplots(figsize=(fig_width, 1.7))

    # Define bar colors
    color_original = "#cacaca"
    color_herbie = "#1f78b4"
    color_target = "#33a02c"

    # Define alpha values
    alpha_normal = 1.0
    alpha_faded = 0.3

    if args.compact:
        # Compact mode: 2 bars + dotted baseline line
        width = 0.38
        x = np.arange(len(names))

        bars2_list = []
        bars3_list = []

        for i in range(len(names)):
            alpha_opt = 0.8 if not small_diff_mask.iloc[i] else alpha_faded * 0.8
            alpha_tgt = 0.8 if not small_diff_mask.iloc[i] else alpha_faded * 0.8

            bar2 = ax.bar(
                x[i] - width / 2,
                optimized.iloc[i],
                width,
                color=color_herbie,
                alpha=alpha_opt,
            )
            bar3 = ax.bar(
                x[i] + width / 2,
                target.iloc[i],
                width,
                color=color_target,
                alpha=alpha_tgt,
            )

            bars2_list.append(bar2[0])
            bars3_list.append(bar3[0])

            # Draw dotted baseline line spanning both bars
            label_alpha = 1.0 if not small_diff_mask.iloc[i] else 0.5
            baseline_y = original.iloc[i]
            line_x_start = x[i] - width - 0.05
            line_x_end = x[i] + width + 0.05
            ax.plot(
                [line_x_start, line_x_end],
                [baseline_y, baseline_y],
                color="black",
                linestyle=":",
                linewidth=0.5,
                alpha=label_alpha,
            )

            label_fontsize = 3
            label_offset = 0.3
            x_offset_60deg = 0.08
            x_offset_outer = 0.04

            height2 = optimized.iloc[i]
            height3 = target.iloc[i]
            low_baseline = baseline_y < 20

            if low_baseline:
                # Low original accuracy: place baseline label on top of both bars, horizontally
                top_of_bars = max(height2, height3)
                baseline_lift = 1.0
                extra_lift = 6.0

                # Baseline label: horizontal, centered over both bars
                ax.text(
                    x[i],
                    top_of_bars + baseline_lift + label_offset,
                    f"{baseline_y:.1f}",
                    ha="center",
                    va="bottom",
                    fontsize=label_fontsize,
                    rotation=0,
                    color="black",
                    alpha=label_alpha,
                )

                # Herbie bar label (shifted up)
                rotation2 = 90 if height3 > height2 * 1.01 else 60
                x_pos2 = bars2_list[i].get_x() + bars2_list[i].get_width() / 2.0
                y_pos2 = height2 + label_offset + extra_lift
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

                # Target bar label (shifted up)
                x_pos3 = (
                    bars3_list[i].get_x()
                    + bars3_list[i].get_width() / 2.0
                    + x_offset_60deg
                    + x_offset_outer
                )
                ax.text(
                    x_pos3,
                    height3 + label_offset + extra_lift,
                    f"{height3:.1f}",
                    ha="center",
                    va="bottom",
                    fontsize=label_fontsize,
                    rotation=60,
                    color=color_target,
                    alpha=label_alpha,
                )
            else:
                # Herbie bar label (blue, same style as normal mode)
                rotation2 = 90 if height3 > height2 * 1.01 else 60
                x_pos2 = bars2_list[i].get_x() + bars2_list[i].get_width() / 2.0
                y_pos2 = height2 + label_offset
                if rotation2 == 60:
                    x_pos2 += x_offset_60deg
                else:
                    y_pos2 += 0.5
                # Ensure label doesn't fall below the dotted baseline
                if y_pos2 < baseline_y + label_offset:
                    y_pos2 = baseline_y + label_offset
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

                # Baseline accuracy label: black text, sideways, just below dotted line on the Herbie bar
                x_pos_bl = bars2_list[i].get_x() + bars2_list[i].get_width() / 2.0
                ax.text(
                    x_pos_bl,
                    baseline_y - 3,
                    f"{baseline_y:.1f}",
                    ha="center",
                    va="top",
                    fontsize=label_fontsize,
                    rotation=90,
                    color="black",
                    alpha=label_alpha,
                )

                # Target bar label (60 degrees, on the right)
                x_pos3 = (
                    bars3_list[i].get_x()
                    + bars3_list[i].get_width() / 2.0
                    + x_offset_60deg
                    + x_offset_outer
                )
                y_pos3 = height3 + label_offset
                # Ensure label doesn't fall below the dotted baseline
                if y_pos3 < baseline_y + label_offset:
                    y_pos3 = baseline_y + label_offset
                ax.text(
                    x_pos3,
                    y_pos3,
                    f"{height3:.1f}",
                    ha="center",
                    va="bottom",
                    fontsize=label_fontsize,
                    rotation=60,
                    color=color_target,
                    alpha=label_alpha,
                )

        ax.set_xlim(-0.5, len(names) - 0.5)
        ax.margins(x=0)

        # Legend for compact mode (column-major: entries fill down then right)
        spacer = Patch(facecolor="none", edgecolor="none", label="")
        legend_elements = [
            plt.Line2D(
                [], [], color="black", linestyle=":", linewidth=0.5, label="Original"
            ),
            spacer,
            Patch(facecolor=color_herbie, alpha=0.8, label="Herbie"),
            Patch(facecolor=color_target, alpha=0.8, label="Tamagoyaki"),
        ]

    else:
        # Normal mode: 3 bars
        width = 0.25
        x = np.arange(len(names))

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
            x_pos3 = (
                bar3.get_x() + bar3.get_width() / 2.0 + x_offset_60deg + x_offset_outer
            )
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

        # Legend for normal mode (column-major: entries fill down then right)
        spacer = Patch(facecolor="none", edgecolor="none", label="")
        legend_elements = [
            Patch(facecolor=color_original, alpha=1.0, label="Original"),
            spacer,
            Patch(facecolor=color_herbie, alpha=0.8, label="Herbie"),
            Patch(facecolor=color_target, alpha=0.8, label="Tamagoyaki"),
        ]

    # Remove top and right spines
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    # Customize the plot
    ylim = ax.get_ylim()
    y_range = ylim[1] - ylim[0]
    ax.text(
        -0.5,
        ylim[1] + y_range * 0.09,
        "Accuracy (%)",
        fontsize=6,
        ha="left",
        va="bottom",
    )

    ax.set_xticks(x)
    ax.set_xticklabels(names, rotation=35, ha="right", fontsize=5)

    # Smaller tick labels
    ax.tick_params(axis="both", labelsize=5, pad=2)

    # Fade x-labels for small difference benchmarks
    for i, label in enumerate(ax.get_xticklabels()):
        if small_diff_mask.iloc[i]:
            label.set_alpha(0.3)

    # Legend positioning with smaller font
    ax.legend(
        handles=legend_elements,
        loc="upper right",
        bbox_to_anchor=(1.02, 1.23),
        frameon=False,
        fontsize=5,
        ncol=2,
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
        bracket_y = ylim[0] - y_range * 0.5
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
