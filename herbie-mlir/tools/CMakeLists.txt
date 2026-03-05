# herbie-mlir-opt executable

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

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

# Combine all generated headers this executable depends on
set(HERBIE_MLIR_OPT_GENERATED_HEADERS
  ${HERBIE_MLIR_GENERATED_HEADERS}
  ${EQUIVALENCE_GENERATED_HEADERS}
  ${EMATCH_GENERATED_HEADERS}
)

set_source_object_depends(
  SOURCES herbie-mlir-opt.cpp
  DEPENDS ${HERBIE_MLIR_OPT_GENERATED_HEADERS}
)

add_llvm_executable(herbie-mlir-opt herbie-mlir-opt.cpp)
llvm_update_compile_flags(herbie-mlir-opt)

target_include_directories(herbie-mlir-opt PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(herbie-mlir-opt PRIVATE ${HERBIE_MLIR_OPT_LIBS})
add_dependencies(herbie-mlir-opt
  MLIRHerbieMLIRIncGen
  MLIREquivalenceIncGen
  MLIREmatchIncGen
  buildRival
  copy_herbiemlir_generated_td_to_src_include
  copy_equivalence_generated_td_to_src_include
  copy_ematch_generated_td_to_src_include
)
mlir_check_all_link_libraries(herbie-mlir-opt)
