# rival-rs C API integration
# Pulls Rival from GitHub and builds the C API library

include(FetchContent)

# Configuration options
set(RIVAL_REPO_URL "https://github.com/herbie-fp/rival-rs.git"
    CACHE STRING "URL of the Rival repository")
set(RIVAL_GIT_TAG "main"
    CACHE STRING "Git tag/branch of Rival to use")
set(RIVAL_ENABLE_LOCAL_DEV OFF
    CACHE BOOL "Use local Rival development (set RIVAL_LOCAL_PATH)")
set(RIVAL_LOCAL_PATH ""
    CACHE PATH "Path to local Rival repository for development")

# Handle local development mode
if(RIVAL_ENABLE_LOCAL_DEV)
  if(NOT RIVAL_LOCAL_PATH)
    message(FATAL_ERROR "RIVAL_ENABLE_LOCAL_DEV=ON requires RIVAL_LOCAL_PATH to be set")
  endif()
  set(RIVAL_SOURCE_DIR "${RIVAL_LOCAL_PATH}")
  message(STATUS "Using local Rival from: ${RIVAL_LOCAL_PATH}")
else()
  # Fetch from GitHub
  FetchContent_Declare(
    rival
    GIT_REPOSITORY "${RIVAL_REPO_URL}"
    GIT_TAG "${RIVAL_GIT_TAG}"
    GIT_SHALLOW ON
    GIT_PROGRESS ON
  )
  
  FetchContent_MakeAvailable(rival)
  set(RIVAL_SOURCE_DIR "${rival_SOURCE_DIR}")
  message(STATUS "Fetched Rival from: ${RIVAL_REPO_URL} (${RIVAL_GIT_TAG})")
endif()

# Find Rust toolchain
find_program(CARGO cargo REQUIRED)
find_program(RUSTC rustc REQUIRED)

message(STATUS "Using Cargo: ${CARGO}")
message(STATUS "Using Rustc: ${RUSTC}")

# Determine target triple
if(CMAKE_SYSTEM_PROCESSOR MATCHES "arm64|aarch64")
  set(RUST_TARGET_TRIPLE "aarch64-apple-darwin")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
  set(RUST_TARGET_TRIPLE "x86_64-apple-darwin")
else()
  set(RUST_TARGET_TRIPLE "")
endif()

# Build configuration
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CARGO_BUILD_FLAGS "")
  set(RIVAL_BUILD_PROFILE "debug")
else()
  set(CARGO_BUILD_FLAGS "--release")
  set(RIVAL_BUILD_PROFILE "release")
endif()

# Create custom target for building Rival via cargo
set(RIVAL_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(RIVAL_LIB_DIR "${RIVAL_BUILD_DIR}/lib")

# Determine library name and extension
if(APPLE)
  set(RIVAL_LIB_NAME "libherbie_rival.a")
elseif(UNIX)
  set(RIVAL_LIB_NAME "libherbie_rival.a")
else()
  set(RIVAL_LIB_NAME "herbie_rival.lib")
endif()

set(RIVAL_LIB_PATH "${RIVAL_LIB_DIR}/${RIVAL_LIB_NAME}")

add_custom_target(
  buildRival ALL
  COMMAND ${CMAKE_COMMAND} -E make_directory "${RIVAL_LIB_DIR}"
  COMMAND
    ${CMAKE_COMMAND} -E env
    CARGO_TARGET_DIR="${RIVAL_BUILD_DIR}/target"
    ${CARGO} build
    ${CARGO_BUILD_FLAGS}
    --manifest-path "${RIVAL_SOURCE_DIR}/Cargo.toml"
    --lib
    -p "rival"
  COMMAND
    ${CMAKE_COMMAND} -E copy
    "${RIVAL_BUILD_DIR}/target/${RIVAL_BUILD_PROFILE}/librival.a"
    "${RIVAL_LIB_PATH}"
  WORKING_DIRECTORY "${RIVAL_SOURCE_DIR}"
  DEPENDS "${RIVAL_SOURCE_DIR}/Cargo.toml"
  COMMENT "Building Rival C library via cargo"
)

# Create imported library target
add_library(RivalCLib STATIC IMPORTED GLOBAL)
set_target_properties(RivalCLib PROPERTIES
  IMPORTED_LOCATION "${RIVAL_LIB_PATH}"
  INTERFACE_INCLUDE_DIRECTORIES "${RIVAL_SOURCE_DIR}"
)
add_dependencies(RivalCLib buildRival)

# Expose via interface library for easy consumption
add_library(Rival INTERFACE)
target_link_libraries(Rival INTERFACE RivalCLib)
target_include_directories(Rival INTERFACE "${RIVAL_SOURCE_DIR}")

message(STATUS "Rival C API:")
message(STATUS "  Include dir: ${RIVAL_SOURCE_DIR}")
message(STATUS "  Library: ${RIVAL_LIB_PATH}")
