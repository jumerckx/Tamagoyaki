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

target_include_directories(cranelift-mlir-opt PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${CMAKE_BINARY_DIR}/cranelift-mlir/include
  ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(cranelift-mlir-opt PRIVATE ${CRANELIFT_MLIR_OPT_LIBS})
add_dependencies(cranelift-mlir-opt
  MLIRCraneliftIncGen
  MLIREquivalenceIncGen
  MLIREmatchIncGen
)
mlir_check_all_link_libraries(cranelift-mlir-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS cranelift-mlir-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
