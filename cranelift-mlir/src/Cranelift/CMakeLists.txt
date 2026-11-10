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
  MLIRAnalysis
  MLIRIR
  MLIRPass
  MLIRParser
  MLIRTransforms
  MLIREquivalence
  MLIREmatch
)

# Consumers include "Cranelift/Cranelift.h", which includes the generated
# "CraneliftPasses.h.inc" unprefixed.
target_include_directories(CraneliftDialect PUBLIC
  $<BUILD_INTERFACE:${CRANELIFT_INCLUDE_DIR}>
  $<BUILD_INTERFACE:${CRANELIFT_MLIR_BINARY_DIR}/include/Cranelift>
  $<BUILD_INTERFACE:${CRANELIFT_MLIR_INCLUDE_DIR}>
  $<BUILD_INTERFACE:${CRANELIFT_MLIR_BINARY_DIR}/include>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki/Cranelift>)

# ============================================================================
# Install Rules
# ============================================================================
# In Tamagoyaki's tree, the library is the package's Cranelift component, so
# that projects built against Tamagoyaki can use convertToSoN and elaborate
# (find_package(Tamagoyaki COMPONENTS Cranelift)). It is not one of the
# package's default targets, which a standalone build of this directory
# imports and would otherwise define twice.
if(NOT CMAKE_SOURCE_DIR STREQUAL CRANELIFT_MLIR_SOURCE_DIR)
  set(_cranelift_export EXPORT TamagoyakiCraneliftTargets)
endif()
install(TARGETS CraneliftDialect
  ${_cranelift_export}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(FILES
  ${CRANELIFT_INCLUDE_DIR}/Cranelift.h
  ${CRANELIFT_MLIR_BINARY_DIR}/include/Cranelift/CraneliftPasses.h.inc
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki/Cranelift)
