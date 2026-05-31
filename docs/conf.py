# Configuration file for the Sphinx documentation builder.
#
# Full list of options:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

# -- Path setup --------------------------------------------------------------

DOCS_DIR = Path(__file__).resolve().parent
REPO_ROOT = DOCS_DIR.parent

# -- Project information -----------------------------------------------------

project = "Tamagoyaki"
author = "Tamagoyaki contributors"
copyright = "2026, Tamagoyaki contributors"
release = "0.1.0"
version = "0.1.0"

# -- General configuration ---------------------------------------------------

extensions = [
    "myst_parser",
    "sphinx.ext.intersphinx",
    "sphinx.ext.todo",
    "sphinx_copybutton",
    "sphinx_design",
    "sphinxcontrib.mermaid",
    "breathe",
]

templates_path = ["_templates"]
exclude_patterns = ["_build", "Thumbs.db", ".DS_Store", "doxygen", "README.md"]

# Source file types: Markdown (MyST) + reStructuredText
source_suffix = {
    ".rst": "restructuredtext",
    ".md": "markdown",
}

# Default to Markdown for the root document.
root_doc = "index"

# -- MyST configuration ------------------------------------------------------

myst_enable_extensions = [
    "colon_fence",
    "deflist",
    "fieldlist",
    "tasklist",
    "attrs_inline",
    "attrs_block",
    "linkify",
    "smartquotes",
    "substitution",
]
myst_heading_anchors = 3

# -- Intersphinx -------------------------------------------------------------

intersphinx_mapping = {
    "python": ("https://docs.python.org/3", None),
}

# -- Breathe (Doxygen integration) -------------------------------------------

os.environ.setdefault("TAMAGOYAKI_BUILD_DIR", str(REPO_ROOT / "build"))

breathe_projects = {
    "tamagoyaki": str(DOCS_DIR / "doxygen" / "xml"),
}
breathe_default_project = "tamagoyaki"
breathe_default_members = ("members", "undoc-members")

# -- Run Doxygen on Read the Docs / CI ---------------------------------------


