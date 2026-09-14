import os

import lit.formats
from lit.llvm import llvm_config

config.name = "cranelift-mlir"
config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)
config.suffixes = ['.mlir']

config.test_source_root = os.path.dirname(__file__)
# config.test_exec_root comes from the site config: this suite is built both as
# part of the Tamagoyaki tree and standalone, and the two put it in different
# places, so CMake is the one that knows.

llvm_config.use_default_substitutions()

tool_dirs = [
    config.cranelift_tools_dir,
    config.tamagoyaki_tools_dir,
    config.llvm_tools_dir,
]
tools = ["cranelift-mlir-opt", "tamagoyaki-opt"]

llvm_config.add_tool_substitutions(tools, tool_dirs)
