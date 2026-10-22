# Out-of-tree copy of the match dialect and the PDL -> match -> pdl_interp
# lowering. See README.md for where it comes from and how it differs from the
# upstream sources.

set(MATCH_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/include)
set(MATCH_BINARY_INCLUDE_DIR ${CMAKE_CURRENT_BINARY_DIR}/include)

# The sources spell their headers like upstream does ("mlir/Dialect/Match/...").
include_directories(${MATCH_INCLUDE_DIR} ${MATCH_BINARY_INCLUDE_DIR})

add_subdirectory(include/mlir/Conversion)
add_subdirectory(include/mlir/Dialect/Match)
add_subdirectory(lib/Dialect/Match)
add_subdirectory(lib/Conversion/PDLToMatch)
add_subdirectory(lib/Conversion/MatchToPDLInterp)

# Consumers (MLIREmatch, tamagoyaki-opt) include the match headers too.
foreach(_target MLIRMatchDialect MLIRMatchTransforms MLIRPDLToMatch
                MLIRMatchToPDLInterp)
  foreach(_t ${_target} obj.${_target})
    if(TARGET ${_t})
      target_include_directories(${_t} PUBLIC
        $<BUILD_INTERFACE:${MATCH_INCLUDE_DIR}>
        $<BUILD_INTERFACE:${MATCH_BINARY_INCLUDE_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki/match>)
    endif()
  endforeach()
endforeach()

install(TARGETS
  MLIRMatchDialect
  MLIRMatchTransforms
  MLIRPDLToMatch
  MLIRMatchToPDLInterp
  EXPORT TamagoyakiTargets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
install(DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki/match
        FILES_MATCHING PATTERN "*.h" PATTERN "*.td")
install(DIRECTORY ${MATCH_BINARY_INCLUDE_DIR}/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki/match
        FILES_MATCHING PATTERN "*.inc"
        PATTERN "CMakeFiles" EXCLUDE)

add_subdirectory(test)
