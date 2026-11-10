//===- MatchOps.td - Match ops -----------------------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_MATCH_IR_MATCHOPS
#define MLIR_DIALECT_MATCH_IR_MATCHOPS

include "mlir/Dialect/Match/IR/MatchTypes.td"
include "mlir/Dialect/PDL/IR/PDLTypes.td"
include "mlir/IR/OpAsmInterface.td"
include "mlir/IR/SymbolInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class Match_Op<string mnemonic, list<Trait> traits = []>
    : Op<Match_Dialect, mnemonic, traits>;

def Match_Question : NativeOpTrait<"Question"> {
  let cppNamespace = "::mlir::match";
}

def Match_MatcherOp : Match_Op<"matcher", [
    IsolatedFromAbove, SingleBlock, NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>,
    SymbolName, SymbolVisibility, Symbol
  ]> {
  let summary = "Container for the navigation/constraint IR of one matcher";

  let arguments = (ins OptionalAttr<SymbolNameAttr>:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility);
  let regions = (region SizedRegion<1>:$bodyRegion);

  let assemblyFormat = [{
    ($sym_visibility^)? ($sym_name^)? `root` `` custom<MatcherRegion>($bodyRegion)
    attr-dict-with-keyword
  }];

  let builders = [
    OpBuilder<(ins CArg<"::mlir::StringAttr", "nullptr">:$sym_name), [{
      build($_builder, $_state, sym_name, /*sym_visibility=*/nullptr);
    }]>
  ];

  let extraClassDeclaration = [{
    bool isOptionalSymbol() { return true; }
  }];
  let hasRegionVerifier = 1;
}

def Match_TryOp : Match_Op<"try", [
    SingleBlock, NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>
  ]> {
  let summary = "Open a new failure scope";

  let regions = (region SizedRegion<1>:$body);

  let assemblyFormat = "$body attr-dict";
  let hasRegionVerifier = 1;
}

def Match_SwitchOpNameOp : Match_Op<"switch_op_name", [
    NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>
  ]> {
  let summary = "Multi-way dispatch on operation name";

  let arguments = (ins PDL_Operation:$op, StrArrayAttr:$caseNames);
  let regions = (region VariadicRegion<SizedRegion<1>>:$caseRegions);

  let hasCustomAssemblyFormat = 1;
  let hasVerifier = 1;
}

def Match_SwitchTypeOp : Match_Op<"switch_type", [
    NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>
  ]> {
  let summary = "Multi-way dispatch on a type value";

  let arguments = (ins PDL_Type:$typeValue, TypeArrayAttr:$caseTypes);
  let regions = (region VariadicRegion<SizedRegion<1>>:$caseRegions);

  let hasCustomAssemblyFormat = 1;
  let hasVerifier = 1;
}

def Match_ConstantAttributeOp : Match_Op<"constant_attribute", [Pure]> {
  let summary = "Materialize a constant attribute as a value";

  let arguments = (ins AnyAttr:$value);
  let results = (outs PDL_Attribute:$result);
  let assemblyFormat = "$value attr-dict";

  let builders = [
    OpBuilder<(ins "Attribute":$value), [{
      build($_builder, $_state, $_builder.getType<pdl::AttributeType>(), value);
    }]>
  ];
}

def Match_ConstantTypeOp : Match_Op<"constant_type", [Pure]> {
  let summary = "Materialize a constant type as a value";

  let arguments = (ins TypeAttr:$value);
  let results = (outs PDL_Type:$result);
  let assemblyFormat = "$value attr-dict";

  let builders = [
    OpBuilder<(ins "TypeAttr":$value), [{
      build($_builder, $_state, $_builder.getType<pdl::TypeType>(), value);
    }]>
  ];
}

def Match_ConstantTypesOp : Match_Op<"constant_types", [Pure]> {
  let summary = "Materialize a constant range of types as a value";

  let arguments = (ins TypeArrayAttr:$value);
  let results = (outs PDL_RangeOf<PDL_Type>:$result);
  let assemblyFormat = "$value attr-dict";

  let builders = [
    OpBuilder<(ins "ArrayAttr":$value), [{
      build($_builder, $_state,
            pdl::RangeType::get($_builder.getType<pdl::TypeType>()), value);
    }]>
  ];
}

