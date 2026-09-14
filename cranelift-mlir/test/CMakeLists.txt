# cranelift-mlir Lit tests

if(NOT LLVM_EXTERNAL_LIT)
    message(FATAL_ERROR "LLVM_EXTERNAL_LIT not set. Required for running tests.")
endif()

# Where the tests run, and where they find their tools. Both are written so
# they hold whether cranelift-mlir is a subdirectory of Tamagoyaki or its own
# top-level project: LLVM_RUNTIME_OUTPUT_INTDIR is this build's bin/ either way.
set(CRANELIFT_MLIR_TEST_EXEC_ROOT ${CMAKE_CURRENT_BINARY_DIR}/lit)
set(CRANELIFT_MLIR_TOOLS_DIR ${LLVM_RUNTIME_OUTPUT_INTDIR})

set(CRANELIFT_MLIR_TEST_DEPENDS
    CraneliftDialect
    cranelift-mlir-opt)

# The tests also run tamagoyaki-opt. In tree it is a target here and lands in
# the same bin/; standalone it is a binary in the found Tamagoyaki, whose
# location TamagoyakiConfig.cmake published as TAMAGOYAKI_TOOLS_DIR.
if(TARGET tamagoyaki-opt)
  set(TAMAGOYAKI_TOOLS_DIR ${LLVM_RUNTIME_OUTPUT_INTDIR})
  list(APPEND CRANELIFT_MLIR_TEST_DEPENDS tamagoyaki-opt)
endif()

set(CRANELIFT_MLIR_TEST_LIT_CFG ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.cfg.py)
configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit/lit.site.cfg.py MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit/lit.cfg.py)

# FileCheck, count, and not come from the prebuilt LLVM. They are only
# exported as CMake imported targets when LLVM is built with
# LLVM_INSTALL_UTILS=ON; the slimmed flake build omits them. The binaries
# themselves still live in ${LLVM_TOOLS_BINARY_DIR} and are found by lit
# via config.llvm_tools_dir, so we only add them as DEPENDS when the
# targets actually exist.
foreach(_tool FileCheck count not)
  if(TARGET ${_tool})
    list(APPEND CRANELIFT_MLIR_TEST_DEPENDS ${_tool})
  endif()
endforeach()

add_lit_testsuite(check-cranelift-mlir
  "Running cranelift-mlir tests"
  ${CMAKE_CURRENT_BINARY_DIR}/lit
  DEPENDS ${CRANELIFT_MLIR_TEST_DEPENDS})
set_target_properties(check-cranelift-mlir PROPERTIES FOLDER "Tests")

add_lit_testsuites(CRANELIFT_MLIR ${CMAKE_CURRENT_SOURCE_DIR} DEPENDS
                   ${CRANELIFT_MLIR_TEST_DEPENDS})
