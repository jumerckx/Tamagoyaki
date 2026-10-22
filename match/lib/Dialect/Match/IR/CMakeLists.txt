add_mlir_dialect_library(MLIRMatchDialect
  Match.cpp

  ADDITIONAL_HEADER_DIRS
  ${MATCH_INCLUDE_DIR}/mlir/Dialect/Match

  DEPENDS
  MLIRMatchOpsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPDLDialect
  MLIRSideEffectInterfaces
  )
