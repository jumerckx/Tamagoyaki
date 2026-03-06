//===- HerbieMLIRDialect.td - HerbieMLIR dialect --------*- tablegen -*-===//
//
// This file defines the HerbieMLIR dialect, operations, attributes, and passes.
//
//===----------------------------------------------------------------------===//

#ifndef HERBIE_MLIR_DIALECT
#define HERBIE_MLIR_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// HerbieMLIR dialect definition.
//===----------------------------------------------------------------------===//

def HerbieMLIR_Dialect : Dialect {
    let name = "herbie";
    let summary = "The Herbie-MLIR dialect.";
    let description = [{
        This dialect provides operations and attributes for the Herbie
        floating-point optimization pipeline.
    }];
    let cppNamespace = "::herbie";

    let useDefaultAttributePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Base HerbieMLIR operation definition.
//===----------------------------------------------------------------------===//

class HerbieMLIR_Op<string mnemonic, list<Trait> traits = []> :
        Op<HerbieMLIR_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// HerbieMLIR Enum Attributes
//===----------------------------------------------------------------------===//

def HerbieMLIR_Constant_E            : I32EnumAttrCase<"Const_E",            0, "E">;
def HerbieMLIR_Constant_PI           : I32EnumAttrCase<"Const_PI",           1, "PI">;
def HerbieMLIR_Constant_M_2_SQRTPI   : I32EnumAttrCase<"Const_M_2_SQRTPI",  2, "M_2_SQRTPI">;
def HerbieMLIR_Constant_LOG2E        : I32EnumAttrCase<"Const_LOG2E",        3, "LOG2E">;
def HerbieMLIR_Constant_PI_2         : I32EnumAttrCase<"Const_PI_2",         4, "PI_2">;
def HerbieMLIR_Constant_SQRT2        : I32EnumAttrCase<"Const_SQRT2",        5, "SQRT2">;
def HerbieMLIR_Constant_LOG10E       : I32EnumAttrCase<"Const_LOG10E",       6, "LOG10E">;
def HerbieMLIR_Constant_PI_4         : I32EnumAttrCase<"Const_PI_4",         7, "PI_4">;
def HerbieMLIR_Constant_SQRT1_2      : I32EnumAttrCase<"Const_SQRT1_2",      8, "SQRT1_2">;
def HerbieMLIR_Constant_LN2          : I32EnumAttrCase<"Const_LN2",          9, "LN2">;
def HerbieMLIR_Constant_M_1_PI       : I32EnumAttrCase<"Const_M_1_PI",      10, "M_1_PI">;
def HerbieMLIR_Constant_INFINITY     : I32EnumAttrCase<"Const_INFINITY",     11, "INFINITY">;
def HerbieMLIR_Constant_LN10         : I32EnumAttrCase<"Const_LN10",        12, "LN10">;
def HerbieMLIR_Constant_M_2_PI       : I32EnumAttrCase<"Const_M_2_PI",      13, "M_2_PI">;

def HerbieMLIR_ConstantEnum : I32EnumAttr<"Constant",
    "Mathematical constant symbols", [
    HerbieMLIR_Constant_E,
    HerbieMLIR_Constant_PI,
    HerbieMLIR_Constant_M_2_SQRTPI,
    HerbieMLIR_Constant_LOG2E,
    HerbieMLIR_Constant_PI_2,
    HerbieMLIR_Constant_SQRT2,
    HerbieMLIR_Constant_LOG10E,
    HerbieMLIR_Constant_PI_4,
    HerbieMLIR_Constant_SQRT1_2,
    HerbieMLIR_Constant_LN2,
    HerbieMLIR_Constant_M_1_PI,
    HerbieMLIR_Constant_INFINITY,
    HerbieMLIR_Constant_LN10,
    HerbieMLIR_Constant_M_2_PI
]> {
    let genSpecializedAttr = 0;
    let cppNamespace = "::herbie";
}

def HerbieMLIR_ConstantAttr : EnumAttr<HerbieMLIR_Dialect, HerbieMLIR_ConstantEnum, "constant">;

//===----------------------------------------------------------------------===//
// HerbieMLIR Operations
//===----------------------------------------------------------------------===//

def HerbieMLIR_ConstantOp : HerbieMLIR_Op<"constant", [Pure]> {
    let summary = "A mathematical constant value";
    let description = [{
        The `herbie.constant` operation produces the value of a well-known
        mathematical constant (e.g. π, 𝑒, √2, and others).

        Example:

        ```mlir
        %0 = herbie.constant E : f64
        %1 = herbie.constant PI : f32
        ```
    }];

    let arguments = (ins HerbieMLIR_ConstantAttr:$symbol);
    let results = (outs AnyType:$value);

    let assemblyFormat = [{
        $symbol attr-dict `:` type($value)
    }];
}

def HerbieMLIR_SoundDivOp : HerbieMLIR_Op<"sound_div", [Pure, SameOperandsAndResultType]> {
    let summary = "Division with a fallback for undefined inputs";
    let description = [{
        The `herbie.sound_div` operation performs division, returning
        `fallback` when the operation is not defined (e.g. division by zero).

        Example:

        ```mlir
        %0 = herbie.sound_div %a, %b, %fb : f64
        ```
    }];

    let arguments = (ins AnyType:$lhs, AnyType:$rhs, AnyType:$fallback);
    let results = (outs AnyType:$result);

    let assemblyFormat = [{
        $lhs `,` $rhs `,` $fallback attr-dict `:` type($result)
    }];
}

def HerbieMLIR_SoundPowOp : HerbieMLIR_Op<"sound_pow", [Pure, SameOperandsAndResultType]> {
    let summary = "Power with a fallback for undefined inputs";
    let description = [{
        The `herbie.sound_pow` operation computes exponentiation, returning
        `fallback` when the operation is not defined on the inputs.

        Example:

        ```mlir
        %0 = herbie.sound_pow %base, %exp, %fb : f64
        ```
    }];

    let arguments = (ins AnyType:$lhs, AnyType:$rhs, AnyType:$fallback);
    let results = (outs AnyType:$result);

    let assemblyFormat = [{
        $lhs `,` $rhs `,` $fallback attr-dict `:` type($result)
    }];
}

def HerbieMLIR_SoundLogOp : HerbieMLIR_Op<"sound_log", [Pure, SameOperandsAndResultType]> {
    let summary = "Logarithm with a fallback for undefined inputs";
    let description = [{
        The `herbie.sound_log` operation computes the natural logarithm,
        returning `fallback` when the operation is not defined on the input
        (e.g. non-positive values).

        Example:

        ```mlir
        %0 = herbie.sound_log %a, %fb : f64
        ```
    }];

    let arguments = (ins AnyType:$value, AnyType:$fallback);
    let results = (outs AnyType:$result);

    let assemblyFormat = [{
        $value `,` $fallback attr-dict `:` type($result)
    }];
}

//===----------------------------------------------------------------------===//
// HerbieMLIR Passes
//===----------------------------------------------------------------------===//

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
    "::mlir::ematch::EmatchDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
    "herbie::HerbieMLIRDialect",
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
           "Maximum number of equality saturation iterations">,
    Option<"patternsFile", "patterns-file", "std::string", /*default=*/"\"\"",
           "Path to an MLIR file containing the patterns module. "
           "When set, the input module is treated as the IR module directly.">
  ];
}

def LowerHerbieSoundOpsPass : Pass<"lower-herbie-sound-ops", "::mlir::ModuleOp"> {
  let summary = "Lower herbie.sound_* operations to arith/math counterparts.";
  let description = [{
    Replaces `herbie.sound_div`, `herbie.sound_pow`, and `herbie.sound_log`
    operations with their standard arith/math equivalents (`arith.divf`,
    `math.powf`, `math.log`), dropping the fallback argument.
  }];
  let dependentDialects = ["::mlir::arith::ArithDialect", "::mlir::math::MathDialect"];
}

def LowerHerbieConstantPass : Pass<"lower-herbie-constant", "::mlir::ModuleOp"> {
  let summary = "Lower herbie.constant operations to arith.constant.";
  let description = [{
    Replaces `herbie.constant` operations with `arith.constant` operations
    containing the actual floating-point value of the mathematical constant.
  }];
  let dependentDialects = ["::mlir::arith::ArithDialect"];
}

//===----------------------------------------------------------------------===//
// HerbieMLIR Interfaces
//===----------------------------------------------------------------------===//

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

#endif // HERBIE_MLIR_DIALECT
