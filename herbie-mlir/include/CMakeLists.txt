# TableGen generation for HerbieMLIR passes and interfaces

include(${PROJECT_SOURCE_DIR}/cmake/TableGenHelpers.cmake)

# ============================================================================
# HerbieMLIR Passes and Interfaces
# ============================================================================
add_dialect_tablegen(
  NAME HerbieMLIR
  NAMESPACE herbiemlir
  TD_FILE HerbieMLIRPasses.td
  DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR}
  COMPONENTS Passes OpInterfaces
)

# Export to parent scope
set(HERBIE_MLIR_GENERATED_HEADERS ${HerbieMLIR_GENERATED_HEADERS} PARENT_SCOPE)
