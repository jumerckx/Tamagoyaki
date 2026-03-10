import csv
import json
import re
import sys
from pathlib import Path
from typing import Any, TypedDict, cast


class TestResult(TypedDict, total=False):
    """Type for individual test result entries."""

    name: str
    link: str
    start: float
    end: float
    target: list[list[float]] | list[Any]


class ResultData(TypedDict, total=False):
    """Type for the top-level results data."""

    tests: list[TestResult]


def extract_filename_from_target_prog(target_prog: str) -> str:
    """Extract filename from target_prog field.

    Args:
        target_prog: The target_prog field containing a filename in a Racket-like structure.

    Returns:
        The extracted filename.

    Raises:
        ValueError: If filename cannot be extracted.
    """
    # Extract filename from patterns like "(((! :filename \"nmse-problem-3.4.4_pi_false\" ..."
    match = re.search(r':filename\s+"([^"]+)"', target_prog)
    if not match:
        raise ValueError(f"Could not extract filename from target_prog: {target_prog}")
    return match.group(1)


def extract_snakemake_tsv_timing(tsv_path: Path) -> str:
    """Extract the timing value from the first column of a TSV file.

    Args:
        tsv_path: Path to the TSV file.

    Returns:
        The first column value from the second row as a string.

    Raises:
        FileNotFoundError: If the TSV file does not exist.
        ValueError: If the TSV file is malformed.
    """
    if not tsv_path.exists():
        raise FileNotFoundError(f"TSV file not found: {tsv_path}")

    with open(tsv_path) as f:
        lines = f.readlines()

    if len(lines) < 2:
        raise ValueError(f"TSV file has fewer than 2 lines: {tsv_path}")

    # Skip header, get first data row
    first_data_row = lines[1].strip()
    if not first_data_row:
        raise ValueError(f"Second row of TSV file is empty: {tsv_path}")

    # Split by tab and get first column
    columns = first_data_row.split("\t")
    if not columns:
        raise ValueError(f"Could not parse TSV file: {tsv_path}")

    return columns[0]


def extract_timing_report_tsv(timing_report_path: Path) -> str:
    """Extract the timing value from a timing report TSV file."""
    if not timing_report_path.exists():
        raise FileNotFoundError(f"TSV file not found: {timing_report_path}")

    with open(timing_report_path) as f:
        lines = f.readlines()

    if len(lines) < 1:
        raise ValueError(f"TSV file has fewer than 2 lines: {timing_report_path}")
    # Skip header, get first data row
    first_data_row = lines[0].strip()
    if not first_data_row:
        raise ValueError(f"First row of TSV file is empty: {timing_report_path}")

    # Split by tab and get first column
    columns = first_data_row.split("\t")
    if not columns:
        raise ValueError(f"Could not parse TSV file: {timing_report_path}")

    return columns[1]


def extract_target_accuracy(target: Any) -> str:
    """Extract the first target accuracy from the target array.

    Args:
        target: The target field from a test, typically a list of [cost, accuracy] pairs.

    Returns:
        The first accuracy value as a string.

    Raises:
        ValueError: If target is not a valid list with at least one [cost, accuracy] pair.
    """
    if not isinstance(target, list):
        raise ValueError(f"Expected target to be a list, got {type(target).__name__}")

    target_list: list[Any] = cast(list[Any], target)

    if len(target_list) == 0:
        raise ValueError("Target array is empty")

    first_target: Any = target_list[0]
    if not isinstance(first_target, (list, tuple)):
        raise ValueError(
            f"Expected target[0] to be a list or tuple, got {type(first_target).__name__}"
        )

    first_target_list: list[Any] = cast(list[Any], first_target)
    if len(first_target_list) < 2:
        raise ValueError(
            f"Expected target[0] to have at least 2 elements, got {len(first_target_list)}"
        )

    accuracy: float = cast(float, first_target_list[1])
    return str(accuracy)


