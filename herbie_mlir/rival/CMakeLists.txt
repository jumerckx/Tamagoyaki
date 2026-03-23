# Set the policy or use the option only when available
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.24")
    cmake_policy(SET CMP0135 NEW)
endif()

# rival-rs C API integration
# Pulls Rival from GitHub and builds the C API library
# Also builds GMP and MPFR from source for portable builds

include(FetchContent)
include(ExternalProject)

# =============================================================================
# GMP and MPFR from source
# =============================================================================

set(GMP_VERSION "6.3.0" CACHE STRING "GMP version to build")
set(MPFR_VERSION "4.2.1" CACHE STRING "MPFR version to build")

set(GMP_URL "https://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.xz")
set(MPFR_URL "https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFR_VERSION}.tar.xz")

set(DEPS_INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/deps-install")
set(DEPS_BUILD_DIR "${CMAKE_CURRENT_BINARY_DIR}/deps-build")

# Build GMP from source
ExternalProject_Add(gmp_external
    URL ${GMP_URL}
    URL_HASH SHA256=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
    PREFIX ${DEPS_BUILD_DIR}/gmp
    INSTALL_DIR ${DEPS_INSTALL_DIR}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
        --enable-static
        --disable-shared
        --with-pic
        --disable-maintainer-mode
        MAKEINFO=true
    BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    BUILD_BYPRODUCTS ${DEPS_INSTALL_DIR}/lib/libgmp.a
    LOG_DOWNLOAD TRUE
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE
)

# Build MPFR from source (depends on GMP)
ExternalProject_Add(mpfr_external
    URL ${MPFR_URL}
    URL_HASH SHA256=277807353a6726978996945af13e52829e3abd7a9a5b7fb2793894e18f1fcbb2
    PREFIX ${DEPS_BUILD_DIR}/mpfr
    INSTALL_DIR ${DEPS_INSTALL_DIR}
    CONFIGURE_COMMAND <SOURCE_DIR>/configure
        --prefix=<INSTALL_DIR>
        --enable-static
        --disable-shared
        --with-pic
        --disable-maintainer-mode
        --with-gmp=<INSTALL_DIR>
    BUILD_COMMAND make -j${CMAKE_BUILD_PARALLEL_LEVEL}
    INSTALL_COMMAND make install
    BUILD_BYPRODUCTS ${DEPS_INSTALL_DIR}/lib/libmpfr.a
    LOG_DOWNLOAD TRUE
    LOG_CONFIGURE TRUE
    LOG_BUILD TRUE
    LOG_INSTALL TRUE
    DEPENDS gmp_external
)

# Create imported targets for GMP and MPFR
add_library(GMP::GMP STATIC IMPORTED GLOBAL)
set_target_properties(GMP::GMP PROPERTIES
    IMPORTED_LOCATION ${DEPS_INSTALL_DIR}/lib/libgmp.a
    INTERFACE_INCLUDE_DIRECTORIES ${DEPS_INSTALL_DIR}/include
)
add_dependencies(GMP::GMP gmp_external)

add_library(MPFR::MPFR STATIC IMPORTED GLOBAL)
set_target_properties(MPFR::MPFR PROPERTIES
    IMPORTED_LOCATION ${DEPS_INSTALL_DIR}/lib/libmpfr.a
    INTERFACE_INCLUDE_DIRECTORIES ${DEPS_INSTALL_DIR}/include
    INTERFACE_LINK_LIBRARIES GMP::GMP
)
add_dependencies(MPFR::MPFR mpfr_external)

message(STATUS "GMP/MPFR will be built from source:")
message(STATUS "  GMP ${GMP_VERSION}: ${GMP_URL}")
message(STATUS "  MPFR ${MPFR_VERSION}: ${MPFR_URL}")
message(STATUS "  Install dir: ${DEPS_INSTALL_DIR}")

# =============================================================================
# Rival from GitHub
# =============================================================================

include(FetchContent)

# Configuration options
set(RIVAL_REPO_URL "https://github.com/herbie-fp/rival-rs.git"
    CACHE STRING "URL of the Rival repository")
set(RIVAL_GIT_TAG "main"
    CACHE STRING "Git tag/branch of Rival to use")
set(RIVAL_LOCAL_PATH ""
    CACHE PATH "Path to local Rival repository (if set, uses local dev mode; otherwise fetches from GitHub)")

# Handle local development vs GitHub fetch
if(RIVAL_LOCAL_PATH)
    if(NOT IS_DIRECTORY "${RIVAL_LOCAL_PATH}")
        message(FATAL_ERROR "RIVAL_LOCAL_PATH is set but directory does not exist: ${RIVAL_LOCAL_PATH}")
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

# Custom command that produces the library file as an explicit output
add_custom_command(
  OUTPUT "${RIVAL_LIB_PATH}"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${RIVAL_LIB_DIR}"
  COMMAND
    ${CMAKE_COMMAND} -E env
    CARGO_TARGET_DIR="${RIVAL_BUILD_DIR}/target"
    ${CARGO} build
    ${CARGO_BUILD_FLAGS}
    --manifest-path "${RIVAL_SOURCE_DIR}/rival3-ffi/Cargo.toml"
    --lib
    -p "rival3-ffi"
  COMMAND
    ${CMAKE_COMMAND} -E copy
    "${RIVAL_BUILD_DIR}/target/${RIVAL_BUILD_PROFILE}/librival3_ffi.a"
    "${RIVAL_LIB_PATH}"
  WORKING_DIRECTORY "${RIVAL_SOURCE_DIR}"
  DEPENDS "${RIVAL_SOURCE_DIR}/Cargo.toml"
  COMMENT "Building Rival C library via cargo"
)

# Custom target that depends on the library output
add_custom_target(buildRival DEPENDS "${RIVAL_LIB_PATH}")

# Create imported library target
add_library(RivalCLib STATIC IMPORTED GLOBAL)
set_target_properties(RivalCLib PROPERTIES
  IMPORTED_LOCATION "${RIVAL_LIB_PATH}"
  INTERFACE_INCLUDE_DIRECTORIES "${RIVAL_SOURCE_DIR}"
)
add_dependencies(RivalCLib buildRival)

# Expose via interface library for easy consumption
add_library(Rival INTERFACE)
target_link_libraries(Rival INTERFACE RivalCLib MPFR::MPFR GMP::GMP)
target_include_directories(Rival INTERFACE "${RIVAL_SOURCE_DIR}")

message(STATUS "Rival C API:")
message(STATUS "  Include dir: ${RIVAL_SOURCE_DIR}")
message(STATUS "  Library: ${RIVAL_LIB_PATH}")
