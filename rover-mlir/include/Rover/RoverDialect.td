//===----------------------------------------------------------------------===//
//
// This file defines the Rover passes.
//
//===----------------------------------------------------------------------===//

#ifndef ROVER_DIALECT
#define ROVER_DIALECT

include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// Rover Passes
//===----------------------------------------------------------------------===//

def RoverInsertGraphPass : Pass<"rover-insert-graph", "::mlir::ModuleOp"> {
  let summary = "Wrap each hw.module body in an equivalence.graph operation.";
  let description = [{
    This pass walks every `hw.module` in the module and replaces its body with
    an `equivalence.graph` operation. It mirrors `equivalence-insert-graph`,
    reusing the same `insertGraphInRegion` utility, but operates on `hw.module`
    rather than `func.func`.
  }];
  let dependentDialects = [
    "::mlir::equivalence::EquivalenceDialect",
    "::circt::hw::HWDialect",
    "::circt::comb::CombDialect"
  ];
}

def RoverSaturatePass : Pass<"rover-saturate", "::mlir::ModuleOp"> {
  let summary = "Saturate a Rover e-graph on a function.";
  let description = [{
    This pass runs the first half of Rover optimization pipeline on a function:

    If a "patterns" module exists in the parent module, it
    will be used for equality saturation.
  }];
  let dependentDialects = [
    "::mlir::func::FuncDialect",
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::ematch::EmatchDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
    "::circt::datapath::DatapathDialect",
    "::circt::hw::HWDialect",
    "::circt::comb::CombDialect"
  ];
  let options = [
    Option<"maxIters", "max-iters", "int", "3",
           "Maximum number of iterations before equality saturation times out.">,
    Option<"maxNodes", "max-nodes", "int", "0",
           "Maximum number of nodes in the e-graph (0 = unlimited).">,
    Option<"patternsFile", "patterns-file", "std::string", /*default=*/"\"\"",
           "Path to an MLIR file containing the patterns module. "
           "When set, the input module is treated as the IR module directly.">
  ];
}

def RoverExtractPass : Pass<"rover-extract", "::mlir::ModuleOp"> {
  let summary = "Extract from a Rover e-graph.";
  let description = [{
    This pass runs the second half of Rover optimization pipeline on a function:

    If a "patterns" module exists in the parent module, it
    will be used for equality saturation.
  }];
  let dependentDialects = [
    "::mlir::func::FuncDialect",
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
    "::circt::datapath::DatapathDialect",
    "::circt::hw::HWDialect",
    "::circt::comb::CombDialect"
  ];
    let options = [
    Option<"extractDelay", "delay", "bool", "false",
           "Extract based on delay else use area.">,
    Option<"debugExtract", "debug", "bool", "false",
           "Enable debug output for extraction.">,
  ];
}

#endif // ROVER_DIALECT
