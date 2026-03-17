# rover-mlir-opt executable

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(ROVER_MLIR_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  Comb
  DatapathDialect
  HWDialect
  RoverDialect
  MLIREquivalence
  MLIREmatch
)

# Combine all generated headers this executable depends on
set(ROVER_MLIR_OPT_GENERATED_HEADERS
  ${COMB_GENERATED_HEADERS}
  ${ROVER_GENERATED_HEADERS}
  ${EQUIVALENCE_GENERATED_HEADERS}
  ${EMATCH_GENERATED_HEADERS}
  ${DATAPATH_GENERATED_HEADERS}
)

set_source_object_depends(
  SOURCES rover-mlir-opt.cpp
  DEPENDS ${ROVER_MLIR_OPT_GENERATED_HEADERS}
)

add_llvm_executable(rover-mlir-opt rover-mlir-opt.cpp)
llvm_update_compile_flags(rover-mlir-opt)

target_include_directories(rover-mlir-opt PRIVATE
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(rover-mlir-opt PRIVATE ${ROVER_MLIR_OPT_LIBS})
add_dependencies(rover-mlir-opt
  # CombIncGen
  MLIREquivalenceIncGen
  MLIREmatchIncGen
  copy_comb_generated_td_to_src_include
  copy_rover_generated_td_to_src_include
  copy_datapath_generated_td_to_src_include
  copy_equivalence_generated_td_to_src_include
  copy_ematch_generated_td_to_src_include
)
mlir_check_all_link_libraries(rover-mlir-opt)
