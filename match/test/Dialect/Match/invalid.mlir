// RUN: tamagoyaki-opt %s -split-input-file -verify-diagnostics

// expected-error @below {{expected inner type of match.optional to be a PDL type}}
func.func private @optional_inner_type(!match.optional<i32>)

// -----

module {
  module @rewriters { module @foo {} }
  // expected-error @below {{expected body block argument to be of type !pdl.operation}}
  match.matcher @root_type root(%root : i32) {
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  // expected-error @below {{expected body block to have exactly one argument}}
  "match.matcher"() ({
  ^bb0(%a: !pdl.operation, %b: !pdl.operation):
    "match.success"() {rewriter = @rewriters::@foo, benefit = 1 : i16} : () -> ()
  }) {sym_name = "two_args"} : () -> ()
}

// -----

module {
  // expected-error @below {{expected matcher to contain at least one `match.success`}}
  match.matcher @no_success root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @try_no_success root(%root : !pdl.operation) {
    // expected-error @below {{region contains no `match.success`}}
    match.try {
      match.has_name %root, "foo.op"
    }
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @switch_name_count root(%root : !pdl.operation) {
    // expected-error @below {{expected one region per case name (2 names vs 1 regions)}}
    "match.switch_op_name"(%root) ({
      "match.success"() {rewriter = @rewriters::@foo, benefit = 1 : i16} : () -> ()
    }) {caseNames = ["a.op", "b.op"]} : (!pdl.operation) -> ()
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @switch_type_count root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    %t = match.get_value_type of %v : !pdl.type
    // expected-error @below {{expected one region per case type (2 types vs 1 regions)}}
    "match.switch_type"(%t) ({
      "match.success"() {rewriter = @rewriters::@foo, benefit = 1 : i16} : () -> ()
    }) {caseTypes = [i32, i64]} : (!pdl.type) -> ()
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @value_type_range root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    %v = match.is_not_null %r : !pdl.value
    // expected-error @below {{failed to verify that `value` type matches arity of `result`}}
    %t = "match.get_value_type"(%v) : (!pdl.value) -> !pdl.range<type>
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @foreach_not_range root(%root : !pdl.operation) {
    // expected-error @below {{expected the iterated value to be a !pdl.range type, but got '!pdl.operation'}}
    match.foreach %e in %root : !pdl.operation {
      match.success @rewriters::@foo benefit(1)
    }
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @foreach_dead root(%root : !pdl.operation) {
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    // expected-error @below {{`match.foreach` body contains no `match.success` (directly or transitively); the region is dead}}
    match.foreach %e in %vs : !pdl.range<value> {
      %t = match.get_value_type of %e : !pdl.type
      match.has_type %t, i32
    }
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @unwrap_type root(%root : !pdl.operation) {
    %r = match.get_result 0 of %root : !match.optional<!pdl.value>
    // expected-error @below {{failed to verify that `optionalValue` is the optional of `unwrapped`}}
    %v = "match.is_not_null"(%r) : (!match.optional<!pdl.value>) -> !pdl.type
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @constraint_returns_op root(%root : !pdl.operation) {
    // expected-error @below {{returning an operation from a constraint is not supported}}
    %c = match.apply_native_constraint "c"(%root : !pdl.operation) : !pdl.operation
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @constraint_no_args root(%root : !pdl.operation) {
    // expected-error @below {{expected at least one argument}}
    "match.apply_native_constraint"() {name = "c"} : () -> ()
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @rewrite_no_args_or_results root(%root : !pdl.operation) {
    // expected-error @below {{expected at least one argument or result}}
    match.apply_native_rewrite "r"
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  // expected-error @below {{`match.success` must be enclosed by a `match.matcher`}}
  match.success @rewriters::@foo benefit(1)
}

// -----

module {
  module @rewriters {}
  match.matcher @unknown_rewriter root(%root : !pdl.operation) {
    // expected-error @below {{references an unknown rewriter symbol: @rewriters::@nope}}
    match.success @rewriters::@nope benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @negative_benefit root(%root : !pdl.operation) {
    // expected-error @below {{'benefit' failed to satisfy constraint: 16-bit signless integer attribute whose value is non-negative}}
    match.success @rewriters::@foo benefit(-1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @negative_count root(%root : !pdl.operation) {
    // expected-error @below {{'count' failed to satisfy constraint: 32-bit signless integer attribute whose value is non-negative}}
    match.check_operand_count %root is -1
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

module {
  module @rewriters { module @foo {} }
  match.matcher @negative_index root(%root : !pdl.operation) {
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    // expected-error @below {{'index' failed to satisfy constraint: 32-bit signless integer attribute whose value is non-negative}}
    %e = match.extract -1 of %vs : !pdl.value
    match.success @rewriters::@foo benefit(1)
  }
}

// -----

// expected-error @below {{failed to satisfy constraint: any type attribute}}
%0 = "match.constant_type"() {value = 10 : i64} : () -> !pdl.type

// -----

// expected-error @below {{failed to satisfy constraint: type array attribute}}
%0 = match.constant_types [i32, 10 : i64]

// -----

module @rewriters {
  match.rewriter @not_allowed(%root : !pdl.operation) {
    // expected-error @below {{'match.has_name' op is not allowed in a `match.rewriter`}}
    match.has_name %root, "foo.op"
  }
}

// -----

module @rewriters {
  // expected-error @below {{expected rewriter arguments to have PDL types, but got 'i32'}}
  match.rewriter @bad_arg(%arg : i32) {
  }
}

// -----

module @rewriters {
  match.rewriter @inferred_and_explicit(%t : !pdl.type) {
    // expected-error @below {{with inferred results cannot also have explicit result types}}
    %op = "match.create_operation"(%t) <{inferredResultTypes, inputAttributeNames = [], name = "foo.op", operandSegmentSizes = array<i32: 0, 0, 1>}> : (!pdl.type) -> !pdl.operation
  }
}

// -----

module @rewriters {
  match.rewriter @range_mismatch(%v : !pdl.value) {
    // expected-error @below {{expected operand to have element type '!pdl.type', but got '!pdl.value'}}
    %r = "match.create_range"(%v) : (!pdl.value) -> !pdl.range<type>
  }
}
