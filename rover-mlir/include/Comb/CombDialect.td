//===----------------------------------------------------------------------===//
//
// This file defines the Comb dialect, operations, attributes, and passes.
//
//===----------------------------------------------------------------------===//

#ifndef COMB_DIALECT
#define COMB_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Pass/PassBase.td"

//===----------------------------------------------------------------------===//
// Comb dialect definition.
//===----------------------------------------------------------------------===//

def CombDialect : Dialect {
    let name = "comb";
    let summary = "The Comb dialect.";
    let description = [{
        This dialect provides operations and attributes for the Comb
        circuit optimization pipeline.
    }];
    let cppNamespace = "::comb";

    // let useDefaultAttributePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Base Comb operation definition.
//===----------------------------------------------------------------------===//

// Base class for the operation in this dialect.
class CombOp<string mnemonic, list<Trait> traits = []> :
    Op<CombDialect, mnemonic, traits>;

// Base class for variadic operators.
class VariadicOp<string mnemonic, list<Trait> traits = []> :
      CombOp<mnemonic, traits # [Pure]> {
  let arguments = (ins Variadic<AnyInteger>:$inputs);
  let results = (outs AnyInteger:$result);
}

class UTVariadicOp<string mnemonic, list<Trait> traits = []> :
      VariadicOp<mnemonic, 
                  traits # [SameTypeOperands, SameOperandsAndResultType]> {

  // let hasCanonicalizeMethod = true;
  // let hasFolder = true;
  // let hasVerifier = 1;

  let assemblyFormat = "$inputs attr-dict `:` qualified(type($result))";

  // let builders = [
  //   OpBuilder<(ins "Value":$lhs, "Value":$rhs, CArg<"bool", "false">:$twoState), [{
  //     return build($_builder, $_state, lhs.getType(),
  //                  ValueRange{lhs, rhs}, twoState);
  //   }]>
  // ];
}

// Base class for binary operators.
class BinOp<string mnemonic, list<Trait> traits = []> :
      CombOp<mnemonic, traits # [Pure]> {
  let arguments = (ins AnyInteger:$lhs, AnyInteger:$rhs);
  let results = (outs AnyInteger:$result);

  let assemblyFormat =
    "$lhs `,` $rhs attr-dict `:` functional-type($args, $results)";
}

// Binary operator with uniform input/result types.
class UTBinOp<string mnemonic, list<Trait> traits = []> :
      BinOp<mnemonic,
               traits # [SameTypeOperands, SameOperandsAndResultType]> {
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` qualified(type($result))";
}


//===----------------------------------------------------------------------===//
// Comb Operations
//===----------------------------------------------------------------------===//

// Arithmetic and Logical Operations.
def AddOp : UTVariadicOp<"add", [Commutative, Pure]>;
def MulOp : UTVariadicOp<"mul", [Commutative, Pure]>;
def ShlOp : UTBinOp<"shl",[Pure]>;
def SubOp : UTBinOp<"sub",[Pure]>;

def ConcatOp : CombOp<"concat", 
  [InferTypeOpInterface, Pure]> {
  let summary = "Concatenate a variadic list of operands together.";
  let description = [{
    See the comb rationale document for details on operand ordering.
  }];

  let arguments = (ins Variadic<AnyInteger>:$inputs);
  let results = (outs AnyInteger:$result);

  // let hasFolder = true;
  // let hasCanonicalizeMethod = true;

  let hasCustomAssemblyFormat = 1;

  // let builders = [
  //   OpBuilder<(ins "Value":$lhs, "Value":$rhs), [{
  //     return build($_builder, $_state, ValueRange{lhs, rhs});
  //   }]>,
  //   OpBuilder<(ins "Value":$hd, "ValueRange":$tl)>,
  // ];

  let extraClassDeclaration = [{
    /// Infer the return types of this operation.
    static llvm::LogicalResult inferReturnTypes(mlir::MLIRContext *context,
                                          std::optional<mlir::Location> loc,
                                          mlir::ValueRange operands,
                                          mlir::DictionaryAttr attrs,
                                          mlir::OpaqueProperties properties,
                                          mlir::RegionRange regions,
                                          mlir::SmallVectorImpl<mlir::Type> &results);
  }];
}

//===----------------------------------------------------------------------===//
// Comb Passes
//===----------------------------------------------------------------------===//

def RoverSaturatePass : Pass<"rover-saturate", "::mlir::ModuleOp"> {
  let summary = "Saturate a Rover e-graph on a function.";
  let description = [{
    This pass runs the first half of Rover optimization pipeline on a function:

    If a "patterns" module exists in the parent module, it
    will be used for equality saturation.
  }];
  let dependentDialects = [
    "::mlir::func::FuncDialect",
    "::mlir::arith::ArithDialect",
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
    // "::hw::HWDialect",
    "::comb::CombDialect"
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
    "::mlir::arith::ArithDialect",
    "::mlir::equivalence::EquivalenceDialect",
    "::mlir::pdl_interp::PDLInterpDialect",
    // "::hw::HWDialect",
    "::comb::CombDialect"
  ];
}

#endif // COMB_MLIR_DIALECT
