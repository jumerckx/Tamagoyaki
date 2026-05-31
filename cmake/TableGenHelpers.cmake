# TableGenHelpers.cmake - Helper functions for MLIR TableGen code generation
#
# This module provides functions to simplify the setup of TableGen-generated
# files for MLIR dialects.

# add_dialect_tablegen - Generate TableGen files for an MLIR dialect
#
# Usage:
#   add_dialect_tablegen(
#     NAME Equivalence                    # Dialect name (used for file naming)
#     NAMESPACE equivalence               # Dialect namespace
#     TD_FILE EquivalenceDialect.td       # Input .td file
#     COMPONENTS Ops Types Attrs Dialect Passes  # Which components to generate
#     [NO_DOCS]                           # Skip markdown documentation generation
#   )
#
# This creates:
#   - TableGen target: MLIR${NAME}IncGen
#
# Documentation: unless NO_DOCS is given, markdown docs are generated through
# MLIR's add_mlir_doc() infrastructure and attached to the `mlir-doc` target:
#   - a `Dialect` component => `-gen-dialect-doc` (ops, types, attributes)
#     -> ${MLIR_BINARY_DIR}/docs/Dialects/${NAME}Dialect.md
#   - a `Passes` component  => `-gen-pass-doc`
#     -> ${MLIR_BINARY_DIR}/docs/Dialects/${NAME}Passes.md
# Build them with:  cmake --build <build-dir> --target mlir-doc
#
function(add_dialect_tablegen)
  cmake_parse_arguments(ARG "NO_DOCS" "NAME;NAMESPACE;TD_FILE" "COMPONENTS" ${ARGN})

  if(NOT ARG_NAME OR NOT ARG_NAMESPACE OR NOT ARG_TD_FILE OR NOT ARG_COMPONENTS)
    message(FATAL_ERROR "add_dialect_tablegen requires NAME, NAMESPACE, TD_FILE, and COMPONENTS")
  endif()

  set(LLVM_TARGET_DEFINITIONS ${ARG_TD_FILE})

  foreach(component ${ARG_COMPONENTS})
    if(component STREQUAL "Ops")
      mlir_tablegen(${ARG_NAME}Ops.h.inc -gen-op-decls)
      mlir_tablegen(${ARG_NAME}Ops.cpp.inc -gen-op-defs)

    elseif(component STREQUAL "Types")
      mlir_tablegen(${ARG_NAME}Types.h.inc -gen-typedef-decls -typedefs-dialect=${ARG_NAMESPACE})
      mlir_tablegen(${ARG_NAME}Types.cpp.inc -gen-typedef-defs -typedefs-dialect=${ARG_NAMESPACE})

    elseif(component STREQUAL "Attrs")
      mlir_tablegen(${ARG_NAME}Attrs.h.inc -gen-attrdef-decls -attrdefs-dialect=${ARG_NAMESPACE})
      mlir_tablegen(${ARG_NAME}Attrs.cpp.inc -gen-attrdef-defs -attrdefs-dialect=${ARG_NAMESPACE})

    elseif(component STREQUAL "Dialect")
      mlir_tablegen(${ARG_NAME}Dialect.h.inc -gen-dialect-decls -dialect=${ARG_NAMESPACE})
      mlir_tablegen(${ARG_NAME}Dialect.cpp.inc -gen-dialect-defs -dialect=${ARG_NAMESPACE})

    elseif(component STREQUAL "Enums")
      mlir_tablegen(${ARG_NAME}Enums.h.inc -gen-enum-decls)
      mlir_tablegen(${ARG_NAME}Enums.cpp.inc -gen-enum-defs)

    elseif(component STREQUAL "Passes")
      mlir_tablegen(${ARG_NAME}Passes.h.inc --gen-pass-decls -name ${ARG_NAME})

    elseif(component STREQUAL "OpInterfaces")
      mlir_tablegen(${ARG_NAME}OpInterfaces.h.inc -gen-op-interface-decls)
      mlir_tablegen(${ARG_NAME}OpInterfaces.cpp.inc -gen-op-interface-defs)

    else()
      message(FATAL_ERROR "Unknown component: ${component}. Supported: Ops, Types, Attrs, Dialect, Enums, Passes, OpInterfaces")
    endif()
  endforeach()

  add_public_tablegen_target(MLIR${ARG_NAME}IncGen)

  set(${ARG_NAME}_TABLEGEN_TARGET MLIR${ARG_NAME}IncGen PARENT_SCOPE)

  # --------------------------------------------------------------------------
  # Documentation generation (MLIR's add_mlir_doc infrastructure).
  # --------------------------------------------------------------------------
  if(ARG_NO_DOCS)
    return()
  endif()

  # add_mlir_doc() expects the .td base name (it appends ".td" itself).
  get_filename_component(_doc_basename ${ARG_TD_FILE} NAME_WE)

  list(FIND ARG_COMPONENTS "Dialect" _has_dialect)
  if(NOT _has_dialect EQUAL -1)
    # -gen-dialect-doc emits a single page covering the dialect's operations,
    # types and attributes.
    add_mlir_doc(${_doc_basename} ${ARG_NAME}Dialect Dialects/
      -gen-dialect-doc -dialect=${ARG_NAMESPACE})
  endif()

  list(FIND ARG_COMPONENTS "Passes" _has_passes)
  if(NOT _has_passes EQUAL -1)
    add_mlir_doc(${_doc_basename} ${ARG_NAME}Passes Dialects/
      -gen-pass-doc)
  endif()
endfunction()
