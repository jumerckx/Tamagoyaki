# Equivalence dialect
set(dialect Equivalence)
set(dialect_namespace equivalence)
set(LLVM_TARGET_DEFINITIONS ${dialect}Dialect.td)

mlir_tablegen(${dialect}Ops.h.inc -gen-op-decls)
set(OPS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Ops.cpp.inc -gen-op-defs)
set(OPS_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Types.h.inc -gen-typedef-decls
              -typedefs-dialect=${dialect_namespace})
set(TYPES_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Types.cpp.inc -gen-typedef-defs
              -typedefs-dialect=${dialect_namespace})
set(TYPES_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Attrs.h.inc -gen-attrdef-decls
              -attrdefs-dialect=${dialect_namespace})
set(ATTRS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Attrs.cpp.inc -gen-attrdef-defs
              -attrdefs-dialect=${dialect_namespace})
set(ATTRS_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Dialect.h.inc -gen-dialect-decls
              -dialect=${dialect_namespace})
set(DIALECT_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Dialect.cpp.inc -gen-dialect-defs
              -dialect=${dialect_namespace})
set(DIALECT_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(EquivalencePasses.h.inc --gen-pass-decls)
set(PASS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})

add_public_tablegen_target(MLIR${dialect}IncGen)

set(equivalence_generated_files
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Types.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Types.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attrs.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Attrs.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Dialect.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Dialect.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Passes.h.inc
)

set(DST ${CMAKE_CURRENT_SOURCE_DIR})

# copy generated files from build dir to here
add_custom_command(
  OUTPUT ${equivalence_generated_files}
  DEPENDS MLIR${dialect}IncGen
  COMMENT "copying generated td files from build to src include dir"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPS_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${TYPES_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${TYPES_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${ATTRS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${ATTRS_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${DIALECT_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${DIALECT_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${PASS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
)

add_custom_target(copy_equivalence_generated_td_to_src_include DEPENDS ${equivalence_generated_files})

# Ematch dialect
set(dialect Ematch)
set(dialect_namespace ematch)
set(LLVM_TARGET_DEFINITIONS ${dialect}Dialect.td)

mlir_tablegen(${dialect}Ops.h.inc -gen-op-decls)
set(OPS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Ops.cpp.inc -gen-op-defs)
set(OPS_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Dialect.h.inc -gen-dialect-decls
              -dialect=${dialect_namespace})
set(DIALECT_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Dialect.cpp.inc -gen-dialect-defs
              -dialect=${dialect_namespace})
set(DIALECT_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(${dialect}Passes.h.inc --gen-pass-decls)
set(PASS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})

add_public_tablegen_target(MLIR${dialect}IncGen)

set(ematch_generated_files
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Ops.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Dialect.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Dialect.cpp.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/${dialect}Passes.h.inc
)

# copy generated files from build dir to here
add_custom_command(
  OUTPUT ${ematch_generated_files}
  DEPENDS MLIR${dialect}IncGen
  COMMENT "copying generated td files from build to src include dir"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPS_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${DIALECT_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${DIALECT_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${PASS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
)

add_custom_target(copy_ematch_generated_td_to_src_include DEPENDS ${ematch_generated_files})
