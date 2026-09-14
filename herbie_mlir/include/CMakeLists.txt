# TableGen generation for HerbieMLIR dialect

# ============================================================================
# HerbieMLIR Dialect
# ============================================================================
add_dialect_tablegen(
  NAME HerbieMLIR
  NAMESPACE herbie
  TD_FILE HerbieMLIRDialect.td
  COMPONENTS Ops Attrs Enums Dialect Passes OpInterfaces
)
