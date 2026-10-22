set(LLVM_TARGET_DEFINITIONS MatchConversionPasses.td)
mlir_tablegen(MatchConversionPasses.h.inc -gen-pass-decls -name MatchConversion)
add_public_tablegen_target(MLIRMatchConversionPassIncGen)
