"""
Record the environment behind an evaluation run.
"""

from __future__ import annotations

import datetime
import hashlib
import os
import platform
import subprocess
from pathlib import Path

__all__ = ["cmd", "cpu_model", "field", "host_fields", "render", "sha256", "write"]

#: Values are aligned at this column, wide enough for the longest key in use
#: (``max_saturation_iters:``). Shared so the two manifests stay comparable.
FIELD_WIDTH = 22


def field(name: str, value: object) -> str:
    return f"{name + ':':<{FIELD_WIDTH}}{value}"


def cmd(args: list[str], *, drop: int = 0, keep: int | None = None) -> str:
    """A command's output as one manifest field.

    Tools disagree on which stream a ``--version`` goes to, so both are read,
    and on how much preamble to print before the version itself:

      * LLVM-based tools (``*-mlir-opt``, ``circt-*``) open with a bare
        ``LLVM (http://llvm.org/):`` banner and put the version, the build type
        and any downstream project's version on the lines *after* it.
      * ABC echoes the command it was given (``======== ABC command line
        "version"``) before answering it.

    So `drop` skips that many leading lines. What remains is stripped and
    joined onto one line, since the manifest is one field per line; `keep`
    bounds how many lines are taken, for probes that answer a failure with a
    backtrace rather than a version.
    """
    try:
        r = subprocess.run(args, check=False, capture_output=True, text=True)
        out = r.stdout or r.stderr
        lines = [ln.strip() for ln in out.strip().splitlines() if ln.strip()]
        lines = lines[drop:][:keep]
        return "; ".join(lines)
    except Exception as e:
        return f"<unavailable: {e}>"


#: Leading lines to drop from an LLVM tool's --version (the banner).
LLVM_BANNER = 1


def cpu_model() -> str:
    try:
        for line in open("/proc/cpuinfo"):
            if line.startswith("model name"):
                return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return cmd(["sysctl", "-n", "machdep.cpu.brand_string"]) or "<unknown>"


def sha256(path: str | Path) -> str:
    """Digest of an input file, for the ones that are vendored rather than
    pinned by the flake (Rover's cell library)."""
    try:
        return hashlib.sha256(Path(path).read_bytes()).hexdigest()
    except Exception as e:
        return f"<unavailable: {e}>"


def host_fields(repo_root: str | Path) -> list[tuple[str, str]]:
    """The environment prefix every manifest starts with."""
    baked_rev = os.environ.get("TAMAGOYAKI_GIT_REV")
    if baked_rev:
        git_rev = baked_rev
    else:
        rev = cmd(["git", "-C", str(repo_root), "rev-parse", "HEAD"])
        dirty = cmd(["git", "-C", str(repo_root), "status", "--porcelain"])
        git_rev = f"{rev}{'  (DIRTY WORKING TREE)' if dirty else ''}"
    now = datetime.datetime.now(datetime.UTC).isoformat()
    return [
        ("generated_utc", now),
        ("git_rev", git_rev),
        ("host", platform.node()),
        ("platform", platform.platform()),
        ("cpu", f"{cpu_model()}  x{os.cpu_count()}"),
        ("python", platform.python_version()),
        ("snakemake", cmd(["snakemake", "--version"])),
    ]


def render(
    *,
    title: str,
    repo_root: str | Path,
    fields: list[tuple[str, object]],
    parameters: list[tuple[str, object]],
) -> str:
    """The manifest text. `fields` follow the shared host block; `parameters`
    go under a ``[parameters]`` heading."""
    lines = [f"# {title}"]
    lines += [field(k, v) for k, v in host_fields(repo_root) + list(fields)]
    lines += ["", "[parameters]"]
    lines += [field(k, v) for k, v in parameters]
    lines += [""]
    return "\n".join(lines)


def write(path: str | Path, **kwargs) -> str:
    """render() to `path`, echoing it so a run's log carries it too."""
    text = render(**kwargs)
    Path(path).write_text(text)
    print(text)
    return text
