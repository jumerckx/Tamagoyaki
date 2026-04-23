# cranelift-mlir Lit tests

if(NOT LLVM_EXTERNAL_LIT)
    message(FATAL_ERROR "LLVM_EXTERNAL_LIT not set. Required for running tests.")
endif()

set(TAMAGOYAKI_BINARY_DIR ${PROJECT_BINARY_DIR})
set(CRANELIFT_MLIR_TEST_LIT_CFG ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.cfg.py)
configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit/lit.site.cfg.py MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.cfg.py)

set(CRANELIFT_MLIR_TEST_DEPENDS
    FileCheck
    count
    not
    CraneliftDialect
    cranelift-mlir-opt
    tamagoyaki-opt)

add_lit_testsuite(check-cranelift-mlir
  "Running cranelift-mlir tests"
  ${CMAKE_CURRENT_BINARY_DIR}/lit
  DEPENDS ${CRANELIFT_MLIR_TEST_DEPENDS})
set_target_properties(check-cranelift-mlir PROPERTIES FOLDER "Tests")

add_lit_testsuites(CRANELIFT_MLIR ${CMAKE_CURRENT_SOURCE_DIR} DEPENDS
                   ${CRANELIFT_MLIR_TEST_DEPENDS})
