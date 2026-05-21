# rover-mlir Lit tests

if(NOT LLVM_EXTERNAL_LIT)
    message(FATAL_ERROR "LLVM_EXTERNAL_LIT not set. Required for running tests.")
endif()

set(TAMAGOYAKI_BINARY_DIR ${PROJECT_BINARY_DIR})
set(ROVER_MLIR_TEST_LIT_CFG ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)
configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)

set(ROVER_MLIR_TEST_DEPENDS
    RoverDialect
    rover-mlir-opt)

# FileCheck, count, and not come from the prebuilt LLVM. They are only
# exported as CMake imported targets when LLVM is built with
# LLVM_INSTALL_UTILS=ON; the slimmed flake build omits them. The binaries
# themselves still live in ${LLVM_TOOLS_BINARY_DIR} and are found by lit
# via config.llvm_tools_dir, so we only add them as DEPENDS when the
# targets actually exist.
foreach(_tool FileCheck count not)
  if(TARGET ${_tool})
    list(APPEND ROVER_MLIR_TEST_DEPENDS ${_tool})
  endif()
endforeach()

add_lit_testsuite(check-rover-mlir
  "Running rover-mlir tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${ROVER_MLIR_TEST_DEPENDS})
set_target_properties(check-rover-mlir PROPERTIES FOLDER "Tests")

add_lit_testsuites(ROVER_MLIR ${CMAKE_CURRENT_SOURCE_DIR} DEPENDS
                   ${ROVER_MLIR_TEST_DEPENDS})
