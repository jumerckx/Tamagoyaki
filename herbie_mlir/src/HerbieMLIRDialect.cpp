#include "HerbieMLIR.h"

#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace herbie;

#include "HerbieMLIRDialect.cpp.inc"

#include "HerbieMLIREnums.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "HerbieMLIRAttrs.cpp.inc"

#define GET_OP_CLASSES
#include "HerbieMLIROps.cpp.inc"

void herbie::HerbieMLIRDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "HerbieMLIROps.cpp.inc"
      >();
  addAttributes<
#define GET_ATTRDEF_LIST
#include "HerbieMLIRAttrs.cpp.inc"
      >();
}
