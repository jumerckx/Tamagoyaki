//===- EquivalenceDialect.td - Equivalence dialect -----------------*- tablegen -*-===//
//
// This file is licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef EQUIVALENCE_DIALECT
#define EQUIVALENCE_DIALECT

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td" 
include "mlir/Pass/PassBase.td"
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/RegionKindInterface.td"


//===----------------------------------------------------------------------===//
// Equivalence dialect definition.
//===----------------------------------------------------------------------===//

def Equivalence_Dialect : Dialect {
    let name = "equivalence";
    let summary = "A dialect for representing e-graphs as MLIR operations.";
    let description = [{
        The equivalence dialect represents e-graphs: `equivalence.graph` holds an
        unordered region of operations, and `equivalence.class` groups values
        that are known to be equivalent.
    }];
    let cppNamespace = "::mlir::equivalence";

    let useDefaultAttributePrinterParser = 1;
    let extraClassDeclaration = [{
        void registerAttributes();
    }];
}

//===----------------------------------------------------------------------===//
// Base equivalence operation definition.
//===----------------------------------------------------------------------===//

class Equivalence_Op<string mnemonic, list<Trait> traits = []> :
        Op<Equivalence_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Equivalence Operations
//===----------------------------------------------------------------------===//

// definition of the YieldOp (equivalence.yield)
def Equivalence_YieldOp : Equivalence_Op<"yield", [
    HasParent<"GraphOp">,
    Pure,
    ReturnLike,
    Terminator, 
]> {
    let summary = "Yield values from a graph region";
    let description = [{
        The `equivalence.yield` operation yields values from a `equivalence.graph` region.
        It serves as the terminator for the graph block.
    }];

    let arguments = (ins Variadic<AnyType>:$values);
    
    let assemblyFormat = [{
        attr-dict ($values^ `:` type($values))?
    }];
    
    // This allows SingleBlockImplicitTerminator to build 'equivalence.yield'
    // without arguments when closing the block.
    let builders = [
        OpBuilder<(ins), [{ return; }]>
    ];

}

def Equivalence_GraphOp : Equivalence_Op<"graph", [
    SingleBlockImplicitTerminator<"YieldOp">,
    DeclareOpInterfaceMethods<RegionKindInterface>,
    RecursivelySpeculatable,
 ]> {
    let summary = "A graph region operation";
    let description = [{
        The `equivalence.graph` operation contains a single-block region in which
        equivalence classes and other operations are defined. Importantly,
        operations in the region are unordered, value uses can come before
        their definitions.
    }];

    let arguments = (ins);
    let results = (outs Variadic<AnyType>:$outputs);

    let regions = (region SizedRegion<1>:$body);

    let assemblyFormat = [{
        ( `->` `(` type($outputs)^ `)` )? $body attr-dict
    }];

    let hasVerifier = 1; 
}


def Equivalence_ClassOp : Equivalence_Op<"class", [
    Pure, 
    SameOperandsAndResultType,
    AttrSizedOperandSegments,
]> {
    let summary = "An e-class representing a set of equivalent values";
    let description = [{
        An e-class operation representing a set of equivalent values.
        Optionally carries a `leader` operand for lazy union-find: when
        present, `leader` points to the canonical representative e-class.
    }];

    let arguments = (ins 
        Variadic<AnyType>:$inputs,
        Optional<AnyType>:$leader,
        OptionalAttr<I64Attr>:$min_cost_index
    );

    let results = (outs AnyType:$result);

    let assemblyFormat = [{
        $inputs (`leader` $leader^)? (` ` `(` `min_cost_index` `=` $min_cost_index^ `)` )? attr-dict `:` type($result)
    }];

    let hasFolder = 1;

    // Establishes the class normal form: merges a nested class operand into
    // this class, and redirects any *other* op that still refers to an operand
    // directly so that it refers to the class result instead.
    let hasCanonicalizeMethod = 1;

    // Verify:
    // 1. At least one operand.
    // 2. If present, the leader is the result of a ClassOp.
    // The normal-form properties (a class result is never an operand of another
    // class; operands are used only by the class; operands are unique) are
    // established by the `equivalence-restore-invariants` pass, not enforced
    // here.
    let hasVerifier = 1;
}

//===----------------------------------------------------------------------===//
// Other Definitions
//===----------------------------------------------------------------------===//

