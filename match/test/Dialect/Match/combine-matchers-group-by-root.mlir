// RUN: tamagoyaki-opt %s -match-combine-matchers=group-by-root | FileCheck %s

// CHECK-LABEL: match.matcher @combined_foo.op root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "foo.op"
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_operand_count %arg0 is 1
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_result_count %arg0 is 1
// CHECK-NEXT:      success @rewriters::@r benefit(2)
// CHECK-NEXT:    }
// CHECK-NEXT:  }
// CHECK-NEXT:  match.matcher @combined root(%arg0: !pdl.operation) {
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_operand_count %arg0 is 2
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:    try {
// CHECK-NEXT:      check_result_count %arg0 is 2
// CHECK-NEXT:      success @rewriters::@r benefit(1)
// CHECK-NEXT:    }
// CHECK-NEXT:  }
// CHECK-NEXT:  match.matcher @bar root(%arg0: !pdl.operation) {
// CHECK-NEXT:    has_name %arg0, "bar.op"
// CHECK-NEXT:    success @rewriters::@r benefit(3)
// CHECK-NEXT:  }
// CHECK-NOT:   match.matcher
module {
  module @rewriters { module @r {} }

  match.matcher @foo_a root(%root : !pdl.operation) {
    match.has_name %root, "foo.op"
    match.check_operand_count %root is 1
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @any_a root(%root : !pdl.operation) {
    match.check_operand_count %root is 2
    match.success @rewriters::@r benefit(1)
  }

  match.matcher @bar root(%root : !pdl.operation) {
    match.has_name %root, "bar.op"
    match.success @rewriters::@r benefit(3)
  }

  match.matcher @foo_b root(%root : !pdl.operation) {
    match.check_result_count %root is 1
    match.has_name %root, "foo.op"
    match.success @rewriters::@r benefit(2)
  }

  match.matcher @any_b root(%root : !pdl.operation) {
    match.check_result_count %root is 2
    match.success @rewriters::@r benefit(1)
  }
}
