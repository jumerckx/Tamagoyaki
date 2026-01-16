# herbie-mlir Lit tests

if(NOT LLVM_EXTERNAL_LIT)
  message(FATAL_ERROR "LLVM_EXTERNAL_LIT not set. Required for running tests.")
endif()

add_lit_testsuite(check-herbie-mlir
  "Running herbie-mlir tests"
  "${CMAKE_CURRENT_SOURCE_DIR}/lit"
  DEPENDS
    herbieMLIR
    tamagoyaki-opt
)
