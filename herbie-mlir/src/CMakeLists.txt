# herbie-mlir library

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

set(HERBIE_MLIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../include)

# ============================================================================
# herbieMLIR Library
# ============================================================================
set(HERBIE_MLIR_SOURCES
  HerbieMLIRDialect.cpp
  HerbieMLIRPasses.cpp
  HerbieMLIROpInterfaces.cpp
  RivalExternalModels.cpp
  IntervalSearch.cpp
  IntervalSearchPass.cpp
  LocalError.cpp
)

set_source_object_depends(
  SOURCES ${HERBIE_MLIR_SOURCES}
  DEPENDS ${HERBIE_MLIR_GENERATED_HEADERS}
)

add_mlir_library(herbieMLIR
  ${HERBIE_MLIR_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${HERBIE_MLIR_INCLUDE_DIR}

  DEPENDS
  MLIRHerbieMLIRIncGen
  copy_herbiemlir_generated_td_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
  Rival
  TamagoyakiTiming
)

target_include_directories(herbieMLIR PUBLIC ${HERBIE_MLIR_INCLUDE_DIR})
