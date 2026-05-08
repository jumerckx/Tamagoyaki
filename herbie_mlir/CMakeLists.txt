# herbie-mlir: Implementation of Herbie's core in MLIR
# This subproject extends Tamagoyaki with interval arithmetic via Rival

add_subdirectory(include)
# rival must be configured before src so that the gmp_external / mpfr_external
# ExternalProject targets exist when src/CMakeLists.txt wires up its
# add_dependencies() calls. Otherwise obj.herbieMLIR can compile before mpfr.h
# has been generated.
add_subdirectory(rival)
add_subdirectory(src)

add_subdirectory(tools)

add_subdirectory(test)

# ============ Herbie (Racket) installation from source ============
option(HERBIE_MLIR_BUILD_HERBIE "Clone and install Herbie from source (requires Racket and Rust)" OFF)
set(HERBIE_GIT_TAG "main" CACHE STRING "Git tag/branch/commit of Herbie to use")
if(HERBIE_MLIR_BUILD_HERBIE)
  find_program(RACKET racket REQUIRED)
  find_program(RACO raco REQUIRED)
  message(STATUS "Using Racket: ${RACKET}")
  message(STATUS "Using Raco: ${RACO}")

  get_filename_component(_RACKET_BIN_DIR "${RACKET}" DIRECTORY)

  set(HERBIE_RACKET_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/racket-pkgs")

  # Query the Racket's system-library-subpath so we can fix up pre-built
  # native libraries that may have been packaged under a different name
  # (e.g. "aarch64-macosx" vs Nix Racket's "aarch64-darwin").
  execute_process(
    COMMAND ${RACKET} -e "(displayln (system-library-subpath #f))"
    OUTPUT_VARIABLE _RACKET_LIB_SUBPATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  message(STATUS "Racket system-library-subpath: ${_RACKET_LIB_SUBPATH}")

  include(ExternalProject)
  ExternalProject_Add(herbie
    GIT_REPOSITORY https://github.com/herbie-fp/herbie
    GIT_TAG        ${HERBIE_GIT_TAG}
    GIT_SHALLOW    FALSE
    UPDATE_COMMAND ""
    SOURCE_DIR     ${CMAKE_CURRENT_BINARY_DIR}/herbie-src
    CONFIGURE_COMMAND ""
    BUILD_COMMAND     ${CMAKE_COMMAND} -E env
                        "PLTADDONDIR=${HERBIE_RACKET_PREFIX}"
                        "DYLD_FALLBACK_LIBRARY_PATH=$ENV{DYLD_FALLBACK_LIBRARY_PATH}"
                        "PATH=${_RACKET_BIN_DIR}:$ENV{PATH}"
                        make -C <SOURCE_DIR> install
    INSTALL_COMMAND   ""
    BUILD_IN_SOURCE   TRUE
    LOG_BUILD         TRUE
  )

  # Pre-install rackunit-lib (not included in racket-minimal) before
  # the Herbie Makefile runs `raco pkg install ./egg-herbie`, which
  # would otherwise prompt interactively and fail on EOF.
  ExternalProject_Add_Step(herbie install_racket_deps
    COMMAND ${CMAKE_COMMAND} -E env
              "PLTADDONDIR=${HERBIE_RACKET_PREFIX}"
              "PATH=${_RACKET_BIN_DIR}:$ENV{PATH}"
              raco pkg install --auto --skip-installed rackunit-lib
    DEPENDEES patch
    DEPENDERS build
    LOG TRUE
  )

  # Rival3 ships pre-built native libraries under platform-specific directory
  # names (e.g. "aarch64-macosx").  When Racket's (system-library-subpath #f)
  # returns a different string (e.g. Nix Racket uses "aarch64-darwin"), the
  # library lookup fails.  Create a symlink so both names resolve.
  set(_RIVAL3_NATIVE_DIR "${HERBIE_RACKET_PREFIX}/*/pkgs/rival3/private/native")
  ExternalProject_Add_Step(herbie fix_rival3_native_symlink
    COMMAND ${CMAKE_COMMAND}
              -DNATIVE_GLOB=${_RIVAL3_NATIVE_DIR}
              -DRACKET_SUBPATH=${_RACKET_LIB_SUBPATH}
              -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/fix_rival3_native.cmake
    DEPENDEES build
    LOG TRUE
  )

  message(STATUS "Herbie will be installed to local Racket prefix: ${HERBIE_RACKET_PREFIX}")
  message(STATUS "To use Herbie, set PLTADDONDIR=${HERBIE_RACKET_PREFIX} or run:")
  message(STATUS "  PLTADDONDIR=${HERBIE_RACKET_PREFIX} ${RACKET} -l herbie -- --version")
endif()
