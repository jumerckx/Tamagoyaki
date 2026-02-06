# Dialect libraries and tamagoyaki-opt executable

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Equivalence Dialect Library
# ============================================================================
set_source_object_depends(
  SOURCES EquivalenceDialect.cpp
  DEPENDS ${EQUIVALENCE_GENERATED_HEADERS}
)

add_mlir_dialect_library(MLIREquivalence
  EquivalenceDialect.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREquivalenceIncGen
  copy_equivalence_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRInferTypeOpInterface
  MLIRFuncDialect
  MLIRRegisterAllDialects
  MLIRRegisterAllPasses
)

# ============================================================================
# Ematch Dialect Library
# ============================================================================
set_source_object_depends(
  SOURCES EmatchDialect.cpp
  DEPENDS ${EMATCH_GENERATED_HEADERS}
)

add_mlir_dialect_library(MLIREmatch
  EmatchDialect.cpp
  Utils/MutableScopedHashTable.cpp
  Utils/ClassOpUnionFind.cpp
  Utils/HashConsPatternRewriter.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREmatchIncGen
  copy_ematch_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRRegisterAllDialects
)

# ============================================================================
# C API Library
# ============================================================================
add_mlir_public_c_api_library(EquivalenceCAPI
  EquivalenceCAPI.cpp
  PARTIAL_SOURCES_INTENDED

  LINK_LIBS PUBLIC
  MLIREquivalence
)

# ============================================================================
# tamagoyaki-opt Executable
# ============================================================================
get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(TAMAGOYAKI_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  MLIREquivalence
  MLIREmatch
)

set_source_object_depends(
  SOURCES tamagoyaki-opt.cpp
  DEPENDS ${EQUIVALENCE_GENERATED_HEADERS} ${EMATCH_GENERATED_HEADERS}
)

add_llvm_executable(tamagoyaki-opt tamagoyaki-opt.cpp)
llvm_update_compile_flags(tamagoyaki-opt)
target_link_libraries(tamagoyaki-opt PRIVATE ${TAMAGOYAKI_OPT_LIBS})
add_dependencies(tamagoyaki-opt
  MLIREquivalenceIncGen
  MLIREmatchIncGen
  copy_equivalence_generated_td_to_src_include
  copy_ematch_generated_td_to_src_include
)
mlir_check_all_link_libraries(tamagoyaki-opt)
