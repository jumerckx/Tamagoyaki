# Snakemake rules shared by the Tamagoyaki evaluations.
#
# Included from the bottom of each pipeline's Snakefile, so everything the
# including workflow defines is already in scope:
#
#     include: str(REPO_ROOT / "tamagoyaki_eval" / "common.smk")
#
# It is addressed by checkout path, not by where tamagoyaki_eval happens to be
# installed: the wrappers already run the pipelines out of a checkout -- main
# Snakefile, rule sources and benchmarks all come from there -- so a fragment of
# the same workflow has to as well.
#
# Contract. The including Snakefile must have defined:
#
#   OUT_DIR        str   the output tree
#   RULES_DIR      str   where the PDL rule sets live (conventionally
#                        f"{OUT_DIR}/01-rules")
#   PAPER_NAME     str   basename of the paper artifact, stage-prefixed like
#                        every other output
#   PAPER_DIR      str   f"{OUT_DIR}/{PAPER_NAME}"
#   PAPER_FIGURES  list  the figures/tables a reader looks at
#   PAPER_DATA     list  the CSV and the manifest behind them
#
# and must constrain the `set` wildcard to its own rule-set names, so that
# `{set}` cannot swallow a path separator.

# ---------------------------------------------------------------------------
# PDL -> PDL-interp
#
# The matcher both e-graph engines load. Regenerating it here is what keeps an
# evaluation independent of any checked-in pdl_interp file.
#
# The "individual" variant compiles each pattern to its own matcher instead of
# one combined automaton; the two exist to be measured against each other, and
# a pipeline that does not compare matchers simply never asks for it.
# ---------------------------------------------------------------------------
rule pdl_to_pdl_interp:
    input:
        f"{RULES_DIR}/{{set}}_pdl.mlir"
    output:
        f"{RULES_DIR}/{{set}}_pdl_interp.mlir"
    shell:
        "xdsl-opt -p 'convert-pdl-to-pdl-interp{{optimize_for_eqsat=true}}' {input} -o {output}"

rule pdl_to_pdl_interp_individual:
    input:
        f"{RULES_DIR}/{{set}}_pdl.mlir"
    output:
        f"{RULES_DIR}/{{set}}_pdl_interp_individual.mlir"
    shell:
        "xdsl-opt -p 'convert-pdl-to-pdl-interp{{optimize_for_eqsat=true convert-individually=true}}'"
        " {input} -o {output}"

# ---------------------------------------------------------------------------
# Paper artifact
#
# Everything a reviewer needs in one directory: the figures, the raw CSV and
# the manifest that says which commit and toolchain produced them.
# `snakemake paper` builds it; the tarball alongside is one file to ship.
# ---------------------------------------------------------------------------
rule paper:
    input:
        figures = PAPER_FIGURES,
        data = PAPER_DATA,
    output:
        directory(PAPER_DIR),
    shell:
        r"""
        mkdir -p {output}/figures
        cp {input.data} {output}/
        cp {input.figures} {output}/figures/
        ( cd {OUT_DIR} && tar -czf {PAPER_NAME}.tar.gz {PAPER_NAME} )
        """

rule clean:
    shell:
        f"rm -rf {OUT_DIR}"

# Cheap, non-measuring rules: never worth scheduling as separate cluster jobs.
localrules: paper, clean
