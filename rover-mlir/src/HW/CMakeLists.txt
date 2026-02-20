# comb library

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

set(HW_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/HW/)

# ============================================================================
# HW Library
# ============================================================================
set(HW_SOURCES
  HWDialect.cpp
)

message(STATUS "HW_GENERATED_HEADERS: ${HW_GENERATED_HEADERS}")

set_source_object_depends(
  SOURCES ${HW_SOURCES}
  DEPENDS ${HW_GENERATED_HEADERS}
)

add_mlir_library(HWDialect
  ${HW_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${HW_INCLUDE_DIR}

  DEPENDS
  MLIRHWIncGen
  copy_comb_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
)

target_include_directories(HWDialect PUBLIC ${HW_INCLUDE_DIR})
