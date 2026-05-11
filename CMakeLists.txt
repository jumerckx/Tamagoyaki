cmake_minimum_required(VERSION 3.20.0)
project(mmlir LANGUAGES CXX C)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
if(CMAKE_EXPORT_COMPILE_COMMANDS)
  set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES 
      ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
endif()


set(CMAKE_BUILD_WITH_INSTALL_NAME_DIR ON)

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")

include(GNUInstallDirs)

option(ENABLE_ASAN "Enable AddressSanitizer" OFF)
if(ENABLE_ASAN)
  add_compile_options(-fsanitize=address -fno-omit-frame-pointer)
  add_link_options(-fsanitize=address)
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

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${MLIR_INCLUDE_DIRS})
link_directories(${LLVM_BUILD_LIBRARY_DIR})
add_definitions(${LLVM_DEFINITIONS})

add_subdirectory(include)
include_directories(include)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include)
add_subdirectory(src)
add_subdirectory(test)

# herbie_mlir subproject (optional, can be disabled)
option(BUILD_HERBIE_MLIR "Build herbie_mlir subproject" ON)
if(BUILD_HERBIE_MLIR)
  add_subdirectory(herbie_mlir)
endif()

# rover-mlir subproject (optional, can be disabled)
option(BUILD_ROVER_MLIR "Build rover-mlir subproject" ON)
if(BUILD_ROVER_MLIR)
  find_package(CIRCT REQUIRED CONFIG)
  message(STATUS "Using CIRCTConfig.cmake in: ${CIRCT_DIR}")
  list(APPEND CMAKE_MODULE_PATH "${CIRCT_CMAKE_DIR}")
  include_directories(${CIRCT_INCLUDE_DIRS})
  add_subdirectory(rover-mlir)
endif()

# cranelift-mlir subproject (optional, can be disabled)
option(BUILD_CRANELIFT_MLIR "Build cranelift-mlir subproject" ON)
if(BUILD_CRANELIFT_MLIR)
  add_subdirectory(cranelift-mlir)
endif()

# check-all: run all test suites that are enabled
set(CHECK_ALL_DEPENDS check-tamagoyaki)
if(BUILD_HERBIE_MLIR)
  list(APPEND CHECK_ALL_DEPENDS check-herbie-mlir)
endif()
if(BUILD_CRANELIFT_MLIR)
  list(APPEND CHECK_ALL_DEPENDS check-cranelift-mlir)
endif()
add_custom_target(check-all DEPENDS ${CHECK_ALL_DEPENDS})
set_target_properties(check-all PROPERTIES FOLDER "Tests")
