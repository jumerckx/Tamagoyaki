# rover-mlir: Implementation of rover's core in MLIR
#
# Nothing here addresses the enclosing project: rover-mlir is built both as a
# subdirectory of the Tamagoyaki tree and as its own top-level project against
# a find_package(Tamagoyaki), and CMAKE_BINARY_DIR / PROJECT_SOURCE_DIR mean
# different things in the two. These two do not.
set(ROVER_MLIR_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(ROVER_MLIR_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(include)
add_subdirectory(src)

option(ROVER_MLIR_BUILD_TOOLS "Build rover-mlir tools (rover-mlir-opt)" ON)
if(ROVER_MLIR_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

add_subdirectory(test)
