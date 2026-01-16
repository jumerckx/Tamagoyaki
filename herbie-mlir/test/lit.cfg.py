import lit.formats

# herbie-mlir Lit configuration

config.name = "herbie-mlir"
config.test_format = lit.formats.ShTest(execute_external=False)

# Add paths for tools
config.substitutions = [
    ("%herbie-mlir-opt", "herbie-mlir-opt"),
    ("%tamagoyaki-opt", "tamagoyaki-opt"),
]

# Test suffixes
config.suffixes = ['.mlir']

# Where to find tests
import os
config.test_source_root = os.path.dirname(__file__)
config.test_exec_root = os.path.dirname(__file__)
