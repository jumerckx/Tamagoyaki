# herbie-mlir tools

set(LIBS
    MLIROptLib
    MLIRArithDialect
    MLIRFuncDialect
    herbieMLIR
)

add_llvm_executable(herbie-mlir-opt herbie-mlir-opt.cpp)
llvm_update_compile_flags(herbie-mlir-opt)

target_include_directories(herbie-mlir-opt
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)

target_link_libraries(herbie-mlir-opt PRIVATE ${LIBS})
add_dependencies(herbie-mlir-opt HerbieMLIRPassesIncGen)

mlir_check_all_link_libraries(herbie-mlir-opt)
