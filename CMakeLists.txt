cmake_minimum_required(VERSION 3.20.0)
project(tamagoyaki VERSION 0.1.0 LANGUAGES CXX C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(CMAKE_EXPORT_COMPILE_COMMANDS)
  set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES 
      ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
endif()


set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")

include(GNUInstallDirs)

option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
if(ENABLE_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address)
endif()

# The ILP-based extraction pass (equivalence-select-ilp) depends on the HiGHS
# solver. Building it is optional: with TAMAGOYAKI_ENABLE_HIGHS=OFF the pass is
# still registered but fails at run time, so the whole project builds without
# the HiGHS dependency.
option(TAMAGOYAKI_ENABLE_HIGHS
       "Build the HiGHS-backed ILP selection pass" ON)
if(TAMAGOYAKI_ENABLE_HIGHS)
  find_package(highs REQUIRED CONFIG)
  message(STATUS "Using highs-config.cmake in: ${highs_DIR}")
endif()

find_package(MLIR REQUIRED CONFIG)

message(STATUS "Using MLIRConfig.cmake in: ${MLIR_DIR}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)
set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/lib)
set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})

list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")

include(TableGen)
include(AddLLVM)
include(AddMLIR)
include(HandleLLVMOptions)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# add_dialect_tablegen(), used by every dialect in this tree. Included once
# here; an out-of-tree dialect gets the same file from TamagoyakiConfig.cmake,
# so neither kind of consumer has to know where it lives.
include(TableGenHelpers)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
link_directories(${LLVM_BUILD_LIBRARY_DIR})
separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
add_definitions(${LLVM_DEFINITIONS_LIST})

# Note: Tamagoyaki's own include/ and the tablegen output under
# ${CMAKE_CURRENT_BINARY_DIR}/include are deliberately *not* added at directory
# scope. They are usage requirements of MLIREquivalence/MLIREmatch/
# TamagoyakiTiming (see tamagoyaki_public_includes in src/CMakeLists.txt), so
# that a subproject here compiles against exactly the interface an out-of-tree
# consumer gets from find_package(Tamagoyaki) -- and a gap in that interface
# breaks this build rather than only the downstream one.
add_subdirectory(include)
add_subdirectory(src)
add_subdirectory(test)

# cranelift-mlir subproject (optional, can be disabled)
#
# The two case studies that used to sit alongside it -- herbie_mlir and
# rover-mlir -- now live in their own repository, which consumes Tamagoyaki
# through the package exported below:
#   https://github.com/jumerckx/tamagoyaki-case-studies
# cranelift-mlir stays because it needs nothing beyond MLIR, and because it is
# also buildable standalone: CI builds it that way against an install prefix,
# which is what keeps the exported interface from quietly rotting.
option(BUILD_CRANELIFT_MLIR "Build cranelift-mlir subproject" ON)
if(BUILD_CRANELIFT_MLIR)
  add_subdirectory(cranelift-mlir)
endif()

# check-all: run all test suites that are enabled. Subprojects without a
# lit suite are still pulled in as build deps so CI fails on a compile
# break instead of silently skipping them.
set(CHECK_ALL_DEPENDS check-tamagoyaki)
if(BUILD_CRANELIFT_MLIR)
  list(APPEND CHECK_ALL_DEPENDS check-cranelift-mlir)
endif()
add_custom_target(check-all DEPENDS ${CHECK_ALL_DEPENDS})
set_target_properties(check-all PROPERTIES FOLDER "Tests")

# ============================================================================
# Package export
# ============================================================================
# Tamagoyaki is meant to be consumed out of tree with
# find_package(Tamagoyaki CONFIG): a case-study repo builds against an
# installed -- or merely configured -- Tamagoyaki instead of pulling it in
# with add_subdirectory(). Two config files are generated so Tamagoyaki_DIR
# can point either at an install prefix or, for the development loop, straight
# at a build directory with nothing installed.
include(CMakePackageConfigHelpers)

set(TAMAGOYAKI_INSTALL_CMAKEDIR ${CMAKE_INSTALL_LIBDIR}/cmake/tamagoyaki)
set(TAMAGOYAKI_BUILD_CMAKEDIR lib/cmake/tamagoyaki)

# TamagoyakiConfig.cmake includes this next to itself, so the build tree needs
# its own copy for the build-tree config to resolve.
configure_file(cmake/TableGenHelpers.cmake
               ${CMAKE_BINARY_DIR}/${TAMAGOYAKI_BUILD_CMAKEDIR}/TableGenHelpers.cmake
               COPYONLY)

# --- build tree ---
set(TAMAGOYAKI_CONFIG_TOOLSDIR bin)
set(TAMAGOYAKI_CONFIG_CMAKEDIR ${TAMAGOYAKI_BUILD_CMAKEDIR})
configure_package_config_file(
  cmake/TamagoyakiConfig.cmake.in
  ${CMAKE_BINARY_DIR}/${TAMAGOYAKI_BUILD_CMAKEDIR}/TamagoyakiConfig.cmake
  INSTALL_DESTINATION ${TAMAGOYAKI_BUILD_CMAKEDIR}
  INSTALL_PREFIX ${CMAKE_BINARY_DIR}
  PATH_VARS TAMAGOYAKI_CONFIG_TOOLSDIR TAMAGOYAKI_CONFIG_CMAKEDIR)

export(EXPORT TamagoyakiTargets
       FILE ${CMAKE_BINARY_DIR}/${TAMAGOYAKI_BUILD_CMAKEDIR}/TamagoyakiTargets.cmake)

write_basic_package_version_file(
  ${CMAKE_BINARY_DIR}/${TAMAGOYAKI_BUILD_CMAKEDIR}/TamagoyakiConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMinorVersion)

# --- install tree ---
set(TAMAGOYAKI_CONFIG_TOOLSDIR ${CMAKE_INSTALL_BINDIR})
set(TAMAGOYAKI_CONFIG_CMAKEDIR ${TAMAGOYAKI_INSTALL_CMAKEDIR})
configure_package_config_file(
  cmake/TamagoyakiConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/cmake-install/TamagoyakiConfig.cmake
  INSTALL_DESTINATION ${TAMAGOYAKI_INSTALL_CMAKEDIR}
  PATH_VARS TAMAGOYAKI_CONFIG_TOOLSDIR TAMAGOYAKI_CONFIG_CMAKEDIR)

install(EXPORT TamagoyakiTargets DESTINATION ${TAMAGOYAKI_INSTALL_CMAKEDIR})
install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/cmake-install/TamagoyakiConfig.cmake
        ${CMAKE_BINARY_DIR}/${TAMAGOYAKI_BUILD_CMAKEDIR}/TamagoyakiConfigVersion.cmake
        cmake/TableGenHelpers.cmake
        DESTINATION ${TAMAGOYAKI_INSTALL_CMAKEDIR})

# Headers. The hand-written tree and the tablegen output land together in one
# flat directory because every consumer spells them unprefixed
# (#include "EquivalenceDialect.h") and the public headers include their own
# .h.inc. The .td files come along so a downstream dialect can include them.
install(DIRECTORY include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki
        FILES_MATCHING PATTERN "*.h" PATTERN "*.td")
# Spelled "vendor/mlir/..." by the public headers, so it keeps its prefix.
install(DIRECTORY vendor
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki
        FILES_MATCHING PATTERN "*.h")
install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/tamagoyaki
        FILES_MATCHING PATTERN "*.inc"
        PATTERN "CMakeFiles" EXCLUDE)
