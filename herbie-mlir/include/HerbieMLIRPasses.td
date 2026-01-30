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


def RivalCompileableInterface : OpInterface<"RivalCompileableInterface"> {
  let description = [{
    Interface for operations to be compiled to Rival expressions.
  }];
  
  let cppNamespace = "::herbie";

  let methods = [
    InterfaceMethod<
      "Compile the operation to a Rival expression.",
      "uint32_t", "compile",
      (ins "::RivalExprArena *":$arena, "::llvm::ArrayRef<uint32_t>":$operands)
    >
  ];
}

#endif // HERBIE_MLIR_PASSES
