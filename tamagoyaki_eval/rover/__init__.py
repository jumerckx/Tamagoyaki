"""Result analysis for the Rover datapath evaluation.

``rover-mlir/eval/Snakefile`` drives these as console scripts (``rover-abc-stats``,
``rover-results-csv``, ``rover-latex-table``), the way the Herbie pipeline drives
``herbie_mlir/tools``. They read the pipeline's output tree and nothing else, so
they can be run by hand against an existing ``rover-eval-out/``.
"""
