# datapath library

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

set(COMB_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Comb)
set(DATAPATH_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Datapath/)

# ============================================================================
# Datapath Library
# ============================================================================
set(DATAPATH_SOURCES
  DatapathDialect.cpp
)

message(STATUS "DATAPATH_GENERATED_HEADERS: ${DATAPATH_GENERATED_HEADERS}")

set_source_object_depends(
  SOURCES ${DATAPATH_SOURCES}
  DEPENDS ${DATAPATH_GENERATED_HEADERS}
)

add_mlir_library(DatapathDialect
  ${DATAPATH_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${DATAPATH_INCLUDE_DIR}
  # ${HW_INCLUDE_DIR}

  DEPENDS
  MLIRDatapathIncGen
  copy_datapath_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
)

target_include_directories(DatapathDialect PUBLIC ${DATAPATH_INCLUDE_DIR})
target_include_directories(DatapathDialect PUBLIC ${COMB_INCLUDE_DIR})

