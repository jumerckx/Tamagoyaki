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
    match = re.search(r':filename\s+"([^"]+)"', target_prog)
    if not match:
        raise ValueError(f"Could not extract filename from target_prog: {target_prog}")
    return match.group(1)


def extract_optimize_timing(timing_path: Path) -> tuple[str, str]:
    """Extract LoadPDL and processFunctions durations from a tamagoyaki timing JSON file.

    Looks for the top-level "HerbieOptimizePass" entry and extracts its
    "LoadPDL" and "processFunctions" children's wall-clock durations.

    Args:
        timing_path: Path to the timing JSON file.

    Returns:
        A tuple of (load_pdl_duration, process_functions_duration) as strings (in seconds).

    Raises:
        FileNotFoundError: If the timing file does not exist.
        ValueError: If the timing data is invalid or required entries are missing.
    """
    if not timing_path.exists():
        raise FileNotFoundError(f"Timing file not found: {timing_path}")

    with open(timing_path) as f:
        timing_data: Any = json.load(f)

    if not isinstance(timing_data, list):
        raise ValueError(
            f"Expected timing data to be a list, got {type(timing_data).__name__}"
        )

    for entry in timing_data:
        if isinstance(entry, dict) and entry.get("name") == "HerbieOptimizePass":
            load_pdl: str | None = None
            process_functions: str | None = None

            for sub_pass in entry.get("passes", []):
                if not isinstance(sub_pass, dict):
                    continue
                wall: Any = sub_pass.get("wall")
                if not isinstance(wall, dict) or "duration" not in wall:
                    continue
                if sub_pass.get("name") == "LoadPDL":
                    load_pdl = str(wall["duration"])
                elif sub_pass.get("name") == "processFunctions":
                    process_functions = str(wall["duration"])

            if load_pdl is None:
                raise ValueError(f"No 'LoadPDL' entry found in HerbieOptimizePass in {timing_path}")
            if process_functions is None:
                raise ValueError(f"No 'processFunctions' entry found in HerbieOptimizePass in {timing_path}")

            return load_pdl, process_functions

    raise ValueError(f"No 'HerbieOptimizePass' entry found in {timing_path}")


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


def extract_saturation_time(timing_path: Path) -> tuple[str, str]:
    """Extract the runSaturation wall-clock duration and total match time from a tamagoyaki timing JSON file.

    Args:
        timing_path: Path to the timing JSON file.

    Returns:
        A tuple of (saturation_duration, match_duration) as strings.

    Raises:
        FileNotFoundError: If the timing file does not exist.
        ValueError: If the timing data is invalid or runSaturation entry is missing.
    """
    if not timing_path.exists():
        raise FileNotFoundError(f"Timing file not found: {timing_path}")

    with open(timing_path) as f:
        timing_data: Any = json.load(f)

    if not isinstance(timing_data, list):
        raise ValueError(
            f"Expected timing data to be a list, got {type(timing_data).__name__}"
        )

    for entry in timing_data:
        if isinstance(entry, dict) and entry.get("name") == "runSaturation":
            wall: Any = entry.get("wall")
            if not isinstance(wall, dict) or "duration" not in wall:
                continue
            saturation_duration = str(wall["duration"])

            # Sum up match durations across all iterations
            match_total: float = 0.0
            passes: Any = entry.get("passes", [])
            for iteration in passes:
                if not isinstance(iteration, dict):
                    continue
                for sub_pass in iteration.get("passes", []):
                    if isinstance(sub_pass, dict) and sub_pass.get("name") == "match":
                        sub_wall: Any = sub_pass.get("wall")
                        if isinstance(sub_wall, dict) and "duration" in sub_wall:
                            match_total += float(sub_wall["duration"])

            return saturation_duration, str(match_total)

    raise ValueError(f"No 'runSaturation' entry found in {timing_path}")


def extract_accuracies(
    json_file: str, optimize_timing_dir: str, saturation_timing_dir: str
) -> None:
    """Extract accuracy metrics from a Herbie results JSON file and output as CSV.

    Args:
        json_file: Path to the JSON results file.
        optimize_timing_dir: Directory containing optimize timing JSON files.
        saturation_timing_dir: Directory containing saturation timing JSON files.

    Raises:
        KeyError: If required fields are missing from the JSON.
        ValueError: If data format is invalid.
        FileNotFoundError: If required files are not found.
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
            "optimize_load_pdl_time",
            "optimize_process_functions_time",
            "herbie_wo_sampling",
            "herbie_sampling",
            "saturation_time_joint",
            "match_time_joint",
            "saturation_time_individual",
            "match_time_individual",
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

        filename: str = extract_filename_from_target_prog(target_prog)

        # Extract optimization timing from tamagoyaki timing JSON
        try:
            load_pdl_time, process_functions_time = extract_optimize_timing(
                Path(optimize_timing_dir) / f"{filename}.json"
            )
        except (ValueError, FileNotFoundError) as e:
            raise ValueError(f"Test {i} ({name}): {e}")

        # Extract Herbie timing data from timeline.json
        try:
            herbie_eval_dir: Path = Path(json_file).parent
            timeline_path: Path = herbie_eval_dir / link / "timeline.json"
            herbie_wo_sampling, herbie_sampling = extract_herbie_timings(timeline_path)
        except (ValueError, FileNotFoundError) as e:
            raise ValueError(f"Test {i} ({name}): {e}")

        # Extract saturation timing data
        try:
            timing_dir: Path = Path(saturation_timing_dir)
            saturation_time_joint, match_time_joint = extract_saturation_time(
                timing_dir / f"{filename}_joint.json"
            )
            saturation_time_individual, match_time_individual = extract_saturation_time(
                timing_dir / f"{filename}_individual.json"
            )
        except (ValueError, FileNotFoundError) as e:
            raise ValueError(f"Test {i} ({name}): {e}")

        writer.writerow(
            {
                "name": name,
                "link": link,
                "original_accuracy_bits": start,
                "optimized_accuracy_bits": end,
                "target_accuracy_bits": target,
                "optimize_load_pdl_time": load_pdl_time,
                "optimize_process_functions_time": process_functions_time,
                "herbie_wo_sampling": herbie_wo_sampling,
                "herbie_sampling": herbie_sampling,
                "saturation_time_joint": saturation_time_joint,
                "match_time_joint": match_time_joint,
                "saturation_time_individual": saturation_time_individual,
                "match_time_individual": match_time_individual,
            }
        )


def main() -> None:
    """Main entry point."""
    if len(sys.argv) != 4:
        print(
            "Usage: python extract_accuracies.py <json_file> <optimize_timing_dir> <saturation_timing_dir>",
            file=sys.stderr,
        )
        sys.exit(1)

    json_file = sys.argv[1]
    optimize_timing_dir = sys.argv[2]
    saturation_timing_dir = sys.argv[3]

    if not Path(json_file).exists():
        print(f"Error: File not found: {json_file}", file=sys.stderr)
        sys.exit(1)

    if not Path(optimize_timing_dir).is_dir():
        print(f"Error: Directory not found: {optimize_timing_dir}", file=sys.stderr)
        sys.exit(1)

    if not Path(saturation_timing_dir).is_dir():
        print(
            f"Error: Directory not found: {saturation_timing_dir}", file=sys.stderr
        )
        sys.exit(1)

    extract_accuracies(json_file, optimize_timing_dir, saturation_timing_dir)


def entry() -> None:
    sys.exit(main())


if __name__ == "__main__":
    entry()
