"""Record the environment behind an evaluation run.

A figure or a table is only reproducible if it can be traced back to a commit,
a toolchain and a parameter set, so every pipeline writes a manifest next to
its results. The first block -- when, which commit, which host, which Python
and Snakemake -- is the same for all of them and lives here; each pipeline adds
its own tool versions and its own ``[parameters]`` section::

    provenance.write(
        output[0],
        title="Tamagoyaki / Rover datapath evaluation provenance",
        repo_root=REPO_ROOT,
        fields=[("rover_mlir_opt", rover_opt), ...],
        parameters=[("max_iters", MAX_ITERS), ...],
    )

Nothing here raises: a manifest that fails to write because ``abc --version``
misbehaved would fail a run that has already produced its numbers. Values that
cannot be determined are recorded as ``<unavailable: ...>``, which is itself
provenance.
"""

from __future__ import annotations

import datetime
import hashlib
import os
import platform
import subprocess
from pathlib import Path

__all__ = ["cmd", "cpu_model", "sha256", "field", "host_fields", "render", "write"]

#: Values are aligned at this column, wide enough for the longest key in use
#: (``max_saturation_iters:``). Shared so the two manifests stay comparable.
FIELD_WIDTH = 22


def field(name: str, value: object) -> str:
    return f"{name + ':':<{FIELD_WIDTH}}{value}"


def cmd(args: list[str]) -> str:
    """First line of a command's output, for version probes. Tools disagree on
    which stream a ``--version`` goes to, so both are accepted."""
    try:
        r = subprocess.run(args, capture_output=True, text=True)
        out = r.stdout or r.stderr
        return out.strip().splitlines()[0] if out.strip() else ""
    except Exception as e:
        return f"<unavailable: {e}>"


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
    git_rev = cmd(["git", "-C", str(repo_root), "rev-parse", "HEAD"])
    dirty = cmd(["git", "-C", str(repo_root), "status", "--porcelain"])
    now = datetime.datetime.now(datetime.timezone.utc).isoformat()
    return [
        ("generated_utc", now),
        ("git_rev", f"{git_rev}{'  (DIRTY WORKING TREE)' if dirty else ''}"),
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
