import os

import lit.formats
from lit.llvm import llvm_config

config.name = "herbie-mlir"
config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)
config.suffixes = ['.mlir']

config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.path.join(config.tamagoyaki_obj_root, "herbie_mlir", "test", "lit")

llvm_config.use_default_substitutions()

tool_dirs = [os.path.join(config.tamagoyaki_obj_root, "bin"), config.llvm_tools_dir]
tools = ["herbie-mlir-opt", "tamagoyaki-opt"]

llvm_config.add_tool_substitutions(tools, tool_dirs)
