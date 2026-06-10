# Tamagoyaki documentation

The site is built with [Sphinx](https://www.sphinx-doc.org/) using:

- [Furo](https://pradyunsg.me/furo/) — modern theme.
- [MyST-Parser](https://myst-parser.readthedocs.io/) — Markdown source files.
- [Breathe](https://breathe.readthedocs.io/) + [Doxygen](https://www.doxygen.nl/)
  — auto-generated C++ API reference.

## Local build

The Sphinx toolchain and Doxygen are provided by the `docs` Nix dev shell (the
Python deps come from `pyproject.toml`'s `docs` optional-dependency group, built
via uv2nix):

```shell
nix develop .#docs
make -C docs html
xdg-open docs/_build/html/index.html   # `open` on macOS
```

Set `SKIP_DOXYGEN=1` to skip the C++ extraction step (useful when iterating on
prose only).

## Layout

| Path | Purpose |
|---|---|
| [`conf.py`](conf.py) | Sphinx configuration (extensions, theme, Doxygen). |
| [`Doxyfile`](Doxyfile) | Doxygen settings consumed by Breathe. |
| [`index.md`](index.md) | Landing page and top-level toctree. |
| [`guides/`](guides/) | Freeform Markdown walkthroughs. |
| [`api/`](api/) | Auto-generated C++ API reference. |

## Adding a new freeform guide

1. Create `docs/guides/my-topic.md`.
2. Add `my-topic` to the toctree in [`guides/index.md`](guides/index.md).
3. Rebuild with `make -C docs html`.

## Publishing

The [`Docs` workflow](../.github/workflows/docs.yml) builds the site on every
push to `main` and deploys it to GitHub Pages. To enable hosting, in the
repository settings:

> *Settings → Pages → Build and deployment → Source: **GitHub Actions***
