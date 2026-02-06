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


def RivalEvaluatePass : Pass<"rival-evaluate", "::mlir::ModuleOp"> {
  let summary = "Compile and evaluate functions using Rival interval arithmetic.";
  let description = [{
    Compiles functions to Rival expressions using RivalCompileableInterface
    and evaluates them with test inputs.
  }];
  let dependentDialects = ["::mlir::func::FuncDialect", "::mlir::arith::ArithDialect"];
}

def IntervalSearchPass : Pass<"interval-search", "::mlir::func::FuncOp"> {
  let summary = "Find valid sampling regions via interval subdivision.";
  let description = [{
    Uses Rival's interval analysis to find regions of the input space where
    floating-point expressions can be safely evaluated. The algorithm
    subdivides the input space, classifying regions as:
    - Valid (safe to sample)
    - Invalid (will always produce errors like division by zero)
    - Uncertain (needs further subdivision or is at the subdivision limit)

    The pass emits statistics about the fraction of the input space that is
    sampleable, which is useful for understanding expression domains.
  }];
  let dependentDialects = ["::mlir::func::FuncDialect", "::mlir::arith::ArithDialect"];
  let options = [
    Option<"maxSearchDepth", "max-depth", "unsigned", "128",
           "Maximum subdivision iterations (fuel)">,
    Option<"maxRegions", "max-regions", "unsigned", "131072",
           "Stop if region count exceeds this (default 2^17)">,
    Option<"analysisPrecision", "analysis-precision", "unsigned", "128",
           "MPFR precision for interval bounds">,
    Option<"maxRivalPrecision", "max-rival-precision", "unsigned", "2000",
           "Max precision for Rival analysis">,
    Option<"maxRivalIterations", "max-rival-iterations", "unsigned", "5",
           "Max Rival iterations per analysis">,
    Option<"emitStatistics", "emit-statistics", "bool", "true",
           "Whether to emit statistics as operation attributes">
  ];
}

def HerbiePrintTopoSort : Pass<"herbie-print-toposort", "::mlir::ModuleOp"> {
  let summary = "Prints topological ordering of selected operations in equivalence.graph.";
  let description = [{
    Computes a topological sort of operations in each equivalence.graph op,
    considering only the operations that correspond to the min_cost_index
    of equivalence.class operations. Operations used by a class but not
    selected by min_cost_index are treated as "ready" (ignored in ordering).
    Prints the resulting order to stderr without modifying the IR.
  }];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

def HerbieOptimizePass : Pass<"herbie-optimize", "::mlir::ModuleOp"> {
  let summary = "Run Herbie optimization pipeline on a function.";
  let description = [{
    This pass runs the full Herbie optimization pipeline on a function:
    1. Interval search to find valid sampling regions
    2. Insert equivalence.graph around the function body
    3. Run equality saturation with rewrite patterns
    4. Compute topological sort of selected operations

    The pass requires the function to implement RivalCompileableInterface for
    interval search. If a "patterns" module exists in the parent module, it
    will be used for equality saturation.
  }];
  let dependentDialects = [
    "::mlir::func::FuncDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::pdl_interp::PDLInterpDialect"
  ];
  let options = [
    // Interval search options
    Option<"maxSearchDepth", "max-depth", "unsigned", "128",
           "Maximum subdivision iterations for interval search">,
    Option<"maxRegions", "max-regions", "unsigned", "131072",
           "Stop interval search if region count exceeds this">,
    Option<"analysisPrecision", "analysis-precision", "unsigned", "128",
           "MPFR precision for interval bounds">,
    Option<"maxRivalPrecision", "max-rival-precision", "unsigned", "2000",
           "Max precision for Rival analysis">,
    Option<"maxRivalIterations", "max-rival-iterations", "unsigned", "5",
           "Max Rival iterations per interval analysis">,
    // Saturation options
    Option<"maxSaturationIters", "max-saturation-iters", "int", "4",
           "Maximum number of equality saturation iterations">
  ];
}


def RivalCompileableInterface : OpInterface<"RivalCompileableInterface"> {
  let description = [{
    Interface for operations to be compiled to Rival expressions.
  }];
  
  let cppNamespace = "::herbie";

  let methods = [
    InterfaceMethod<
      "Compile the operation to a Rival expression.",
      "llvm::ArrayRef<uint32_t>", "compile",
      (ins "::RivalExprArena *":$arena, "::llvm::ArrayRef<uint32_t>":$operands)
    >
  ];
}

#endif // HERBIE_MLIR_PASSES
