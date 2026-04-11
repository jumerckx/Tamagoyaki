# fix_rival3_native.cmake
# Called with -DNATIVE_GLOB=<glob> -DRACKET_SUBPATH=<subpath>
#
# Rival3 ships pre-built native libraries under platform names like
# "aarch64-macosx", but Nix Racket may use "aarch64-darwin".
# If the directory for RACKET_SUBPATH doesn't exist, create a symlink
# from the first matching platform directory.

file(GLOB _native_dirs "${NATIVE_GLOB}")
foreach(_native_dir ${_native_dirs})
  set(_target "${_native_dir}/${RACKET_SUBPATH}")
  if(EXISTS "${_target}")
    message(STATUS "rival3 native dir already exists: ${_target}")
    continue()
  endif()

  # Find an existing platform dir that looks like a match
  # (same arch prefix, different OS suffix).
  string(REGEX MATCH "^([^-]+)" _arch "${RACKET_SUBPATH}")
  file(GLOB _candidates "${_native_dir}/${_arch}-*")
  list(LENGTH _candidates _n)
  if(_n GREATER 0)
    list(GET _candidates 0 _src)
    message(STATUS "Symlinking rival3 native: ${_target} -> ${_src}")
    file(CREATE_LINK "${_src}" "${_target}" SYMBOLIC)
  else()
    message(WARNING "No matching rival3 native dir for ${RACKET_SUBPATH} in ${_native_dir}")
  endif()
endforeach()
