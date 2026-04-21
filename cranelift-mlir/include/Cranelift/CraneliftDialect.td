//===----------------------------------------------------------------------===//
//
// This file defines the Cranelift passes.
//
//===----------------------------------------------------------------------===//

#ifndef CRANELIFT_DIALECT
#define CRANELIFT_DIALECT

include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// Cranelift Passes
//===----------------------------------------------------------------------===//

def CraneliftDummyPass : InterfacePass<"cranelift-dummy", "::mlir::FunctionOpInterface"> {
  let summary = "A dummy pass for the cranelift-mlir subproject.";
  let description = [{
    Placeholder pass that does nothing. Used to verify the cranelift-mlir
    build infrastructure is wired up correctly.
  }];
}

#endif // CRANELIFT_DIALECT
