// RUN: tamagoyaki-opt %s -split-input-file -allow-unregistered-dialect -verify-diagnostics | FileCheck %s

// Not upstream: the out-of-tree copy lets a `match.rewriter` contain ops of
// other dialects, e.g. to be lowered to native rewrites later. Only the
// `match` and `pdl` ops are restricted.

// CHECK-LABEL: match.rewriter @other_dialect
// CHECK:         "test.helper"(%{{.*}}) : (!pdl.value) -> !pdl.value
module @rewriters {
  match.rewriter @other_dialect(%root : !pdl.operation, %v : !pdl.value) {
    %0 = "test.helper"(%v) : (!pdl.value) -> !pdl.value
    replace %root with (%0 : !pdl.value)
  }
}

// -----

module @rewriters {
  match.rewriter @not_allowed(%root : !pdl.operation) {
    %0 = "test.helper"(%root) : (!pdl.operation) -> !pdl.operation
    // expected-error @below {{'match.has_name' op is not allowed in a `match.rewriter`}}
    has_name %0, "foo"
  }
}
