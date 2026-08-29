// module MulSel #(
//     parameter BW = 32
// )
// (
//     input logic [BW-1:0] a,
//     input logic [BW-1:0] b,
//     input logic [BW-1:0] c,
//     input logic s,
//     output logic [2*BW - 1:0] out
// );
//
// assign out = s ? a * b : a * c;
//
// endmodule

module @ir {
  hw.module @MulSel(in %a : i32, in %b : i32, in %c : i32, in %s : i1, out result : i64) {
    %c0_i32 = hw.constant 0 : i32
    %0 = comb.concat %c0_i32, %a : i32, i32
    %1 = comb.concat %c0_i32, %b : i32, i32
    %2 = comb.mul %0, %1 : i64
    %3 = comb.concat %c0_i32, %c : i32, i32
    %4 = comb.mul %0, %3 : i64
    %5 = comb.mux %s, %2, %4 : i64
    hw.output %5 : i64
  }
}
