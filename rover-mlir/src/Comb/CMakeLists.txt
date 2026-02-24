# comb library

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

set(COMB_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Comb)
set(HW_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/)

# ============================================================================
# Comb Library
# ============================================================================
set(COMB_SOURCES
  CombDialect.cpp
  CombPasses.cpp
)

set_source_object_depends(
  SOURCES ${COMB_SOURCES}
  DEPENDS ${COMB_GENERATED_HEADERS}
)

add_mlir_library(Comb
  ${COMB_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${COMB_INCLUDE_DIR}
  # ${HW_INCLUDE_DIR}

  DEPENDS
  MLIRCombIncGen
  copy_comb_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
)

target_include_directories(Comb PUBLIC ${COMB_INCLUDE_DIR})
target_include_directories(Comb PUBLIC ${HW_INCLUDE_DIR})
