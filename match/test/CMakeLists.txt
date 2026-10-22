# Lit suite for the copied match dialect tests. The tests are the upstream ones
# with tamagoyaki-opt replaced by tamagoyaki-opt.
set(MATCH_TEST_LIT_CFG ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)
configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py)

set(MATCH_TEST_DEPENDS tamagoyaki-opt)
foreach(_tool FileCheck count not)
  if(TARGET ${_tool})
    list(APPEND MATCH_TEST_DEPENDS ${_tool})
  endif()
endforeach()

add_lit_testsuite(
  check-match "Running the match dialect regression tests"
  ${CMAKE_CURRENT_BINARY_DIR} DEPENDS ${MATCH_TEST_DEPENDS})
set_target_properties(check-match PROPERTIES FOLDER "Tests")
