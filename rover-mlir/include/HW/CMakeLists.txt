# TableGen generation for HW dialect

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# HW Dialect
# ============================================================================
add_dialect_tablegen(
  NAME HW
  NAMESPACE hw
  TD_FILE HWDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Attrs Enums Dialect Passes
)

# Export to parent scope
set(HW_GENERATED_HEADERS ${HW_GENERATED_HEADERS} PARENT_SCOPE)
