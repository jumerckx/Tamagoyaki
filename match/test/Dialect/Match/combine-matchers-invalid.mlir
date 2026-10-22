// RUN: tamagoyaki-opt %s -split-input-file -match-combine-matchers -verify-diagnostics

module {
  module @rewriters { module @r {} }
  match.matcher @nested root(%root : !pdl.operation) {
    // expected-error @below {{combine-matchers does not support nested `try`/`switch_*` in input matchers}}
    match.try {
      match.has_name %root, "foo.op"
      match.success @rewriters::@r benefit(1)
    }
    match.success @rewriters::@r benefit(2)
  }
  match.matcher @nested_other root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
}

// -----

module {
  module @rewriters { module @r {} }
  match.matcher @nested_switch root(%root : !pdl.operation) {
    // expected-error @below {{combine-matchers does not support nested `try`/`switch_*` in input matchers}}
    match.switch_op_name %root
    case "foo.op" {
      match.success @rewriters::@r benefit(1)
    }
    case "bar.op" {
      match.success @rewriters::@r benefit(2)
    }
  }
  match.matcher @nested_switch_other root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
}

// -----

module {
  module @rewriters { module @r {} }
  match.matcher @foreach_not_last root(%root : !pdl.operation) {
    %rs = match.get_results of %root : !match.optional<!pdl.range<value>>
    %vs = match.is_not_null %rs : !pdl.range<value>
    // expected-error @below {{combine-matchers requires `match.foreach` to be the last op in its block; ops following the loop would be absorbed into its body}}
    match.foreach %e in %vs : !pdl.range<value> {
      %t = match.get_value_type of %e : !pdl.type
      match.has_type %t, i32
      match.success @rewriters::@r benefit(1)
    }
    match.check_operand_count %root is 1
  }
  match.matcher @foreach_not_last_other root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
}

// -----

module {
  module @rewriters { module @r {} }
  match.matcher @two_succ root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(1)
    // expected-error @below {{combine-matchers expects exactly one `match.success` per input matcher}}
    match.success @rewriters::@r benefit(2)
  }
  match.matcher @two_succ_other root(%root : !pdl.operation) {
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }
}
