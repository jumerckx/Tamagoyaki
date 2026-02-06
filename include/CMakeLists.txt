# TableGen generation for Equivalence and Ematch dialects
#
# To add a new dialect, copy one of the add_dialect_tablegen blocks below.
# Available COMPONENTS: Ops, Types, Attrs, Dialect, Passes, OpInterfaces

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Equivalence Dialect
# ============================================================================
add_dialect_tablegen(
  NAME Equivalence
  NAMESPACE equivalence
  TD_FILE EquivalenceDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Types Attrs Dialect Passes
)

# ============================================================================
# Ematch Dialect
# ============================================================================
add_dialect_tablegen(
  NAME Ematch
  NAMESPACE ematch
  TD_FILE EmatchDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Dialect Passes
)

# Export to parent scope for use in src/CMakeLists.txt
set(EQUIVALENCE_GENERATED_HEADERS ${Equivalence_GENERATED_HEADERS} PARENT_SCOPE)
set(EMATCH_GENERATED_HEADERS ${Ematch_GENERATED_HEADERS} PARENT_SCOPE)
