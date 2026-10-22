add_mlir_conversion_library(MLIRPDLToMatch
  PDLToMatch.cpp
  RewriterGen.cpp
  RootOrdering.cpp

  ADDITIONAL_HEADER_DIRS
  ${MATCH_INCLUDE_DIR}/mlir/Conversion/PDLToMatch

  DEPENDS
  MLIRMatchConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRInferTypeOpInterface
  MLIRMatchDialect
  MLIRPDLDialect
  MLIRPDLInterpDialect
  MLIRPass
  )
