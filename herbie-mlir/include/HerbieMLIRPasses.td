//===- HerbieMLIRPasses.td - HerbieMLIR passes definition -------*- tablegen -*-===//
//
// This file defines passes for the herbie-mlir project.
//
//===----------------------------------------------------------------------===//

#ifndef HERBIE_MLIR_PASSES
#define HERBIE_MLIR_PASSES

include "mlir/Pass/PassBase.td"
include "mlir/IR/OpBase.td"

def HerbieMLIRTemplatePass : Pass<"herbie-mlir-template", "::mlir::ModuleOp"> {
  let summary = "Template pass for HerbieMLIR.";
  let description = [{
    A template pass demonstrating the herbie-mlir pass infrastructure.
  }];
  let dependentDialects = ["::mlir::func::FuncDialect"];
}


def TransferOpInterface : OpInterface<"TransferOpInterface"> {
  let description = [{
    Interface for operations to define their own transfer functions for 
    my custom dataflow analysis.
  }];
  
  let cppNamespace = "::my_project";

  let methods = [
    InterfaceMethod<
      "Apply the transfer function to the given solver state.",
      "void", "visit",
      (ins "::mlir::dataflow::LatticeAnchor":$anchor, 
           "::mlir::dataflow::DataFlowSolver &":$solver),
      /*methodBody=*/[{}],
      /*defaultImplementation=*/[{
        return; // Default is to do nothing or mark conservative
      }]
    >
  ];
}

#endif // HERBIE_MLIR_PASSES
