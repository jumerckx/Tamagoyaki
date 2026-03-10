# TableGen generation for Rover passes

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# Rover Passes
# ============================================================================
add_dialect_tablegen(
  NAME Rover
  NAMESPACE rover
  TD_FILE RoverDialect.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Passes
)

# Export to parent scope
set(ROVER_GENERATED_HEADERS ${Rover_GENERATED_HEADERS} PARENT_SCOPE)
