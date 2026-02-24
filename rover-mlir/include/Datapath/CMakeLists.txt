# TableGen generation for Datapath dialect

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Datapath Dialect
# ============================================================================
add_dialect_tablegen(
  NAME Datapath
  NAMESPACE datapath
  TD_FILE DatapathDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Attrs Dialect Passes
)

# Export to parent scope
set(DATAPATH_GENERATED_HEADERS ${Datapath_GENERATED_HEADERS} PARENT_SCOPE)
