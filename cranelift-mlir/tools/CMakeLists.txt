# cranelift-mlir-opt executable

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(CRANELIFT_MLIR_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  CraneliftDialect
  MLIREquivalence
  MLIREmatch
)

add_llvm_executable(cranelift-mlir-opt cranelift-mlir-opt.cpp)
llvm_update_compile_flags(cranelift-mlir-opt)

# Tamagoyaki's include directories come through MLIREquivalence/MLIREmatch.
target_include_directories(cranelift-mlir-opt PRIVATE
  ${CRANELIFT_MLIR_SOURCE_DIR}/include
  ${CRANELIFT_MLIR_BINARY_DIR}/include
)

target_link_libraries(cranelift-mlir-opt PRIVATE ${CRANELIFT_MLIR_OPT_LIBS})
# Only cranelift-mlir's own tablegen target: Tamagoyaki's .inc files are either
# built by its IncGen targets (in-tree, ordered by the link to MLIREquivalence)
# or already installed (standalone), and MLIREquivalenceIncGen does not exist
# out of tree.
add_dependencies(cranelift-mlir-opt MLIRCraneliftIncGen)
mlir_check_all_link_libraries(cranelift-mlir-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS cranelift-mlir-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
