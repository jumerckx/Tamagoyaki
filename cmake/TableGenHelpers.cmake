# TableGenHelpers.cmake - Helper functions for MLIR TableGen code generation
#
# This module provides functions to simplify the setup of TableGen-generated
# files and their copying from build to source directories.

# add_dialect_tablegen - Generate and copy TableGen files for an MLIR dialect
#
# Usage:
#   add_dialect_tablegen(
#     NAME Equivalence                    # Dialect name (used for file naming)
#     NAMESPACE equivalence               # Dialect namespace
#     TD_FILE EquivalenceDialect.td       # Input .td file
#     DEST_DIR ${CMAKE_CURRENT_SOURCE_DIR} # Where to copy generated files
#     COMPONENTS Ops Types Attrs Dialect Passes  # Which components to generate
#   )
#
# This creates:
#   - TableGen targets: MLIR${NAME}IncGen
#   - Copy target: copy_${lowercase_name}_generated_td_to_src_include
#   - Output variable: ${NAME}_GENERATED_HEADERS (list of copied .inc files)
#
function(add_dialect_tablegen)
  cmake_parse_arguments(ARG "" "NAME;NAMESPACE;TD_FILE;DEST_DIR" "COMPONENTS" ${ARGN})

  if(NOT ARG_NAME OR NOT ARG_NAMESPACE OR NOT ARG_TD_FILE OR NOT ARG_DEST_DIR OR NOT ARG_COMPONENTS)
    message(FATAL_ERROR "add_dialect_tablegen requires NAME, NAMESPACE, TD_FILE, DEST_DIR, and COMPONENTS")
  endif()

  set(LLVM_TARGET_DEFINITIONS ${ARG_TD_FILE})

  set(build_files "")
  set(generated_files "")

  foreach(component ${ARG_COMPONENTS})
    if(component STREQUAL "Ops")
      mlir_tablegen(${ARG_NAME}Ops.h.inc -gen-op-decls)
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      mlir_tablegen(${ARG_NAME}Ops.cpp.inc -gen-op-defs)
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files
        ${ARG_DEST_DIR}/${ARG_NAME}Ops.h.inc
        ${ARG_DEST_DIR}/${ARG_NAME}Ops.cpp.inc)

    elseif(component STREQUAL "Types")
      mlir_tablegen(${ARG_NAME}Types.h.inc -gen-typedef-decls -typedefs-dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      mlir_tablegen(${ARG_NAME}Types.cpp.inc -gen-typedef-defs -typedefs-dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files
        ${ARG_DEST_DIR}/${ARG_NAME}Types.h.inc
        ${ARG_DEST_DIR}/${ARG_NAME}Types.cpp.inc)

    elseif(component STREQUAL "Attrs")
      mlir_tablegen(${ARG_NAME}Attrs.h.inc -gen-attrdef-decls -attrdefs-dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      mlir_tablegen(${ARG_NAME}Attrs.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files
        ${ARG_DEST_DIR}/${ARG_NAME}Attrs.h.inc
        ${ARG_DEST_DIR}/${ARG_NAME}Attrs.cpp.inc)

    elseif(component STREQUAL "Dialect")
      mlir_tablegen(${ARG_NAME}Dialect.h.inc -gen-dialect-decls -dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      mlir_tablegen(${ARG_NAME}Dialect.cpp.inc -gen-dialect-defs -dialect=${ARG_NAMESPACE})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files
        ${ARG_DEST_DIR}/${ARG_NAME}Dialect.h.inc
        ${ARG_DEST_DIR}/${ARG_NAME}Dialect.cpp.inc)

    elseif(component STREQUAL "Passes")
      mlir_tablegen(${ARG_NAME}Passes.h.inc --gen-pass-decls -name ${ARG_NAME})
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files ${ARG_DEST_DIR}/${ARG_NAME}Passes.h.inc)

    elseif(component STREQUAL "OpInterfaces")
      mlir_tablegen(${ARG_NAME}OpInterfaces.h.inc -gen-op-interface-decls)
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      mlir_tablegen(${ARG_NAME}OpInterfaces.cpp.inc -gen-op-interface-defs)
      list(APPEND build_files ${TABLEGEN_OUTPUT})
      list(APPEND generated_files
        ${ARG_DEST_DIR}/${ARG_NAME}OpInterfaces.h.inc
        ${ARG_DEST_DIR}/${ARG_NAME}OpInterfaces.cpp.inc)

    else()
      message(FATAL_ERROR "Unknown component: ${component}. Supported: Ops, Types, Attrs, Dialect, Passes, OpInterfaces")
    endif()
  endforeach()

  add_public_tablegen_target(MLIR${ARG_NAME}IncGen)

  # Build copy commands
  set(copy_commands "")
  list(LENGTH build_files num_files)
  math(EXPR last_index "${num_files} - 1")
  foreach(i RANGE ${last_index})
    list(GET build_files ${i} build_file)
    list(APPEND copy_commands
      COMMAND ${CMAKE_COMMAND} -E copy ${build_file} ${ARG_DEST_DIR})
  endforeach()

  string(TOLOWER ${ARG_NAME} name_lower)

  add_custom_command(
    OUTPUT ${generated_files}
    DEPENDS MLIR${ARG_NAME}IncGen ${build_files}
    COMMENT "Copying generated ${ARG_NAME} TableGen files to source directory"
    ${copy_commands}
  )

  add_custom_target(copy_${name_lower}_generated_td_to_src_include DEPENDS ${generated_files})

  # Export generated headers list to parent scope
  set(${ARG_NAME}_GENERATED_HEADERS ${generated_files} PARENT_SCOPE)
  set(${ARG_NAME}_TABLEGEN_TARGET MLIR${ARG_NAME}IncGen PARENT_SCOPE)
  set(${ARG_NAME}_COPY_TARGET copy_${name_lower}_generated_td_to_src_include PARENT_SCOPE)
endfunction()

# set_source_object_depends - Set OBJECT_DEPENDS property on source files
#
# Usage:
#   set_source_object_depends(
#     SOURCES file1.cpp file2.cpp
#     DEPENDS ${HEADER_LIST}
#   )
#
function(set_source_object_depends)
  cmake_parse_arguments(ARG "" "" "SOURCES;DEPENDS" ${ARGN})

  if(NOT ARG_SOURCES OR NOT ARG_DEPENDS)
    message(FATAL_ERROR "set_source_object_depends requires SOURCES and DEPENDS")
  endif()

  foreach(source ${ARG_SOURCES})
    set_source_files_properties(${source}
      PROPERTIES OBJECT_DEPENDS "${ARG_DEPENDS}"
    )
  endforeach()
endfunction()
