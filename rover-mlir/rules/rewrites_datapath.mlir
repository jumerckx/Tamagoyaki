//------------------------------------------------------------------------------
// DATAPATH REWRITES -- extension to rewrites_base.mlir
//
// Lowerings into the CIRCT datapath dialect, via the native rewrites
// BuildPartialProduct / BuildCompress registered by RoverSaturatePass. Appended
// to rewrites_base.mlir for the evaluation's "multi" configuration; this file
// is never used on its own.
//------------------------------------------------------------------------------
pdl.pattern @AddAddToCompress : benefit(1) {
  %type = pdl.type

  %a = pdl.operand : %type
  %b = pdl.operand : %type
  %c = pdl.operand : %type

  %add0 = pdl.operation "comb.add"(%a, %b, %c : !pdl.value, !pdl.value, !pdl.value)
            -> (%type : !pdl.type)

  pdl.rewrite %add0 {
    %range = pdl.range %a, %b, %c : !pdl.value, !pdl.value, !pdl.value
    %compress = pdl.apply_native_rewrite "BuildCompress"
             (%range: !pdl.range<value>)
             : !pdl.operation
    
    %comp0 = pdl.result 0 of %compress
    %comp1 = pdl.result 1 of %compress

    %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
             -> (%type : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %add0 with %add
  }
}

// Bind the two operands and the result type of the comb.mul.
pdl.pattern @MulToPartialProductTree : benefit(1) {

  // Operands – we don't constrain them beyond "they exist".
  %lhs = pdl.operand
  %rhs = pdl.operand

  // The result type of the mul (an integer type of some width).
  %resultType = pdl.type

  // The comb.mul operation itself.
  %mulOp = pdl.operation "comb.mul"(%lhs, %rhs : !pdl.value, !pdl.value)
               -> (%resultType : !pdl.type)

  // ── Rewrite ────────────────────────────────────────────────────────────────
  pdl.rewrite %mulOp {
    // Delegate all width-dependent IR construction to C++.
    // Returns the comb.add Operation that replaces the mul.
    %pp = pdl.apply_native_rewrite "BuildPartialProduct"
                 (%mulOp: !pdl.operation)
                 : !pdl.operation
    %ppResults = pdl.results of %pp 

    %compress = pdl.apply_native_rewrite "BuildCompress"
             (%ppResults: !pdl.range<value>)
             : !pdl.operation
    
    %comp0 = pdl.result 0 of %compress
    %comp1 = pdl.result 1 of %compress

    %add = pdl.operation "comb.add"(%comp0, %comp1 : !pdl.value, !pdl.value)
             -> (%resultType : !pdl.type)
    // Splice the comb.add result in place of the original mul result.
    pdl.replace %mulOp with %add
  }
}
