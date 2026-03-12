# herbie-mlir: Implementation of Herbie's core in MLIR
# This subproject extends Tamagoyaki with interval arithmetic via Rival

add_subdirectory(include)
add_subdirectory(src)
add_subdirectory(rival)

add_subdirectory(tools)

add_subdirectory(test)

# ============ Herbie (Racket) installation from source ============
option(HERBIE_MLIR_BUILD_HERBIE "Clone and install Herbie from source (requires Racket and Rust)" OFF)
if(HERBIE_MLIR_BUILD_HERBIE)
  set(HERBIE_RACKET_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/racket-pkgs")

  include(ExternalProject)
  ExternalProject_Add(herbie
    GIT_REPOSITORY https://github.com/herbie-fp/herbie
    GIT_TAG        main
    GIT_SHALLOW    TRUE
    UPDATE_DISCONNECTED TRUE
    SOURCE_DIR     ${CMAKE_CURRENT_BINARY_DIR}/herbie-src
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ${CMAKE_COMMAND} -E env
                        "PLTADDONDIR=${HERBIE_RACKET_PREFIX}"
                        make -C <SOURCE_DIR> install
    INSTALL_COMMAND   ""
    BUILD_IN_SOURCE   TRUE
    LOG_BUILD         TRUE
  )

  message(STATUS "Herbie will be installed to local Racket prefix: ${HERBIE_RACKET_PREFIX}")
  message(STATUS "To use Herbie, set PLTADDONDIR=${HERBIE_RACKET_PREFIX} or run:")
  message(STATUS "  PLTADDONDIR=${HERBIE_RACKET_PREFIX} racket -l herbie -- --version")
endif()
