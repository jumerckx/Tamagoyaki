# Dialect libraries and tamagoyaki-opt executable

# ============================================================================
# Equivalence Dialect Library
# ============================================================================
add_mlir_dialect_library(MLIREquivalence
  EquivalenceDialect.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREquivalenceIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRInferTypeOpInterface
  MLIRFuncDialect
  MLIRRegisterAllDialects
  MLIRRegisterAllPasses
  TamagoyakiTiming
)

# ============================================================================
# Tamagoyaki Timing Library
# ============================================================================
add_mlir_library(TamagoyakiTiming
  TamagoyakiTiming.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  LINK_LIBS PUBLIC
  MLIRIR
)

# ============================================================================
# Ematch Dialect Library
# ============================================================================
add_mlir_dialect_library(MLIREmatch
  EmatchDialect.cpp
  Utils/MutableScopedHashTable.cpp
  Utils/ClassOpUnionFind.cpp
  Utils/HashConsPatternRewriter.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREquivalenceIncGen
  MLIREmatchIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRRegisterAllDialects
  MLIREquivalence
  TamagoyakiTiming
)

# ============================================================================
# C API Library
# ============================================================================
add_mlir_public_c_api_library(EquivalenceCAPI
  EquivalenceCAPI.cpp
  PARTIAL_SOURCES_INTENDED

  LINK_LIBS PUBLIC
  MLIREquivalence
)

# ============================================================================
# tamagoyaki-opt Executable
# ============================================================================
get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(TAMAGOYAKI_OPT_LIBS
  ${dialect_libs}
  ${conversion_libs}
  MLIROptLib
  MLIREquivalence
  MLIREmatch
  TamagoyakiTiming
)

add_llvm_executable(tamagoyaki-opt tamagoyaki-opt.cpp)
llvm_update_compile_flags(tamagoyaki-opt)
target_link_libraries(tamagoyaki-opt PRIVATE ${TAMAGOYAKI_OPT_LIBS})
add_dependencies(tamagoyaki-opt
  MLIREquivalenceIncGen
  MLIREmatchIncGen
)
mlir_check_all_link_libraries(tamagoyaki-opt)

# ============================================================================
# Install Rules
# ============================================================================
install(TARGETS
  MLIREquivalence
  MLIREmatch
  TamagoyakiTiming
  EquivalenceCAPI
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(TARGETS tamagoyaki-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
