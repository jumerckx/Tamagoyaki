# TableGen generation for Rover passes

# ============================================================================
# Rover Passes
# ============================================================================
add_dialect_tablegen(
  NAME Rover
  NAMESPACE rover
  TD_FILE RoverDialect.td
  COMPONENTS Passes
)
