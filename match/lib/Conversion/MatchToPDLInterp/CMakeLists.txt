add_mlir_conversion_library(MLIRMatchToPDLInterp
  MatchToPDLInterp.cpp

  ADDITIONAL_HEADER_DIRS
  ${MATCH_INCLUDE_DIR}/mlir/Conversion/MatchToPDLInterp

  DEPENDS
  MLIRMatchConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRMatchDialect
  MLIRPDLInterpDialect
  MLIRPass
  )
