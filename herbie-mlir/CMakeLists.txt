# herbie-mlir: Implementation of Herbie's core in MLIR
# This subproject extends Tamagoyaki with interval arithmetic via Rival

add_subdirectory(include)
add_subdirectory(src)
add_subdirectory(rival)

option(HERBIE_MLIR_BUILD_TOOLS "Build herbie-mlir tools (herbie-mlir-opt)" ON)
if(HERBIE_MLIR_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

add_subdirectory(test)
