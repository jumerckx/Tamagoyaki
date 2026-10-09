// RUN: tamagoyaki-opt --ematch-combine-matchers %s | FileCheck %s
// RUN: tamagoyaki-opt --ematch-combine-matchers --ematchify %s \
// RUN:   | FileCheck %s --check-prefix=EMATCH

// ===----------------------------------------------------------------------===//
// Test the ematch-combine-matchers pass.
//
// Two matchers rooted at `arith.addf` each navigate to the defining op of both
// operands and check its name; they disagree only on the names ((sin,cos) vs
// (cos,sin)). The frequency-based `match-combine-matchers` would emit both
// `get_defining_op` navigations up front and defer the name checks to a nested
// branch. This pass instead orders by operation-navigation position, so the
// name check on the first defining op becomes a branch (folded into a
// `switch_op_name`) *above* the navigation to the second defining op.
//
// After ematchify, each `get_defining_op` becomes an e-class loop
// (`get_class_vals` + `get_each`); grouping the name check first means the
// second loop runs only for candidates that already matched the first name —
// avoiding the multiplicative blow-up.
// ===----------------------------------------------------------------------===//

module {
  module @rewriters { module @a {} module @b {} }

  // CHECK-LABEL: match.matcher @a
  // CHECK:         has_name %[[ROOT:.*]], "arith.addf"
  // The first operand's defining op is navigated and its name switched on...
  // CHECK:         %[[D0:.*]] = get_defining_op of %{{.*}}
  // CHECK-NEXT:    %[[DOP0:.*]] = is_not_null %[[D0]] : {{.*}} -> !pdl.operation
  // ...before the second defining op is ever queried.
  // CHECK-NOT:     get_defining_op
  // CHECK:         switch_op_name %[[DOP0]]
  // CHECK:         case "math.sin" {
  // CHECK-NEXT:      %[[D1:.*]] = get_defining_op of
  // CHECK-NEXT:      %[[DOP1:.*]] = is_not_null %[[D1]]
  // CHECK-NEXT:      has_name %[[DOP1]], "math.cos"

  // EMATCH-LABEL: match.matcher @a
  // First operand: one e-class loop, then switch on the defining op's name.
  // EMATCH:         ematch.get_class_vals
  // EMATCH:         %[[E0:.*]] = get_each
  // EMATCH:         %[[GD0:.*]] = get_defining_op of %[[E0]]
  // EMATCH:         %[[G0:.*]] = is_not_null %[[GD0]] : {{.*}} -> !pdl.operation
  // No second e-class loop before the name switch.
  // EMATCH-NOT:     get_class_vals
  // EMATCH:         switch_op_name %[[G0]]
  // EMATCH:         case "math.sin" {
  // The second operand's e-class loop is inside the case, after the first name
  // check has already filtered candidates.
  // EMATCH-NEXT:      ematch.get_class_vals
  // EMATCH-NEXT:      get_each
  match.matcher @a root(%root : !pdl.operation) {
    match.has_name %root, "arith.addf"
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v0 = match.is_not_null %o0 : !match.optional<!pdl.value> -> !pdl.value
    %o1 = match.get_operand 1 of %root : !match.optional<!pdl.value>
    %v1 = match.is_not_null %o1 : !match.optional<!pdl.value> -> !pdl.value
    %d0 = match.get_defining_op of %v0 : !pdl.value -> !match.optional<!pdl.operation>
    %dop0 = match.is_not_null %d0 : !match.optional<!pdl.operation> -> !pdl.operation
    %d1 = match.get_defining_op of %v1 : !pdl.value -> !match.optional<!pdl.operation>
    %dop1 = match.is_not_null %d1 : !match.optional<!pdl.operation> -> !pdl.operation
    match.has_name %dop0, "math.sin"
    match.has_name %dop1, "math.cos"
    match.success @rewriters::@a benefit(1) (%root : !pdl.operation)
  }
  match.matcher @b root(%root : !pdl.operation) {
    match.has_name %root, "arith.addf"
    %o0 = match.get_operand 0 of %root : !match.optional<!pdl.value>
    %v0 = match.is_not_null %o0 : !match.optional<!pdl.value> -> !pdl.value
    %o1 = match.get_operand 1 of %root : !match.optional<!pdl.value>
    %v1 = match.is_not_null %o1 : !match.optional<!pdl.value> -> !pdl.value
    %d0 = match.get_defining_op of %v0 : !pdl.value -> !match.optional<!pdl.operation>
    %dop0 = match.is_not_null %d0 : !match.optional<!pdl.operation> -> !pdl.operation
    %d1 = match.get_defining_op of %v1 : !pdl.value -> !match.optional<!pdl.operation>
    %dop1 = match.is_not_null %d1 : !match.optional<!pdl.operation> -> !pdl.operation
    match.has_name %dop0, "math.cos"
    match.has_name %dop1, "math.sin"
    match.success @rewriters::@b benefit(1) (%root : !pdl.operation)
  }
}
