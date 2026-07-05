# Dialect libraries and tamagoyaki-opt executable

# ============================================================================
# Equivalence Dialect Library
# ============================================================================
add_mlir_dialect_library(MLIREquivalence
  EquivalenceDialect.cpp
  EquivalenceTransforms.cpp
  EquivalencePasses.cpp
  EquivalenceSelectIlp.cpp
  PARTIAL_SOURCES_INTENDED

  ADDITIONAL_HEADER_DIRS
  ${PROJECT_SOURCE_DIR}/include

  DEPENDS
  MLIREquivalenceIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRInferTypeOpInterface
  MLIRLoopLikeInterface
  MLIRFuncDialect
  MLIRRegisterAllDialects
  MLIRRegisterAllPasses
  TamagoyakiTiming
)

# The equivalence-select-ilp pass optionally links the HiGHS solver. When
# disabled the pass source still compiles (so the pass stays registered) but
# its body reports that HiGHS support is unavailable.
#
# add_mlir_dialect_library compiles the sources through an object library
# (obj.MLIREquivalence when one is created), so the HiGHS include dirs and the
# TAMAGOYAKI_HIGHS_ENABLED define have to be attached to that object target to
# reach EquivalenceSelectIlp.cpp; the actual link is on the wrapper target.
if(TAMAGOYAKI_ENABLE_HIGHS)
  set(_equivalence_obj_target MLIREquivalence)
  if(TARGET obj.MLIREquivalence)
    set(_equivalence_obj_target obj.MLIREquivalence)
  endif()
  target_compile_definitions(${_equivalence_obj_target}
                             PRIVATE TAMAGOYAKI_HIGHS_ENABLED)
  # Propagates HiGHS's INTERFACE_INCLUDE_DIRECTORIES to the source compilation.
  target_link_libraries(${_equivalence_obj_target} PRIVATE highs::highs)
  # Propagates the actual libhighs link requirement to consumers.
  target_link_libraries(MLIREquivalence PRIVATE highs::highs)
endif()

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
  EmatchTransforms.cpp
  EmatchPasses.cpp
  Utils/MutableScopedHashTable.cpp
  Utils/GraphScope.cpp
  Utils/ClassOpUtils.cpp
  Utils/ScopeRepIndex.cpp
  Utils/CongruenceEngine.cpp
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
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

install(TARGETS tamagoyaki-opt
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
