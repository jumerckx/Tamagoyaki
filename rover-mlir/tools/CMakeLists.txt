# rover-mlir-opt executable

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(ROVER_MLIR_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  CIRCTComb
  # Transform libs: --comb-int-range-narrowing over a persisted e-graph is part
  # of the rover evaluation, and circt-opt cannot run it (no equivalence
  # dialect), so rover-mlir-opt registers the CIRCT passes itself.
  CIRCTCombTransforms
  CIRCTHW
  CIRCTDatapath
  CIRCTDatapathTransforms
  RoverDialect
  MLIREquivalence
  MLIREmatch
)

add_llvm_executable(rover-mlir-opt rover-mlir-opt.cpp)
llvm_update_compile_flags(rover-mlir-opt)

# Tamagoyaki's include directories come through MLIREquivalence/MLIREmatch.
target_include_directories(rover-mlir-opt PRIVATE
  ${ROVER_MLIR_SOURCE_DIR}/include
  ${ROVER_MLIR_BINARY_DIR}/include
  ${CIRCT_INCLUDE_DIRS}
)

target_link_libraries(rover-mlir-opt PRIVATE ${ROVER_MLIR_OPT_LIBS})
# Only rover-mlir's own tablegen target. Tamagoyaki's .inc files are either
# built by its IncGen targets (in-tree, ordered by the link to MLIREquivalence)
# or already installed (standalone); MLIREquivalenceIncGen does not exist out
# of tree.
add_dependencies(rover-mlir-opt MLIRRoverIncGen)
mlir_check_all_link_libraries(rover-mlir-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS rover-mlir-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
