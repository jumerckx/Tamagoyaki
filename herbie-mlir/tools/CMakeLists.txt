# herbie-mlir tools

add_executable(herbie-mlir-opt
  herbie-mlir-opt.cpp
)

target_include_directories(herbie-mlir-opt
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)

target_link_libraries(herbie-mlir-opt
  PUBLIC
    herbieMLIR
    MLIROptLib
    MLIRPass
    MLIRTransforms
)
