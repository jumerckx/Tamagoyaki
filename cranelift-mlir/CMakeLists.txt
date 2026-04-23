# cranelift-mlir: Cranelift backend in MLIR

add_subdirectory(include)
add_subdirectory(src)

option(CRANELIFT_MLIR_BUILD_TOOLS "Build cranelift-mlir tools (cranelift-mlir-opt)" ON)
if(CRANELIFT_MLIR_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

add_subdirectory(test)
