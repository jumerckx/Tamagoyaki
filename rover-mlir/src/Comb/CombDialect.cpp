#include "Comb.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace comb;

#include "CombDialect.cpp.inc"

// #include "CombEnums.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "CombAttrs.cpp.inc"

#define GET_OP_CLASSES
#include "CombOps.cpp.inc"

void CombDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "CombOps.cpp.inc"
      >();
  addAttributes<
#define GET_ATTRDEF_LIST
#include "CombAttrs.cpp.inc"
      >();
}

static unsigned getTotalWidth(ValueRange inputs) {
  unsigned resultWidth = 0;
  for (auto input : inputs) {
    auto intType = mlir::cast<mlir::IntegerType>(input.getType());
    resultWidth += intType.getWidth();
  }
  return resultWidth;
}

LogicalResult ConcatOp::inferReturnTypes(MLIRContext *context,
                                         std::optional<Location> loc,
                                         mlir::ValueRange operands,
                                         mlir::DictionaryAttr attrs,
                                         mlir::OpaqueProperties properties,
                                         mlir::RegionRange regions,
                                         SmallVectorImpl<Type> &results) {
  unsigned resultWidth = getTotalWidth(operands);
  results.push_back(IntegerType::get(context, resultWidth));
  return success();
}

/// Parse a ConcatOp that can either follow the format:
/// $inputs attr-dict `:` qualified(type($inputs))
/// or have no operands, colon and typelist.
ParseResult ConcatOp::parse(OpAsmParser &parser, OperationState &result) {
  SmallVector<OpAsmParser::UnresolvedOperand, 4> operands;
  SmallVector<Type, 4> types;

  llvm::SMLoc allOperandLoc = parser.getCurrentLocation();

  // Parse the operand list, attributes and colon
  if (parser.parseOperandList(operands) ||
      parser.parseOptionalAttrDict(result.attributes) || parser.parseColon())
    return failure();

  // Parse an optional list of types
  Type parsedType;
  auto parseResult = parser.parseOptionalType(parsedType);
  if (parseResult.has_value()) {
    if (failed(parseResult.value()))
      return failure();
    types.push_back(parsedType);
    while (succeeded(parser.parseOptionalComma())) {
      if (parser.parseType(parsedType))
        return failure();
      types.push_back(parsedType);
    }
  }

  if (parser.resolveOperands(operands, types, allOperandLoc, result.operands))
    return failure();

  SmallVector<Type, 1> inferredTypes;
  if (failed(ConcatOp::inferReturnTypes(
          parser.getContext(), result.location, result.operands,
          result.attributes.getDictionary(parser.getContext()),
          result.getRawProperties(), {}, inferredTypes)))
    return failure();

  result.addTypes(inferredTypes);
  return success();
}

void ConcatOp::print(OpAsmPrinter &p) {
  p << " ";
  p.printOperands(getOperands());
  p.printOptionalAttrDict((*this)->getAttrs());
  p << " : ";
  llvm::interleaveComma(getOperandTypes(), p);
}
