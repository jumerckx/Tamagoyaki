# this configures the adjacent lit.site.cfg.py.in
set(TAMAGOYAKI_BINARY_DIR ${PROJECT_BINARY_DIR})
set(TAMAGOYAKI_SOURCE_DIR ${PROJECT_SOURCE_DIR})
set(TAMAGOYAKI_TEST_LIT_CFG ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)
configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)

set(TAMAGOYAKI_TEST_DEPENDS
    tamagoyaki-opt)

# FileCheck, count, and not come from the prebuilt LLVM. They are only
# exported as CMake imported targets when LLVM is built with
# LLVM_INSTALL_UTILS=ON; the slimmed flake build omits them. The binaries
# themselves still live in ${LLVM_TOOLS_BINARY_DIR} and are found by lit
# via config.llvm_tools_dir, so we only add them as DEPENDS when the
# targets actually exist.
foreach(_tool FileCheck count not)
  if(TARGET ${_tool})
    list(APPEND TAMAGOYAKI_TEST_DEPENDS ${_tool})
  endif()
endforeach()

add_lit_testsuite(
  check-tamagoyaki "Running the tamagoyaki regression tests"
  ${CMAKE_CURRENT_BINARY_DIR} DEPENDS ${TAMAGOYAKI_TEST_DEPENDS})
set_target_properties(check-tamagoyaki PROPERTIES FOLDER "Tests")

add_lit_testsuites(TAMAGOYAKI ${CMAKE_CURRENT_SOURCE_DIR} DEPENDS
                   ${TAMAGOYAKI_TEST_DEPENDS})
