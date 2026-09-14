# cranelift-mlir: Cranelift backend in MLIR
#
# Buildable two ways: as a subdirectory of the Tamagoyaki tree, and standalone
# against a Tamagoyaki that was found with find_package.
# CI tests the latter to ensure external standalone projects can do the same.
#
# Standalone:
#   cmake -S cranelift-mlir -B <build> -GNinja \
#         -DCMAKE_PREFIX_PATH=<tamagoyaki-install-prefix-or-build-dir>
cmake_minimum_required(VERSION 3.20.0)

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(cranelift-mlir LANGUAGES CXX C)

  set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")
  set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  include(GNUInstallDirs)

  find_package(MLIR REQUIRED CONFIG)
  message(STATUS "Using MLIRConfig.cmake in: ${MLIR_DIR}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

  # Brings the MLIREquivalence / MLIREmatch / TamagoyakiTiming imported targets
  # and add_dialect_tablegen().
  find_package(Tamagoyaki REQUIRED CONFIG)
  message(STATUS "Using TamagoyakiConfig.cmake in: ${Tamagoyaki_DIR}")

  list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")
  list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
  include(TableGen)
  include(AddLLVM)
  include(AddMLIR)
  include(HandleLLVMOptions)

  set(LLVM_RUNTIME_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/bin)
  set(LLVM_LIBRARY_OUTPUT_INTDIR ${CMAKE_BINARY_DIR}/lib)
  set(MLIR_BINARY_DIR ${CMAKE_BINARY_DIR})

  include_directories(${LLVM_INCLUDE_DIRS})
  include_directories(${MLIR_INCLUDE_DIRS})
  link_directories(${LLVM_BUILD_LIBRARY_DIR})
  separate_arguments(LLVM_DEFINITIONS_LIST NATIVE_COMMAND ${LLVM_DEFINITIONS})
  add_definitions(${LLVM_DEFINITIONS_LIST})
endif()

# Addressed through these rather than CMAKE_BINARY_DIR/PROJECT_SOURCE_DIR,
# which mean different things in the two modes above.
set(CRANELIFT_MLIR_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(CRANELIFT_MLIR_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})

add_subdirectory(include)
add_subdirectory(src)

option(CRANELIFT_MLIR_BUILD_TOOLS "Build cranelift-mlir tools (cranelift-mlir-opt)" ON)
if(CRANELIFT_MLIR_BUILD_TOOLS)
    add_subdirectory(tools)
endif()

add_subdirectory(test)
