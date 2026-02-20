# TableGen generation for Comb dialect

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Comb Dialect
# ============================================================================
add_dialect_tablegen(
  NAME Comb
  NAMESPACE comb
  TD_FILE CombDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Attrs Dialect Passes
)

message(STATUS "Comb_GENERATED_HEADERS: ${Comb_GENERATED_HEADERS}")
# Export to parent scope
set(COMB_GENERATED_HEADERS ${Comb_GENERATED_HEADERS} PARENT_SCOPE)
