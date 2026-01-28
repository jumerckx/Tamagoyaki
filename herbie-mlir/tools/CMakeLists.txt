# herbie-mlir tools

get_property(dialect_libs GLOBAL PROPERTY MLIR_DIALECT_LIBS)
get_property(conversion_libs GLOBAL PROPERTY MLIR_CONVERSION_LIBS)

set(LIBS
    ${dialect_libs}
    ${conversion_libs}
    MLIROptLib
    herbieMLIR
    MLIREquivalence
    MLIRTamatch
    Rival
)

add_llvm_executable(herbie-mlir-opt herbie-mlir-opt.cpp)
llvm_update_compile_flags(herbie-mlir-opt)

target_include_directories(herbie-mlir-opt
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
    ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(herbie-mlir-opt PRIVATE ${LIBS})
add_dependencies(herbie-mlir-opt HerbieMLIRPassesIncGen MLIREquivalenceIncGen MLIRTamatchIncGen buildRival)

mlir_check_all_link_libraries(herbie-mlir-opt)
