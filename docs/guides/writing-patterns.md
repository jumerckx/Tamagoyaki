# Writing rewrite patterns

Rewrite patterns in Tamagoyaki are expressed using MLIR's
[PDL](https://mlir.llvm.org/docs/Dialects/PDLOps/) dialect. This page is a
placeholder for a more complete walkthrough — feel free to expand it.

## Recommended reading

- [PDL dialect documentation](https://mlir.llvm.org/docs/Dialects/PDLOps/)
- [PDL Interpreter dialect](https://mlir.llvm.org/docs/Dialects/PDLInterpOps/)
- The example patterns under `test/` and `herbie_mlir/test/` in the source
  tree.

## Adding new freeform pages

To add another guide:

1. Create a new Markdown file under `docs/guides/`.
2. Add it to the toctree in
   [`docs/guides/index.md`](file:///home/jumerckx/worktrees/Tamagoyaki/faint-fossil/Tamagoyaki/docs/guides/index.md).
3. Rebuild locally with `make -C docs html` (or push to `main` and let the
   GitHub Actions workflow publish it).
