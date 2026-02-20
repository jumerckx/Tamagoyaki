#include "HW.h"

#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/IR/OpImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace hw;

#include "HWDialect.cpp.inc"

// #include "HWEnums.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "HWAttrs.cpp.inc"

#define GET_OP_CLASSES
#include "HWOps.cpp.inc"

void HWDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "HWOps.cpp.inc"
      >();
  addAttributes<
#define GET_ATTRDEF_LIST
#include "HWAttrs.cpp.inc"
      >();
}

void ConstantOp::print(OpAsmPrinter &p) {
  p << " ";
  p.printAttribute(getValueAttr());
  p.printOptionalAttrDict((*this)->getAttrs(), /*elidedAttrs=*/{"value"});
}

ParseResult ConstantOp::parse(OpAsmParser &parser, OperationState &result) {
  IntegerAttr valueAttr;

  if (parser.parseAttribute(valueAttr, "value", result.attributes) ||
      parser.parseOptionalAttrDict(result.attributes))
    return failure();

  result.addTypes(valueAttr.getType());
  return success();
}
