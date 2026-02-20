//===- HWDialect.td - HW dialect definition ----------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This contains the HWDialect definition to be included in other files.
//
//===----------------------------------------------------------------------===//

#ifndef HW_DIALECT
#define HW_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Pass/PassBase.td"

def HWDialect : Dialect {
  let name = "hw";
  let cppNamespace = "::hw";

  let summary = "Types and operations for the hardware dialect";
  let description = [{
    This dialect defines the `hw` dialect, which is intended to be a generic
    representation of HW outside of a particular use-case.
  }];

  // let hasConstantMaterializer = 1;
  // let useDefaultTypePrinterParser = 1;

  // let extraClassDeclaration = [{
  //   /// Register all HW types.
  //   void registerTypes();
  //   /// Register all HW attributes.
  //   void registerAttributes();

  //   Attribute parseAttribute(DialectAsmParser &p, Type type) const override;
  //   void printAttribute(Attribute attr, DialectAsmPrinter &p) const override;
  // }];
}

// Base class for the operation in this dialect.
class HWOp<string mnemonic, list<Trait> traits = []> :
    Op<HWDialect, mnemonic, traits>;


def ConstantOp
 : HWOp<"constant", [Pure, ConstantLike, FirstAttrDerivedResultType]> {
  let summary = "Produce a constant value";
  let description = [{
    The constant operation produces a constant value of standard integer type
    without a sign.
    ```
      %result = hw.constant 42 : t1
    ```
    }];

  let arguments = (ins APIntAttr:$value);
  let results = (outs AnyInteger:$result);
  let hasCustomAssemblyFormat = 1;

  // let builders = [
  //   /// Build a ConstantOp from an APInt, infering the result type from the
  //   /// width of the APInt.
  //   OpBuilder<(ins "const APInt &":$value)>,

  //   /// This builder allows construction of small signed integers like 0, 1, -1
  //   /// matching a specified MLIR IntegerType.  This shouldn't be used for
  //   /// general constant folding because it only works with values that can be
  //   /// expressed in an int64_t.  Use APInt's instead.
  //   OpBuilder<(ins "Type":$type, "int64_t":$value)>,

  //   /// Build a ConstantOp from a prebuilt attribute.
  //   OpBuilder<(ins "IntegerAttr":$value)>
  // ];
  // let hasFolder = true;
  // let hasVerifier = 1;
}

#endif // HW_DIALECT
