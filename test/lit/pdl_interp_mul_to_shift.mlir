// RUN: tamagoyaki-opt -ematch-apply-pdl-interp %s | FileCheck %s

module @ir {
    // CHECK:      func.func @main(%arg0: i32) -> i32 {
    // CHECK-NEXT:   %c1_i32 = arith.constant 1 : i32
    // CHECK-NEXT:   %0 = arith.shli %arg0, %c1_i32 : i32
    // CHECK-NEXT:   return %0 : i32
    // CHECK-NEXT: }

    func.func @main(%a: i32) -> i32 {
        %two = arith.constant 2 : i32
        %res = arith.muli %a, %two : i32
        func.return %res : i32
    }
}

// The pdl pattern is lowered to pdl_interp through the match dialect (without
// e-matching) and applied with the greedy pattern rewrite driver.
module @patterns {
  pdl.pattern @mul_to_shift : benefit(1) {
    %type = pdl.type : i32
    %x = pdl.operand : %type
    %two_attr = pdl.attribute = 2 : i32
    %two_op = pdl.operation "arith.constant" {"value" = %two_attr} -> (%type : !pdl.type)
    %two = pdl.result 0 of %two_op
    %mul = pdl.operation "arith.muli"(%x, %two : !pdl.value, !pdl.value) -> (%type : !pdl.type)
    pdl.rewrite %mul {
      %one_attr = pdl.attribute = 1 : i32
      %one_op = pdl.operation "arith.constant" {"value" = %one_attr} -> (%type : !pdl.type)
      %one = pdl.result 0 of %one_op
      %shl = pdl.operation "arith.shli"(%x, %one : !pdl.value, !pdl.value) -> (%type : !pdl.type)
      pdl.replace %mul with %shl
    }
  }
}
