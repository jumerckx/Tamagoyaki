# herbie-mlir headers

set(LLVM_TARGET_DEFINITIONS HerbieMLIRPasses.td)

mlir_tablegen(HerbieMLIRPasses.h.inc --gen-pass-decls -name HerbieMLIR)
set(PASS_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})

mlir_tablegen(HerbieMLIROpInterfaces.h.inc -gen-op-interface-decls)
set(OPINTERFACE_H_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})
mlir_tablegen(HerbieMLIROpInterfaces.cpp.inc -gen-op-interface-defs)
set(OPINTERFACE_CPP_INC_TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT})


add_public_tablegen_target(HerbieMLIRPassesIncGen)

set(herbie_mlir_generated_files
  ${CMAKE_CURRENT_SOURCE_DIR}/HerbieMLIRPasses.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/HerbieMLIROpInterfaces.h.inc
  ${CMAKE_CURRENT_SOURCE_DIR}/HerbieMLIROpInterfaces.cpp.inc
)

set(DST ${CMAKE_CURRENT_SOURCE_DIR})

# copy generated files from build dir to here
add_custom_command(
  OUTPUT ${herbie_mlir_generated_files}
  DEPENDS HerbieMLIRPassesIncGen
  COMMENT "copying generated HerbieMLIR files from build to src include dir"
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${PASS_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPINTERFACE_H_INC_TABLEGEN_OUTPUT}
      ${DST}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
      ${OPINTERFACE_CPP_INC_TABLEGEN_OUTPUT}
      ${DST}
)

add_custom_target(copy_herbie_mlir_generated_to_src_include DEPENDS ${herbie_mlir_generated_files})