def _maybe_run_tablegen() -> None:
    """Generate TableGen headers if a configured build directory exists."""
    build_dir = Path(os.environ.get("TAMAGOYAKI_BUILD_DIR", REPO_ROOT / "build"))
    if not (build_dir / "CMakeCache.txt").exists():
        print(
            "warning: TableGen outputs not found (no CMakeCache.txt). "
            "Set TAMAGOYAKI_BUILD_DIR to your configured build directory.",
            file=sys.stderr,
        )
        return

    targets = [
        "MLIREquivalenceIncGen",
        "MLIREmatchIncGen",
        "MLIRHerbieMLIRIncGen",
        "MLIRCraneliftIncGen",
        "MLIRRoverIncGen",
    ]
    try:
        subprocess.run(
            ["cmake", "--build", str(build_dir), "--target", *targets],
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        print(f"warning: failed to run TableGen targets: {exc}", file=sys.stderr)
        return

    expected = [
        build_dir / "include" / "EmatchDialect.h.inc",
        build_dir / "include" / "EquivalenceDialect.h.inc",
    ]
    if not all(path.exists() for path in expected):
        missing = ", ".join(str(path) for path in expected if not path.exists())
        print(
            "warning: missing TableGen headers: "
            f"{missing}. Docs may warn about missing declarations.",
            file=sys.stderr,
        )


# -- Generated dialect reference ---------------------------------------------

# Each entry maps a dialect to the markdown files produced by mlir-tblgen via
# add_mlir_doc() (see cmake/TableGenHelpers.cmake). `dialect_doc` is the
# -gen-dialect-doc output (ops/types/attrs) or None for passes-only dialects;
# `pass_doc` is the -gen-pass-doc output. The assembled page is written to
# docs/dialects/<slug>.md and listed in docs/dialects/index.md.
DIALECT_DOCS = [
    ("equivalence", "Equivalence dialect", "EquivalenceDialect.md", "EquivalencePasses.md"),
    ("ematch", "Ematch dialect", "EmatchDialect.md", "EmatchPasses.md"),
    ("herbie", "HerbieMLIR dialect", "HerbieMLIRDialect.md", "HerbieMLIRPasses.md"),
    ("cranelift", "Cranelift passes", None, "CraneliftPasses.md"),
    ("rover", "Rover passes", None, "RoverPasses.md"),
]


def _read_generated(docs_src: Path, name: str | None) -> str | None:
    """Read a mlir-tblgen markdown file, dropping the Hugo-only `[TOC]` marker."""
    if name is None:
        return None
    path = docs_src / name
    if not path.exists():
        return None
    lines = [line for line in path.read_text().splitlines() if line.strip() != "[TOC]"]
    return "\n".join(lines).strip()


def _generate_dialect_docs() -> None:
    """Build the `mlir-doc` target and assemble per-dialect reference pages.

    Writes one page per dialect into docs/dialects/. When the generated
    markdown is unavailable (no build dir, Doxygen-only run, etc.) a stub page
    is written so the toctree in docs/dialects/index.md never breaks the build.
    """
    out_dir = DOCS_DIR / "dialects"
    out_dir.mkdir(parents=True, exist_ok=True)

    build_dir = Path(os.environ.get("TAMAGOYAKI_BUILD_DIR", REPO_ROOT / "build"))
    docs_src = build_dir / "docs" / "Dialects"
    if (build_dir / "CMakeCache.txt").exists():
        try:
            subprocess.run(
                ["cmake", "--build", str(build_dir), "--target", "mlir-doc"],
                check=True,
            )
        except (FileNotFoundError, subprocess.CalledProcessError) as exc:
            print(f"warning: failed to build mlir-doc target: {exc}", file=sys.stderr)
    else:
        print(
            "warning: dialect docs not generated (no CMakeCache.txt). "
            "Set TAMAGOYAKI_BUILD_DIR to a configured build directory.",
            file=sys.stderr,
        )

    for slug, title, dialect_doc, pass_doc in DIALECT_DOCS:
        dialect_md = _read_generated(docs_src, dialect_doc)
        pass_md = _read_generated(docs_src, pass_doc)

        if dialect_md is None and pass_md is None:
            (out_dir / f"{slug}.md").write_text(
                f"# {title}\n\n"
                "```{warning}\n"
                "The generated reference for this dialect is unavailable. Build it "
                "with `cmake --build <build-dir> --target mlir-doc`.\n"
                "```\n"
            )
            continue

        # When -gen-dialect-doc output is present it already carries the page's
        # H1 (`# '<name>' Dialect`); otherwise synthesise one for passes-only
        # dialects so the page has a title for the toctree.
        sections: list[str] = []
        if dialect_md is not None:
            sections.append(dialect_md)
        else:
            sections.append(f"# {title}")
        if pass_md is not None:
            sections.append("## Passes\n\n" + pass_md)

        (out_dir / f"{slug}.md").write_text("\n\n".join(sections) + "\n")


def _ensure_breathe_stub() -> None:
    """Write a minimal Doxygen XML index so Breathe never crashes.

    Breathe requires `index.xml` to exist even before resolving directives.
    When Doxygen isn't installed (e.g. during a quick local prose-only
    build), we drop in an empty stub. A real Doxygen run will overwrite it.
    """
    xml_dir = DOCS_DIR / "doxygen" / "xml"
    index = xml_dir / "index.xml"
    if index.exists():
        return
    xml_dir.mkdir(parents=True, exist_ok=True)
    index.write_text(
        '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n'
        '<doxygenindex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"'
        ' version="1.9.0" />\n'
    )


def _resolved_doxyfile() -> Path:
    """Create a Doxygen config with the build dir baked in."""
    doxyfile = DOCS_DIR / "Doxyfile"
    content = doxyfile.read_text()
    build_dir = Path(os.environ.get("TAMAGOYAKI_BUILD_DIR", REPO_ROOT / "build"))
    content = content.replace("@TAMAGOYAKI_BUILD_DIR@", str(build_dir))

    resolved = DOCS_DIR / "_build" / "Doxyfile"
    resolved.parent.mkdir(parents=True, exist_ok=True)
    resolved.write_text(content)
    return resolved


def _run_doxygen() -> None:
    """Run Doxygen to generate the XML consumed by Breathe."""
    doxyfile = DOCS_DIR / "Doxyfile"
    if not doxyfile.exists():
        return
    try:
        subprocess.run(
            ["doxygen", str(_resolved_doxyfile())],
            cwd=DOCS_DIR,
            check=True,
        )
    except (FileNotFoundError, subprocess.CalledProcessError) as exc:
        print(f"warning: failed to run Doxygen: {exc}", file=sys.stderr)


# Always (re)generate Doxygen XML when building. This keeps GitHub Actions
# and local builds in sync without an extra build step.
if os.environ.get("SKIP_DOXYGEN") != "1":
    _maybe_run_tablegen()
    _run_doxygen()
_generate_dialect_docs()
_ensure_breathe_stub()

# -- Pygments lexers ---------------------------------------------------------
# Pygments has no built-in MLIR lexer. Reuse the LLVM IR lexer for ```mlir
# fenced code blocks so highlighting works and Sphinx stops warning about an
# unknown lexer name.
from pygments.lexers.asm import LlvmLexer  # noqa: E402


class MlirLexer(LlvmLexer):
    name = "MLIR"
    aliases = ["mlir"]
    filenames = ["*.mlir"]


def setup(app):
    from sphinx.highlighting import lexers

    lexers["mlir"] = MlirLexer()


# -- HTML output -------------------------------------------------------------

html_theme = "furo"
html_title = "Tamagoyaki"
html_static_path = ["_static"]
html_logo = "../tamagoyaki.png"
html_favicon = "../tamagoyaki.png"

html_theme_options = {
    "sidebar_hide_name": False,
    "navigation_with_keys": True,
    "source_repository": "https://github.com/jumerckx/tamagoyaki/",
    "source_branch": "main",
    "source_directory": "docs/",
    "footer_icons": [
        {
            "name": "GitHub",
            "url": "https://github.com/jumerckx/tamagoyaki",
            "html": (
                '<svg stroke="currentColor" fill="currentColor" stroke-width="0" '
                'viewBox="0 0 16 16"><path fill-rule="evenodd" d="M8 0C3.58 0 0 '
                "3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 "
                "0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94"
                "-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 "
                "1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 "
                "0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 "
                "2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 "
                "2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 "
                "0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 "
                "1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42"
                '-3.58-8-8-8z"></path></svg>'
            ),
            "class": "",
        },
    ],
}

# -- Misc --------------------------------------------------------------------

todo_include_todos = True
# Breathe emits cross-references to Doxygen-generated file pages and to LLVM/MLIR
# C++ symbols that are not part of this project's documentation. Suppress those
# unresolvable reference warnings so the build stays clean.
suppress_warnings = [
    "myst.header",
    "ref.ref",
    "ref.cpp",
    "ref.identifier",
]
