# rover-mlir: Implementation of rover's core in MLIR

add_subdirectory(include)
add_subdirectory(src)

option(ROVER_MLIR_BUILD_TOOLS "Build rover-mlir tools (rover-mlir-opt)" ON)
if(ROVER_MLIR_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

# add_subdirectory(test)
