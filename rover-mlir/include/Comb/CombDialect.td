//===----------------------------------------------------------------------===//
//
// This file defines the Comb dialect, operations, and attributes.
//
//===----------------------------------------------------------------------===//

#ifndef COMB_DIALECT
#define COMB_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

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
  let arguments = (ins Variadic<AnyInteger>:$inputs, UnitAttr:$twoState);
  let results = (outs AnyInteger:$result);
}

class UTVariadicOp<string mnemonic, list<Trait> traits = []> :
      VariadicOp<mnemonic, 
                  traits # [SameTypeOperands, SameOperandsAndResultType]> {

  // let hasCanonicalizeMethod = true;
  // let hasFolder = true;
  // let hasVerifier = 1;

  // let assemblyFormat = "$inputs attr-dict `:` qualified(type($result))";
  let assemblyFormat = "(`bin` $twoState^)? $inputs attr-dict `:` qualified(type($result))";

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
def ShruOp : UTBinOp<"shru",[Pure]>;
def SubOp : UTBinOp<"sub",[Pure]>;
def AndOp : UTVariadicOp<"and", [Commutative]>;
def OrOp  : UTVariadicOp<"or",  [Commutative]>;
def XorOp : UTVariadicOp<"xor", [Commutative]>;

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

// Select one of two values based on a condition.
def MuxOp : CombOp<"mux", 
  [Pure,   AllTypesMatch<["trueValue", "falseValue", "result"]>]> {
  let summary = "Return one or the other operand depending on a selector bit";
  let description = [{
    ```
      %0 = mux %pred, %tvalue, %fvalue : i4
    ```
  }];

  let arguments = (ins I1:$cond, AnyType:$trueValue,
                       AnyType:$falseValue, UnitAttr:$twoState);
  let results = (outs AnyType:$result);

  let assemblyFormat =
    "(`bin` $twoState^)? $cond `,` $trueValue `,` $falseValue  attr-dict `:` qualified(type($result))";
}

// Extract a range of bits from the specified input.
def ExtractOp : CombOp<"extract", 
  [Pure]> {
  let summary = "Extract a range of bits into a smaller value, lowBit "
                "specifies the lowest bit included.";

  let arguments = (ins AnyInteger:$input, I32Attr:$lowBit);
  let results = (outs AnyInteger:$result);

  let assemblyFormat =
    "$input `from` $lowBit attr-dict `:` functional-type($input, $result)";

  // let hasFolder = true;
  // let hasVerifier = 1;
  // let hasCanonicalizeMethod = true;

  // let builders = [
  //   OpBuilder<(ins "Value":$lhs, "int32_t":$lowBit, "int32_t":$bitWidth), [{
  //     auto resultType = $_builder.getIntegerType(bitWidth);
  //     return build($_builder, $_state, resultType, lhs, lowBit);
  //   }]>
  // ];
}


#endif // COMB_MLIR_DIALECT
