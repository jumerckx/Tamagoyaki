# cranelift library

set(CRANELIFT_INCLUDE_DIR ${CRANELIFT_MLIR_SOURCE_DIR}/include/Cranelift)
set(CRANELIFT_MLIR_INCLUDE_DIR ${CRANELIFT_MLIR_SOURCE_DIR}/include)

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

# Tamagoyaki's own include directories are not listed here: they arrive as
# usage requirements of MLIREquivalence/MLIREmatch, the same way in an in-tree
# build as through find_package(Tamagoyaki).
target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_INCLUDE_DIR})
target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_MLIR_BINARY_DIR}/include/Cranelift)
target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_MLIR_INCLUDE_DIR})
target_include_directories(CraneliftDialect PUBLIC ${CRANELIFT_MLIR_BINARY_DIR}/include)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS CraneliftDialect
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
