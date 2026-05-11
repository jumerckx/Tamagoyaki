# rover library

set(ROVER_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Rover)
set(ROVER_MLIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include)

# ============================================================================
# Rover Library
# ============================================================================
set(ROVER_SOURCES
  RoverPasses.cpp
)

add_mlir_library(RoverDialect
  ${ROVER_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${ROVER_INCLUDE_DIR}

  DEPENDS
  MLIRRoverIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRParser
  MLIRTransforms
  MLIRFuncDialect
  MLIRArithDialect
  MLIRAnalysis
  MLIREquivalence
  MLIREmatch
  CIRCTComb
  CIRCTHW
  CIRCTDatapath
)

target_include_directories(RoverDialect PUBLIC ${ROVER_INCLUDE_DIR})
target_include_directories(RoverDialect PUBLIC ${CMAKE_BINARY_DIR}/rover-mlir/include/Rover)
target_include_directories(RoverDialect PUBLIC ${ROVER_MLIR_INCLUDE_DIR})
target_include_directories(RoverDialect PUBLIC ${CMAKE_BINARY_DIR}/rover-mlir/include)
target_include_directories(RoverDialect PUBLIC ${CIRCT_INCLUDE_DIRS})

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS RoverDialect
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