def Match_GetOperandOp : Match_Op<"get_operand", [Pure]> {
  let summary = "Get an operand of an operation (nullable)";
  let arguments = (ins PDL_Operation:$op, I32Attr:$index);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat = "$index `of` $op attr-dict `:` qualified(type($result))";
}

def Match_GetOperandsOp : Match_Op<"get_operands", [Pure]> {
  let summary = "Get a group of operands of an operation (nullable)";
  let arguments = (ins PDL_Operation:$op, OptionalAttr<I32Attr>:$index);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat =
      "($index^)? `of` $op attr-dict `:` qualified(type($result))";
}

def Match_GetResultOp : Match_Op<"get_result", [Pure]> {
  let summary = "Get a result of an operation (nullable)";
  let arguments = (ins PDL_Operation:$op, I32Attr:$index);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat = "$index `of` $op attr-dict `:` qualified(type($result))";
}

def Match_GetResultsOp : Match_Op<"get_results", [Pure]> {
  let summary = "Get a group of results of an operation (nullable)";
  let arguments = (ins PDL_Operation:$op, OptionalAttr<I32Attr>:$index);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat =
      "($index^)? `of` $op attr-dict `:` qualified(type($result))";
}

def Match_GetAttributeOp : Match_Op<"get_attribute", [Pure]> {
  let summary = "Get a named attribute of an operation (nullable)";
  let arguments = (ins PDL_Operation:$op, StrAttr:$name);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat = "$name `of` $op attr-dict `:` qualified(type($result))";
}

def Match_GetDefiningOpOp : Match_Op<"get_defining_op", [Pure]> {
  let summary = "Get the defining operation of a value or value range (nullable)";
  let arguments = (ins PDL_InstOrRangeOf<PDL_Value>:$value);
  let results = (outs Match_OptionalType:$result);
  let assemblyFormat =
      "`of` $value `:` type($value) attr-dict `->` qualified(type($result))";
}

def Match_GetValueTypeOp : Match_Op<"get_value_type", [Pure,
    TypesMatchWith<"`value` type matches arity of `result`",
                   "result", "value", "getGetValueTypeOpValueType($_self)">]> {
  let summary = "Get the type of a value or value range (non-nullable)";
  let arguments = (ins PDL_InstOrRangeOf<PDL_Value>:$value);
  let results = (outs PDL_InstOrRangeOf<PDL_Type>:$result);
  let assemblyFormat = "`of` $value `:` type($result) attr-dict";
}

def Match_GetAttributeTypeOp : Match_Op<"get_attribute_type", [Pure]> {
  let summary = "Get the type of an attribute (non-nullable)";
  let arguments = (ins PDL_Attribute:$attribute);
  let results = (outs PDL_Type:$result);
  let assemblyFormat = "`of` $attribute attr-dict";
}

def Match_GetUsersOp : Match_Op<"get_users", [Pure]> {
  let summary = "Get all users of a value (non-nullable)";
  let arguments = (ins PDL_Value:$value);
  let results = (outs PDL_RangeOf<PDL_Operation>:$result);
  let assemblyFormat = "`of` $value attr-dict";
}

def Match_ExtractOp
    : Match_Op<"extract", [Pure,
     TypesMatchWith<
        "`range` is a PDL range whose element type matches type of `result`",
        "result", "range", "pdl::RangeType::get($_self)">]> {
  let summary = "Extract the item at the specified index in a range";

  let arguments = (ins PDL_RangeOf<PDL_AnyType>:$range,
                       ConfinedAttr<I32Attr, [IntNonNegative]>:$index);
  let results = (outs PDL_AnyType:$result);
  let assemblyFormat = "$index `of` $range `:` type($result) attr-dict";

  let builders = [
    OpBuilder<(ins "Value":$range, "unsigned":$index), [{
      build($_builder, $_state,
            ::llvm::cast<pdl::RangeType>(range.getType()).getElementType(),
            range, index);
    }]>,
  ];
}

