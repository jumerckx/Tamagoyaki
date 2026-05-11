# rover-mlir-opt executable

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(ROVER_MLIR_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  CIRCTComb
  CIRCTHW
  CIRCTDatapath
  RoverDialect
  MLIREquivalence
  MLIREmatch
)

add_llvm_executable(rover-mlir-opt rover-mlir-opt.cpp)
llvm_update_compile_flags(rover-mlir-opt)

target_include_directories(rover-mlir-opt PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${CMAKE_BINARY_DIR}/rover-mlir/include
  ${PROJECT_SOURCE_DIR}/include
  ${CIRCT_INCLUDE_DIRS}
)

target_link_libraries(rover-mlir-opt PRIVATE ${ROVER_MLIR_OPT_LIBS})
add_dependencies(rover-mlir-opt
  MLIRRoverIncGen
  MLIREquivalenceIncGen
  MLIREmatchIncGen
)
mlir_check_all_link_libraries(rover-mlir-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS rover-mlir-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
