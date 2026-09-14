import os

import lit.formats
from lit.llvm import llvm_config

config.name = "rover-mlir"
config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)
config.suffixes = ['.mlir']

config.test_source_root = os.path.dirname(__file__)
# config.test_exec_root comes from the site config: this suite is built both as
# part of the Tamagoyaki tree and standalone, and the two put it in different
# places, so CMake is the one that knows.

# Fixture files in this directory are inputs to tests, not tests themselves --
# skip them so lit doesn't complain about missing RUN lines. (The rewrite rule
# sets now live in rover-mlir/rules/, outside test_source_root, so they need no
# entry here.)
config.excludes = ["basic.comb.mlir", "Inputs"]

llvm_config.use_default_substitutions()

tool_dirs = [config.rover_tools_dir, config.llvm_tools_dir]
tools = ["rover-mlir-opt"]

llvm_config.add_tool_substitutions(tools, tool_dirs)
