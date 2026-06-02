# Test-only passes. This library is built and linked into tamagoyaki-opt only
# when TAMAGOYAKI_INCLUDE_TESTS is enabled (see the top-level CMakeLists.txt).
# It mirrors MLIR's test/lib/ convention: passes here are not part of the
# Tamagoyaki core and exist purely to drive lit/FileCheck tests. Add new
# test-pass source files to this list and register them from
# src/tamagoyaki-opt.cpp behind #ifdef TAMAGOYAKI_INCLUDE_TESTS.
add_mlir_library(TamagoyakiTestPasses
  TestEquivalenceUtils.cpp

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREquivalenceIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIREquivalence
)
