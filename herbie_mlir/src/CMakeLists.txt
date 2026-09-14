# herbie-mlir library

set(HERBIE_MLIR_INCLUDE_DIR ${HERBIE_MLIR_SOURCE_DIR}/include)

# ============================================================================
# herbieMLIR Library
# ============================================================================
set(HERBIE_MLIR_SOURCES
  HerbieMLIRDialect.cpp
  HerbieMLIRPasses.cpp
  HerbieMLIROpInterfaces.cpp
  RivalExternalModels.cpp
  BatchEvaluateExternalModels.cpp
  IntervalSearch.cpp
  IntervalSearchPass.cpp
  LocalError.cpp
)

add_mlir_library(herbieMLIR
  ${HERBIE_MLIR_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${HERBIE_MLIR_INCLUDE_DIR}

  DEPENDS
  MLIRHerbieMLIRIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRParser
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRMathDialect
  MLIRAnalysis
  MLIREquivalence
  MLIREmatch
  Rival
  TamagoyakiTiming
)

# Tamagoyaki's include directories are not listed: they arrive as usage
# requirements of MLIREquivalence/MLIREmatch, in-tree and out of tree alike.
target_include_directories(herbieMLIR PUBLIC ${HERBIE_MLIR_INCLUDE_DIR})
target_include_directories(herbieMLIR PUBLIC ${HERBIE_MLIR_BINARY_DIR}/include)

# Ensure GMP/MPFR headers are available before compiling.
# ExternalProject dependencies don't propagate through INTERFACE/IMPORTED
# targets to object libraries created by add_mlir_library, so we need an
# explicit dependency when building from source.
if(TARGET gmp_external)
  add_dependencies(obj.herbieMLIR gmp_external)
endif()
if(TARGET mpfr_external)
  add_dependencies(obj.herbieMLIR mpfr_external)
endif()

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS herbieMLIR
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
