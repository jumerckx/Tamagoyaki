#include "Datapath.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace datapath;

#include "DatapathDialect.cpp.inc"

// #include "DatapathEnums.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "DatapathAttrs.cpp.inc"

void DatapathDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "DatapathOps.cpp.inc"
      >();
  addAttributes<
#define GET_ATTRDEF_LIST
#include "DatapathAttrs.cpp.inc"
      >();
}

// Parser for the custom type format
// Parser for "<input-type> [<num-inputs> -> <num-outputs>]"
static ParseResult parseCompressFormat(OpAsmParser &parser,
                                       SmallVectorImpl<Type> &inputTypes,
                                       SmallVectorImpl<Type> &resultTypes) {

  int64_t inputCount, resultCount;
  Type inputElementType;

  if (parser.parseType(inputElementType) || parser.parseLSquare() ||
      parser.parseInteger(inputCount) || parser.parseArrow() ||
      parser.parseInteger(resultCount) || parser.parseRSquare())
    return failure();

  // Inputs and results have same type
  inputTypes.assign(inputCount, inputElementType);
  resultTypes.assign(resultCount, inputElementType);

  return success();
}

// Printer for "<input-type> [<num-inputs> -> <num-outputs>]"
static void printCompressFormat(OpAsmPrinter &printer, Operation *op,
                                TypeRange inputTypes, TypeRange resultTypes) {

  printer << inputTypes[0] << " [" << inputTypes.size() << " -> "
          << resultTypes.size() << "]";
}

//===----------------------------------------------------------------------===//
// TableGen generated logic.
//===----------------------------------------------------------------------===//
#define GET_OP_CLASSES
#include "DatapathOps.cpp.inc"