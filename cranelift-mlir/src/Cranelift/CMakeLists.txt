# cranelift library

set(CRANELIFT_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include/Cranelift)
set(CRANELIFT_MLIR_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../include)

# ============================================================================
# Cranelift Library
# ============================================================================
set(CRANELIFT_SOURCES
  CraneliftPasses.cpp
)

add_mlir_library(CraneliftDialect
  ${CRANELIFT_SOURCES}
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${CRANELIFT_INCLUDE_DIR}

  DEPENDS
  MLIRCraneliftIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRParser
  MLIRTransforms
  MLIREquivalence
  MLIREmatch
)

target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_INCLUDE_DIR})
target_include_directories(CraneliftDialect PUBLIC ${CMAKE_BINARY_DIR}/cranelift-mlir/include/Cranelift)
target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_MLIR_INCLUDE_DIR})
target_include_directories(CraneliftDialect PUBLIC ${CMAKE_BINARY_DIR}/cranelift-mlir/include)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS CraneliftDialect
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