def EquivalenceInsertGraph : Pass<"equivalence-insert-graph", "::mlir::ModuleOp"> {
  let summary = "Replaces a function body with a equivalence.graph operation.";
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect", "::mlir::func::FuncDialect"];
}
  

def EquivalenceExtract: Pass<"equivalence-extract", "::mlir::ModuleOp"> {
  let summary = "Extracts selected nodes from equivalence classes.";
  let description = [{
    After greedy selection has set min_cost_index on ClassOps, this pass
    extracts the selected operand from each e-class: replaces the ClassOp
    result with the chosen operand, erases the ClassOp and all non-selected
    candidate operations, and removes the cost attribute from the selected op.
    ClassOps with no uses are erased entirely along with their operand ops.
    ClassOps without a min_cost_index are left untouched.
  }];
  let options = [
    Option<"removeGraphs", "remove-graphs", "bool", "false",
           "Remove the GraphOp wrapper if all e-classes have been extracted">
  ];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

def EquivalenceSelectGreedy: Pass<"equivalence-select-greedy", "::mlir::ModuleOp"> {
  let summary = "Performs greedy cost-based extraction for equivalence classes.";
  let description = [{
    Implements greedy cost-based extraction for equivalence classes using
    bottom-up fixed-point iteration. For each e-class, finds the minimum cost
    node and sets the min_cost_index attribute on ClassOp operations.
  }];
  let options = [
    Option<"costFile", "cost-file", "std::string", "",
           "Path to JSON file containing operation costs">,
    Option<"defaultCost", "default-cost", "int", "-1",
           "Default cost for operations not in cost file (-1 means none)">,
    Option<"costAttributeName", "attribute-name", "std::string", "\"equivalence.cost\"",
           "Name of the attribute representing the local cost of operations">
  ];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

def EquivalenceSelectConstants: Pass<"equivalence-select-constants", "::mlir::ModuleOp"> {
  let summary = "Selects constant operands in equivalence classes.";
  let description = [{
    Walks each e-class (ClassOp) in the graph and inspects its operands. For
    classes that contain an operand produced by a constant operation, selects
    that operand. Classes that already carry a `min_cost_index`, or that contain
    no constant operand, are left untouched.
  }];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

def EquivalenceRestoreInvariants: Pass<"equivalence-restore-invariants", "::mlir::ModuleOp"> {
  let summary = "Restores the equivalence-class normal form to a fixpoint.";
  let description = [{
    Applies the `equivalence.class` canonicalization patterns until no further
    rewrites apply, re-establishing the class normal form:

      * a class result is never used as an operand of another class
        (nested classes are merged), and
      * a class's operands are used only by that class
        (external uses are rerouted through the class result).
      * class operands are deduplicated

    Unlike the general `--canonicalize` pass, this runs the greedy driver with
    no iteration or rewrite limit, so it reaches a genuine fixpoint. Folding and
    constant CSE are disabled: those optimizing rewrites (e.g. collapsing a
    single-element class to its operand) are not part of the normal form and
    would destroy e-graph structure that downstream consumers depend on.
  }];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

def EquivalenceGraphSize: Pass<"equivalence-graph-size", "::mlir::ModuleOp"> {
  let summary = "Prints the size of each equivalence graph in the module.";
  let description = [{
    Walks each `equivalence.graph` in the module and prints the number of
    e-classes and e-nodes it contains. This is the same metric reported during
    equality saturation debug output.
  }];
  let dependentDialects = ["::mlir::equivalence::EquivalenceDialect"];
}

//===----------------------------------------------------------------------===//
// Equivalence Attributes
//===----------------------------------------------------------------------===//

class Equivalence_Attr<string name, string attrMnemonic, list<Trait> traits = []>
    : AttrDef<Equivalence_Dialect, name, traits> {
  let mnemonic = attrMnemonic;
}

def Equivalence_CostAttr : Equivalence_Attr<"Cost", "cost"> {
  let summary = "An attribute representing the cost of an operation";
  let description = [{
    This attribute stores the cost of an operation for use in cost-based
    extraction algorithms. A value of -1 indicates no cost is available.
  }];
  let parameters = (ins "int64_t":$value);
  let assemblyFormat = "`<` $value `>`";
}

#endif // EQUIVALENCE_DIALECT
