add_mlir_dialect_library(MLIRMatchTransforms
  CombineMatchers.cpp

  ADDITIONAL_HEADER_DIRS
  ${MATCH_INCLUDE_DIR}/mlir/Dialect/Match/Transforms

  DEPENDS
  MLIRMatchPassIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRMatchDialect
  MLIRPass
  )
