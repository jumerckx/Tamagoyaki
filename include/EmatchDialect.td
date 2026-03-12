//===- EmatchDialect.td - Ematch dialect ----*- tablegen -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef EMATCH_DIALECT
#define EMATCH_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Pass/PassBase.td"
include "mlir/Dialect/PDL/IR/PDLTypes.td"

//===----------------------------------------------------------------------===//
// Ematch dialect definition.
//===----------------------------------------------------------------------===//

def Ematch_Dialect : Dialect {
    let name = "ematch";
    let summary = "An ematch out-of-tree MLIR dialect.";
    let description = [{
        This dialect is an example of an out-of-tree MLIR dialect designed to
        illustrate the basic setup required to develop MLIR-based tools without
        working inside of the LLVM source tree.
    }];
    let cppNamespace = "::mlir::ematch";

    let useDefaultTypePrinterParser = 1;
}

//===----------------------------------------------------------------------===//
// Base ematch operation definition.
//===----------------------------------------------------------------------===//

class Ematch_Op<string mnemonic, list<Trait> traits = []> :
        Op<Ematch_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Ematch Operations
//===----------------------------------------------------------------------===//

def Ematch_FooOp : Ematch_Op<"foo", [Pure, SameOperandsAndResultType]> {
    let summary = "Illustrates how to define an operation.";
    let description = [{
        The `ematch.foo` operation illustrates how to define a new
        operation in a dialect. It uses an operation trait to declare that it
        has no side effects.

        This operation takes an integer argument and returns an integer.

        Example:

        ```mlir
        %0 = arith.constant 2 : i32
        // Apply the foo operation to %0
        %1 = ematch.foo %0 : i32
        ```
    }];

    let arguments = (ins I32:$input);
    let results = (outs I32:$res);

    let assemblyFormat = [{
        $input attr-dict `:` type($input)
    }];
}

def Ematch_GetClassValsOp : Ematch_Op<"get_class_vals"> {
    let summary = "Get all values in the equivalence class of a value.";
    let description = [{
        Take a value and return all values in its equivalence class.

        If the value is an equivalence.class result, return the operands of the
        class, otherwise return a range containing the value itself.
    }];

    let arguments = (ins PDL_Value:$value);
    let results = (outs PDL_RangeOf<PDL_Value>:$result);

    let assemblyFormat = "$value attr-dict";
}

def Ematch_GetClassRepresentativeOp : Ematch_Op<"get_class_representative"> {
    let summary = "Get one of the values in the equivalence class of a value.";
    let description = [{
        Get one of the values in the equivalence class of v.
    }];

    let arguments = (ins PDL_Value:$value);
    let results = (outs PDL_Value:$result);

    let assemblyFormat = "$value attr-dict";
}

def Ematch_GetClassResultOp : Ematch_Op<"get_class_result"> {
    let summary = "Get the equivalence.class result for the class of a value.";
    let description = [{
        Get the equivalence.class result corresponding to the equivalence class
        of v.
    }];

    let arguments = (ins PDL_Value:$value);
    let results = (outs PDL_Value:$result);

    let assemblyFormat = "$value attr-dict";
}

def Ematch_GetClassResultsOp : Ematch_Op<"get_class_results"> {
    let summary = "Get equivalence.class results for a range of values.";
    let description = [{
        Get the equivalence.class results corresponding to the equivalence
        classes of a range of values.
    }];

    let arguments = (ins PDL_RangeOf<PDL_Value>:$values);
    let results = (outs PDL_RangeOf<PDL_Value>:$result);

    let assemblyFormat = "$values attr-dict";
}

def Ematch_UnionOp : Ematch_Op<"union"> {
    let summary = "Merge values or operations into equivalence class(es).";
    let description = [{
        Merge two values, an operation and a value range, or two value ranges
        into equivalence class(es).

        Supported operand type combinations:
        - (value, value): merge two values
        - (operation, range<value>): merge operation results with values
        - (range<value>, range<value>): merge two value ranges
    }];

    let arguments = (ins
        AnyTypeOf<[PDL_Value, PDL_Operation, PDL_RangeOf<PDL_Value>]>:$lhs,
        AnyTypeOf<[PDL_Value, PDL_RangeOf<PDL_Value>]>:$rhs
    );

    let assemblyFormat = "$lhs `:` type($lhs) `,` $rhs `:` type($rhs) attr-dict";
}

def Ematch_DedupOp : Ematch_Op<"dedup"> {
    let summary = "Deduplicate an operation against the hashcons.";
    let description = [{
        Check if the operation already exists in the hashcons.

        If so, remove the new one and return the existing one.
    }];

    let arguments = (ins PDL_Operation:$input_op);
    let results = (outs PDL_Operation:$result_op);

    let assemblyFormat = "$input_op attr-dict";
}

//===----------------------------------------------------------------------===//
// Ematch Passes
//===----------------------------------------------------------------------===//

def EmatchSaturatePass : Pass<"ematch-saturate", "::mlir::ModuleOp"> {
    let summary = "Run equality saturation on the program with the provided patterns.";
    let description = [{
        This pass applies pattern rewriting to operations in the ematch dialect.
        It serves as an example of implementing a transformation pass.
    }];
    let dependentDialects = ["::mlir::ematch::EmatchDialect"];
    let options = [
        Option<"maxIters", "max-iters", "int", "4",
               "Maximum number of iterations before equality saturation times out.">,
        Option<"maxNodes", "max-nodes", "int", "0",
               "Maximum number of nodes in the e-graph (0 = unlimited).">,
        Option<"patternsFile", "patterns-file", "std::string", /*default=*/"\"\"",
               "Path to an MLIR file containing the patterns module. "
               "When set, the input module is treated as the IR module directly.">
    ];
}

def EmatchSaturateBenchmarkPass : Pass<"ematch-saturate-benchmark", "::mlir::ModuleOp"> {
    let summary = "Run equality saturation N times for benchmarking/profiling.";
    let description = [{
        This pass runs the ematch-saturate pass N times, cloning the IR module
        each time to ensure fresh input. Useful for profiling and benchmarking.
    }];
    let dependentDialects = ["::mlir::ematch::EmatchDialect"];
    let options = [
        Option<"numRuns", "num-runs", "int", "10",
               "Number of times to run equality saturation.">,
        Option<"maxIters", "max-iters", "int", "4",
               "Maximum number of iterations before equality saturation times out.">,
        Option<"maxNodes", "max-nodes", "int", "0",
               "Maximum number of nodes in the e-graph (0 = unlimited).">
    ];
}

def ApplyPDLInterpPass : Pass<"ematch-apply-pdl-interp", "::mlir::ModuleOp"> {
    let summary = "Apply pdl_interp patterns to the IR module using the greedy pattern rewrite driver.";
    let description = [{
        A debugging pass that applies pdl_interp patterns to the IR module using
        MLIR's greedy pattern rewrite driver, similar to TestPDLByteCode in MLIR.
    }];
    let dependentDialects = ["::mlir::ematch::EmatchDialect"];
}

def ConvertEmatchToPDLInterpPass : Pass<"convert-ematch-to-pdl-interp", "::mlir::ModuleOp"> {
    let summary = "Convert ematch operations to pdl_interp apply_rewrite operations.";
    let description = [{
        This pass converts operations in the ematch dialect into a
        pdl_interp.apply_rewrite operations.
        Note that this transformation also happens in ematch-saturate by default.
    }];
    let dependentDialects = ["::mlir::ematch::EmatchDialect"];
}

#endif // EMATCH_DIALECT
