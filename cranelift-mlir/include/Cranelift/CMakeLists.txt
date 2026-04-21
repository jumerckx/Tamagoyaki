# TableGen generation for Cranelift passes

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Cranelift Passes
# ============================================================================
add_dialect_tablegen(
  NAME Cranelift
  NAMESPACE cranelift
  TD_FILE CraneliftDialect.td
  COMPONENTS Passes
)
