# herbie-mlir source code

add_library(herbieMLIR
  HerbieMLIRPasses.cpp
)

target_include_directories(herbieMLIR
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
    ${MLIR_INCLUDE_DIRS}
)

target_link_libraries(herbieMLIR
  PUBLIC
    MLIRPass
    MLIRTransforms
    MLIRFuncDialect
)
