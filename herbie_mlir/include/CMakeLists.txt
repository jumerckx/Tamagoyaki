# TableGen generation for HerbieMLIR dialect

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# HerbieMLIR Dialect
# ============================================================================
add_dialect_tablegen(
  NAME HerbieMLIR
  NAMESPACE herbie
  TD_FILE HerbieMLIRDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Ops Attrs Enums Dialect Passes OpInterfaces
)

# Export to parent scope
set(HERBIE_MLIR_GENERATED_HEADERS ${HerbieMLIR_GENERATED_HEADERS} PARENT_SCOPE)
