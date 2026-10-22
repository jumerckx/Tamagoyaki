// RUN: tamagoyaki-opt %s -split-input-file -convert-pdl-to-match -verify-diagnostics

module {
  pdl.pattern : benefit(1) {
    %v = pdl.operand

    // expected-error @below {{constraint argument is not reachable from the pattern root and is not a constant}}
    pdl.apply_native_constraint "c"(%v : !pdl.value)

    %root = operation "foo.op"
    rewrite %root with "rewriter"
  }
}

// -----

module {
  pdl.pattern : benefit(1) {
    %type = type : i32
    %attr = attribute : %type

    // expected-error @below {{constraint argument is not reachable from the pattern root and is not a constant}}
    pdl.apply_native_constraint "c"(%attr : !pdl.attribute)

    %root = operation "foo.op"
    rewrite %root with "rewriter"
  }
}
