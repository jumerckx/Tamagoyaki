# rover library

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

set(ROVER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Rover)
set(ROVER_MLIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include)

# ============================================================================
# Rover Library
# ============================================================================
set(ROVER_SOURCES
  RoverPasses.cpp
)

set_source_object_depends(
  SOURCES ${ROVER_SOURCES}
  DEPENDS ${ROVER_GENERATED_HEADERS}
)

add_mlir_library(RoverDialect
  ${ROVER_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${ROVER_INCLUDE_DIR}

  DEPENDS
  MLIRRoverIncGen
  copy_rover_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
  Comb
  DatapathDialect
  HWDialect
)

target_include_directories(RoverDialect PUBLIC ${ROVER_INCLUDE_DIR})
target_include_directories(RoverDialect PUBLIC ${ROVER_MLIR_INCLUDE_DIR})