def Match_ForEachOp : Match_Op<"foreach", [
    SingleBlock, NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>
  ]> {
  let summary = "Existentially quantify a failure scope over a range";

  let arguments = (ins PDL_RangeOf<PDL_AnyType>:$range);
  let regions = (region SizedRegion<1>:$body);

  let hasCustomAssemblyFormat = 1;
  let hasRegionVerifier = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    OpBuilder<(ins "Value":$range)>,
  ];

  let extraClassDeclaration = [{
    ::mlir::BlockArgument getLoopVariable() {
      return getBody().front().getArgument(0);
    }

    ::mlir::Type getElementType() {
      return ::llvm::cast<::mlir::pdl::RangeType>(getRange().getType())
          .getElementType();
    }
  }];
}

def Match_IsNotNullOp : Match_Op<"is_not_null", [
    TypesMatchWith<"`optionalValue` is the optional of `unwrapped`",
                   "unwrapped", "optionalValue",
                   "::mlir::match::OptionalType::get($_self)">]> {
  let summary = "Unwrap an optional value, failing if it is null";
  let arguments = (ins Match_OptionalType:$optionalValue);
  let results = (outs PDL_AnyType:$unwrapped);
  let assemblyFormat = "$optionalValue `:` type($unwrapped) attr-dict";
}

def Match_HasNameOp : Match_Op<"has_name", [Match_Question]> {
  let summary = "Test the operation name";
  let arguments = (ins PDL_Operation:$op, StrAttr:$name);
  let assemblyFormat = "$op `,` $name attr-dict";
}

def Match_EqualOp : Match_Op<"equal", [SameTypeOperands]> {
  let summary = "Test equality of two values";
  let arguments = (ins PDL_AnyType:$lhs, PDL_AnyType:$rhs);
  let assemblyFormat = "$lhs `,` $rhs `:` type($lhs) attr-dict";
}

def Match_HasTypeOp : Match_Op<"has_type", [Match_Question]> {
  let summary = "Test that a type matches a constant type";
  let arguments = (ins PDL_Type:$typeValue, TypeAttr:$constantType);
  let assemblyFormat = "$typeValue `,` $constantType attr-dict";
}

def Match_HasTypesOp : Match_Op<"has_types", [Match_Question]> {
  let summary = "Test that a range of types matches a constant array of types";
  let arguments = (ins PDL_RangeOf<PDL_Type>:$types,
                       TypeArrayAttr:$constantTypes);
  let assemblyFormat = "$types `,` $constantTypes attr-dict";
}

def Match_HasAttrValueOp : Match_Op<"has_attr_value", [Match_Question]> {
  let summary = "Test that an attribute matches a constant value";
  let arguments = (ins PDL_Attribute:$attribute, AnyAttr:$value);
  let assemblyFormat = "$attribute `is` $value attr-dict";
}

def Match_CheckOperandCountOp : Match_Op<"check_operand_count", [Match_Question]> {
  let summary = "Test the operand count of an operation";
  let arguments = (ins PDL_Operation:$op,
                       ConfinedAttr<I32Attr, [IntNonNegative]>:$count,
                       UnitAttr:$atLeast);
  let assemblyFormat = [{
    $op `is` (`at_least` $atLeast^)? $count attr-dict
  }];
}

def Match_CheckResultCountOp : Match_Op<"check_result_count", [Match_Question]> {
  let summary = "Test the result count of an operation";
  let arguments = (ins PDL_Operation:$op,
                       ConfinedAttr<I32Attr, [IntNonNegative]>:$count,
                       UnitAttr:$atLeast);
  let assemblyFormat = [{
    $op `is` (`at_least` $atLeast^)? $count attr-dict
  }];
}

def Match_ApplyNativeConstraintOp : Match_Op<"apply_native_constraint"> {
  let summary = "Apply a native constraint";
  let arguments = (ins StrAttr:$name,
                       Variadic<PDL_AnyType>:$args,
                       DefaultValuedAttr<BoolAttr, "false">:$isNegated);
  let results = (outs Variadic<PDL_AnyType>:$constraintResults);
  let assemblyFormat = [{
    $name `(` $args `:` type($args) `)`
    (`is_negated` `=` $isNegated^)? (`:` type($constraintResults)^)? attr-dict
  }];
  let hasVerifier = 1;
}

def Match_ApplyNativeRewriteOp : Match_Op<"apply_native_rewrite"> {
  let summary = "Apply a native rewrite method";

  let arguments = (ins StrAttr:$name, Variadic<PDL_AnyType>:$args);
  let results = (outs Variadic<PDL_AnyType>:$results);
  let assemblyFormat = [{
    $name (`(` $args^ `:` type($args) `)`)? (`:` type($results)^)? attr-dict
  }];
  let hasVerifier = 1;
}

