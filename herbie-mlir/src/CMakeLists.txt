# herbie-mlir source code

set(HERBIE_MLIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../include)

add_mlir_library(herbieMLIR
  HerbieMLIRPasses.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${HERBIE_MLIR_INCLUDE_DIR}

  DEPENDS
  HerbieMLIRPassesIncGen
  copy_herbie_mlir_generated_to_src_include

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
  Rival
)

target_include_directories(herbieMLIR PUBLIC ${HERBIE_MLIR_INCLUDE_DIR})
