# herbie-mlir-opt executable

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(HERBIE_MLIR_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  herbieMLIR
  MLIREquivalence
  MLIREmatch
  Rival
  TamagoyakiTiming
)

add_llvm_executable(herbie-mlir-opt herbie-mlir-opt.cpp)
llvm_update_compile_flags(herbie-mlir-opt)

target_include_directories(herbie-mlir-opt PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${CMAKE_BINARY_DIR}/herbie_mlir/include
  ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(herbie-mlir-opt PRIVATE ${HERBIE_MLIR_OPT_LIBS})
add_dependencies(herbie-mlir-opt
  MLIRHerbieMLIRIncGen
  MLIREquivalenceIncGen
  MLIREmatchIncGen
  buildRival
)
mlir_check_all_link_libraries(herbie-mlir-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS herbie-mlir-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
