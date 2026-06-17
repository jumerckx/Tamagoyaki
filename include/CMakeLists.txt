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
  COMPONENTS Ops Attrs Dialect Passes
)

# ============================================================================
# Ematch Dialect
# ============================================================================
add_dialect_tablegen(
  NAME Ematch
  NAMESPACE ematch
  TD_FILE EmatchDialect.td
  COMPONENTS Ops Dialect Passes
)
