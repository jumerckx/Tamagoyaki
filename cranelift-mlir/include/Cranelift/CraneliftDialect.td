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

def CraneliftOptimizePass : InterfacePass<"cranelift-optimize", "::mlir::FunctionOpInterface"> {
  let summary = "A dummy pass for the cranelift-mlir subproject.";
  let description = [{
    Placeholder pass that does nothing. Used to verify the cranelift-mlir
    build infrastructure is wired up correctly.
  }];
  let dependentDialects = [
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::ematch::EmatchDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
  ];
  let options = [
    Option<"patternsFile", "patterns-file", "std::string", /*default=*/"\"\"",
           "Path to an MLIR file containing the PDL patterns module.">,
    Option<"maxIters", "max-iters", "int", "4",
           "Maximum number of equality saturation iterations.">,
    Option<"maxNodes", "max-nodes", "int", "0",
           "Maximum number of nodes in the e-graph (0 = unlimited).">,
    Option<"eagerRewrite", "eager-rewrite", "bool", "true",
           "When true, matching and rewriting are interleaved (eager).">
  ];
}

#endif // CRANELIFT_DIALECT
