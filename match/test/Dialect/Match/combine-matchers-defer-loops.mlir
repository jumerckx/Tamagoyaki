// RUN: tamagoyaki-opt %s -match-combine-matchers | FileCheck %s --check-prefix=DEFAULT
// RUN: tamagoyaki-opt %s -match-combine-matchers=defer-loops | FileCheck %s

// Not upstream: tests the defer-loops option added to the out-of-tree copy.
//
// Each matcher loops over two ranges and checks the name of an op from each.
// By default both loops are entered first, so the checks of the first loop
// run inside the second one. With defer-loops, a loop is only entered after
// everything that does not depend on it, so the second loop is nested under
// the checks of the first one.

module {
  module @rewriters {
    match.rewriter @a(%root : !pdl.operation) {}
    match.rewriter @b(%root : !pdl.operation) {}
  }

  // DEFAULT-LABEL: match.matcher @combined
  // DEFAULT:         foreach %[[X:.*]] in
  // DEFAULT-NEXT:      foreach %[[Y:.*]] in
  // DEFAULT-NEXT:        switch_op_name %[[X]]

  // CHECK-LABEL: match.matcher @combined
  // CHECK:         has_name %[[ROOT:.*]], "test.root"
  // CHECK-NEXT:    %[[XS:.*]] = apply_native_rewrite "xs"(%[[ROOT]] : !pdl.operation) : !pdl.range<operation>
  // CHECK-NEXT:    %[[YS:.*]] = apply_native_rewrite "ys"(%[[ROOT]] : !pdl.operation) : !pdl.range<operation>
  // CHECK-NEXT:    foreach %[[X:.*]] in %[[XS]] : !pdl.range<operation> {
  // CHECK-NEXT:      switch_op_name %[[X]]
  // CHECK-NEXT:      case "test.a" {
  // CHECK-NEXT:        foreach %[[Y:.*]] in %[[YS]] : !pdl.range<operation> {
  // CHECK-NEXT:          has_name %[[Y]], "test.b"
  // CHECK-NEXT:          success @rewriters::@a
  // CHECK-NEXT:        }
  // CHECK-NEXT:      }
  // CHECK-NEXT:      case "test.b" {
  // CHECK-NEXT:        foreach %[[Y:.*]] in %[[YS]] : !pdl.range<operation> {
  // CHECK-NEXT:          has_name %[[Y]], "test.a"
  // CHECK-NEXT:          success @rewriters::@b
  match.matcher @a root(%root : !pdl.operation) {
    has_name %root, "test.root"
    %xs = apply_native_rewrite "xs"(%root : !pdl.operation) : !pdl.range<operation>
    foreach %x in %xs : !pdl.range<operation> {
      has_name %x, "test.a"
      %ys = apply_native_rewrite "ys"(%root : !pdl.operation) : !pdl.range<operation>
      foreach %y in %ys : !pdl.range<operation> {
        has_name %y, "test.b"
        success @rewriters::@a benefit(1) (%root : !pdl.operation)
      }
    }
  }
  match.matcher @b root(%root : !pdl.operation) {
    has_name %root, "test.root"
    %xs = apply_native_rewrite "xs"(%root : !pdl.operation) : !pdl.range<operation>
    foreach %x in %xs : !pdl.range<operation> {
      has_name %x, "test.b"
      %ys = apply_native_rewrite "ys"(%root : !pdl.operation) : !pdl.range<operation>
      foreach %y in %ys : !pdl.range<operation> {
        has_name %y, "test.a"
        success @rewriters::@b benefit(1) (%root : !pdl.operation)
      }
    }
  }
}
