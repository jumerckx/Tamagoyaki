//===- HerbieMLIRPasses.td - HerbieMLIR passes definition -------*- tablegen -*-===//
//
// This file defines passes for the herbie-mlir project.
//
//===----------------------------------------------------------------------===//

#ifndef HERBIE_MLIR_PASSES
#define HERBIE_MLIR_PASSES

include "mlir/Pass/PassBase.td"

def HerbieMLIRTemplatePass : Pass<"herbie-mlir-template", "::mlir::ModuleOp"> {
  let summary = "Template pass for HerbieMLIR.";
  let description = [{
    A template pass demonstrating the herbie-mlir pass infrastructure.
  }];
  let dependentDialects = ["::mlir::func::FuncDialect"];
}

def IntervalAnalysisPass : Pass<"herbie-interval-analysis", "::mlir::ModuleOp"> {
  let summary = "Run interval analysis using Rival.";
  let description = [{
    Performs sparse forward dataflow interval analysis on the module using
    the Rival interval arithmetic library. Prints computed intervals for
    each SSA value.
  }];
  let dependentDialects = [
    "::mlir::func::FuncDialect",
    "::mlir::arith::ArithDialect"
  ];
}

#endif // HERBIE_MLIR_PASSES