def extract_herbie_timings(timeline_path: Path) -> tuple[str, str]:
    """Extract Herbie timing data from a timeline.json file.

    Args:
        timeline_path: Path to the timeline.json file.

    Returns:
        A tuple of (herbie_wo_sampling, herbie_sampling) as strings.

    Raises:
        FileNotFoundError: If the timeline.json file does not exist.
        ValueError: If the timeline data is invalid.
    """
    if not timeline_path.exists():
        raise FileNotFoundError(f"Timeline file not found: {timeline_path}")

    with open(timeline_path) as f:
        timeline_data: Any = json.load(f)

    if not isinstance(timeline_data, list):
        raise ValueError(
            f"Expected timeline to be a list, got {type(timeline_data).__name__}"
        )

    timeline: list[Any] = cast(list[Any], timeline_data)
    herbie_wo_sampling: float = 0.0
    herbie_sampling: float = 0.0

    for entry in timeline:
        if not isinstance(entry, dict):
            raise ValueError(
                f"Expected timeline entry to be a dict, got {type(entry).__name__}"
            )

        entry_dict: dict[str, Any] = cast(dict[str, Any], entry)
        entry_type: Any = entry_dict.get("type")
        entry_time: Any = entry_dict.get("time")

        if entry_time is None:
            continue

        try:
            time_value: float = float(entry_time)
        except (TypeError, ValueError):
            raise ValueError(f"Could not convert time value to float: {entry_time}")

        if entry_type == "sample":
            herbie_sampling += time_value
        else:
            herbie_wo_sampling += time_value

    return str(herbie_wo_sampling), str(herbie_sampling)


def extract_accuracies(json_file: str, results_dir: str = "results") -> None:
    """Extract accuracy metrics from a Herbie results JSON file and output as CSV.

    Args:
        json_file: Path to the JSON results file.
        results_dir: Base directory for results (default: "results").

    Raises:
        KeyError: If required fields are missing from the JSON.
        ValueError: If data format is invalid.
        FileNotFoundError: If TSV files are not found.
    """
    with open(json_file) as f:
        data: dict[str, Any] = json.load(f)

    writer = csv.DictWriter(
        sys.stdout,
        fieldnames=[
            "name",
            "link",
            "original_accuracy_bits",
            "optimized_accuracy_bits",
            "target_accuracy_bits",
            "eqsat_saturation",
            "eqsat_total",
            "herbie_wo_sampling",
            "herbie_sampling",
        ],
    )
    writer.writeheader()

    tests: list[dict[str, Any]] = data["tests"]
    for i, test in enumerate(tests):
        try:
            name: str = str(test["name"])
            link: str = str(test["link"])
            start: str = str(test["start"])
            end: str = str(test["end"])
            target: str = extract_target_accuracy(test["target"])
            target_prog: str = str(test["target-prog"])
        except KeyError as e:
            raise KeyError(f"Test {i}: Missing required field {e}")

        # Extract timing data from TSV files
        try:
            filename: str = extract_filename_from_target_prog(target_prog)
            eqsat_saturate_timing: float = float(
                extract_timing_report_tsv(
                    Path(results_dir) / "saturated" / f"{filename}_timing_report.tsv"
                )
            )
            eqsat_herbie_timing: float = float(
                extract_snakemake_tsv_timing(
                    Path(results_dir) / "saturated" / f"{filename}.tsv"
                )
            )
            extract_timing: float = float(
                extract_snakemake_tsv_timing(
                    Path(results_dir) / "optimized" / f"{filename}.tsv"
                )
            )
            eqsat_timing: str = str(eqsat_herbie_timing + extract_timing)
        except (ValueError, FileNotFoundError) as e:
            raise ValueError(f"Test {i} ({name}): {e}")

        # Extract Herbie timing data from timeline.json
        try:
            herbie_eval_dir: Path = Path(json_file).parent
            timeline_path: Path = herbie_eval_dir / link / "timeline.json"
            herbie_wo_sampling, herbie_sampling = extract_herbie_timings(timeline_path)
        except (ValueError, FileNotFoundError) as e:
            raise ValueError(f"Test {i} ({name}): {e}")

        writer.writerow(
            {
                "name": name,
                "link": link,
                "original_accuracy_bits": start,
                "optimized_accuracy_bits": end,
                "target_accuracy_bits": target,
                "eqsat_saturation": eqsat_saturate_timing,
                "eqsat_total": eqsat_timing,
                "herbie_wo_sampling": herbie_wo_sampling,
                "herbie_sampling": herbie_sampling,
            }
        )


def main() -> None:
    """Main entry point."""
    if len(sys.argv) != 2:
        print("Usage: python extract_accuracies.py <json_file>", file=sys.stderr)
        sys.exit(1)

    json_file = sys.argv[1]

    if not Path(json_file).exists():
        print(f"Error: File not found: {json_file}", file=sys.stderr)
        sys.exit(1)

    extract_accuracies(json_file)


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
