// RUN: true

// A pdl_interp matcher for `arith.muli %x, 2` written for e-matching. It uses
// `ematch.is_arg` to require that the multiplied value `%x` is block argument 0
// of the function, fully grounding the pattern. The pass replaces the
// `pdl_interp.record_match` with a recording constraint.

pdl_interp.func @matcher(%arg0: !pdl.operation) {
    %0 = pdl_interp.get_operand 1 of %arg0
    pdl_interp.is_not_null %0 : !pdl.value -> ^bb_success, ^bb1
    ^bb_success:
    %eqvals = ematch.get_class_vals %0
    pdl_interp.foreach %eqval : !pdl.value in %eqvals {
        %op = pdl_interp.get_defining_op of %eqval : !pdl.value
        pdl_interp.is_not_null %op : !pdl.operation -> ^bb2, ^bb_continue
    ^bb2:
        pdl_interp.check_operation_name of %arg0 is "arith.muli" -> ^bb3, ^bb_continue
    ^bb3:
        pdl_interp.check_operand_count of %arg0 is 2 -> ^bb4, ^bb_continue
    ^bb4:
        pdl_interp.check_result_count of %arg0 is 1 -> ^bb5, ^bb_continue
    ^bb5:
        %2 = pdl_interp.get_operand 0 of %arg0
        pdl_interp.is_not_null %2 : !pdl.value -> ^bb6, ^bb_continue
    ^bb6:
        pdl_interp.check_operation_name of %op is "arith.constant" -> ^bb7, ^bb_continue
    ^bb7:
        %3 = pdl_interp.get_attribute "value" of %op
        pdl_interp.is_not_null %3 : !pdl.attribute -> ^bb8, ^bb_continue
    ^bb8:
        pdl_interp.check_attribute %3 is 2 : i32 -> ^bb_isarg, ^bb_continue
    ^bb_isarg:
        ematch.is_arg %2, 0 -> ^bb_record, ^bb_continue
    ^bb_record:
        pdl_interp.record_match @rewriters::@mul_to_shift(%2, %arg0 : !pdl.value, !pdl.operation) : benefit(1), loc([%op, %arg0]), root("arith.muli") -> ^bb_continue
    ^bb_continue:
        pdl_interp.continue
    } -> ^bb1
    ^bb1:
        pdl_interp.finalize
}
module @rewriters {
    pdl_interp.func @mul_to_shift(%arg0: !pdl.value, %arg1: !pdl.operation) {
        pdl_interp.finalize
    }
}