def Match_SuccessOp : Match_Op<"success", [
    DeclareOpInterfaceMethods<SymbolUserOpInterface>]> {
  let summary = "Marks a successful pattern match";

  let arguments = (ins SymbolRefAttr:$rewriter,
                       ConfinedAttr<I16Attr, [IntNonNegative]>:$benefit,
                       Variadic<PDL_AnyType>:$inputs);
  let assemblyFormat = [{
    $rewriter `benefit` `(` $benefit `)`
    (`(` $inputs^ `:` type($inputs) `)`)? attr-dict
  }];
  let hasVerifier = 1;
}

def Match_RewriterOp : Match_Op<"rewriter", [
    IsolatedFromAbove, SingleBlock, NoTerminator,
    DeclareOpInterfaceMethods<OpAsmOpInterface, ["getDefaultDialect"]>,
    SymbolName, SymbolVisibility, Symbol
  ]> {
  let summary = "Container for the rewrite IR of one pattern";

  let arguments = (ins SymbolNameAttr:$sym_name,
                       OptionalAttr<StrAttr>:$sym_visibility);
  let regions = (region SizedRegion<1>:$body);

  let hasCustomAssemblyFormat = 1;
  let hasRegionVerifier = 1;

  let skipDefaultBuilders = 1;
  let builders = [
    OpBuilder<(ins "::llvm::StringRef":$name)>,
  ];
}

def Match_CreateOperationOp
    : Match_Op<"create_operation", [AttrSizedOperandSegments]> {
  let summary = "Create an operation";

  let arguments = (ins StrAttr:$name,
                       Variadic<PDL_InstOrRangeOf<PDL_Value>>:$inputOperands,
                       Variadic<PDL_Attribute>:$inputAttributes,
                       StrArrayAttr:$inputAttributeNames,
                       Variadic<PDL_InstOrRangeOf<PDL_Type>>:$inputResultTypes,
                       UnitAttr:$inferredResultTypes);
  let results = (outs PDL_Operation:$resultOp);

  let builders = [
    OpBuilder<(ins "StringRef":$name, "ValueRange":$types,
      "bool":$inferredResultTypes, "ValueRange":$operands,
      "ValueRange":$attributes, "ArrayAttr":$attributeNames), [{
      build($_builder, $_state, $_builder.getType<pdl::OperationType>(), name,
            operands, attributes, attributeNames, types, inferredResultTypes);
    }]>
  ];
  let assemblyFormat = [{
    $name (`(` $inputOperands^ `:` type($inputOperands) `)`)? ``
    custom<CreateOperationOpAttributes>($inputAttributes, $inputAttributeNames)
    custom<CreateOperationOpResults>($inputResultTypes, type($inputResultTypes),
                                     $inferredResultTypes)
    attr-dict
  }];
  let hasVerifier = 1;
}

def Match_CreateRangeOp : Match_Op<"create_range", [Pure]> {
  let summary = "Construct a range of values or types";

  let arguments = (ins Variadic<PDL_AnyType>:$arguments);
  let results = (outs PDL_RangeOf<AnyTypeOf<[PDL_Type, PDL_Value]>>:$result);
  let assemblyFormat = [{
    ($arguments^ `:` type($arguments))?
    custom<RangeType>(ref(type($arguments)), type($result))
    attr-dict
  }];
  let hasVerifier = 1;
}

def Match_ReplaceOp : Match_Op<"replace"> {
  let summary = "Replace an operation with a set of values";

  let arguments = (ins PDL_Operation:$inputOp,
                       Variadic<PDL_InstOrRangeOf<PDL_Value>>:$replValues);
  let assemblyFormat = [{
    $inputOp `with` ` ` `(` ($replValues^ `:` type($replValues))? `)`
    attr-dict
  }];
}

def Match_EraseOp : Match_Op<"erase"> {
  let summary = "Erase an operation";

  let arguments = (ins PDL_Operation:$inputOp);
  let assemblyFormat = "$inputOp attr-dict";
}

#endif // MLIR_DIALECT_MATCH_IR_MATCHOPS
