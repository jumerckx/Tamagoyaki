# -*- Python -*-

import os

import lit.formats
from lit.llvm import llvm_config

# Configuration file for the 'lit' test runner.

config.name = "MATCH"

config.test_format = lit.formats.ShTest(not llvm_config.use_lit_shell)

config.suffixes = [".mlir"]

config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = config.match_obj_root

llvm_config.with_system_environment(["HOME", "INCLUDE", "LIB", "TMP", "TEMP"])

llvm_config.use_default_substitutions()

config.excludes = ["Inputs", "CMakeLists.txt", "README.txt", "LICENSE.txt"]

llvm_config.with_environment("PATH", config.llvm_tools_dir, append_path=True)

tool_dirs = [os.path.join(config.tamagoyaki_obj_root, "bin"), config.llvm_tools_dir]
llvm_config.add_tool_substitutions(["tamagoyaki-opt"], tool_dirs)
