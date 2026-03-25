// module ShiftMult #(
//     parameter BW = 32
// )  // Parameterized width for the multiplier
// (
//     input logic [BW-1:0] a,
//     input logic [BW-1:0] b,
//     input logic [$clog2(BW)-1:0] m,
//     input logic [$clog2(BW)-1:0] n,
//     output logic [2*BW-1:0] out
// );  
// 
// wire [ 2*BW - 1 : 0 ] d, e;
// wire [$clog2(BW):0] sum;
// 
// assign d = a << m;
// assign e = b << n;
// assign out = d * e;
// 
// endmodule

module @ir {
  func.func @ShiftMult(%a : i32, %b : i32, %m : i5, %n : i5) -> i64 {
    %c0_i59 = hw.constant 0 : i59
    %c0_i32 = hw.constant 0 : i32
    %0 = comb.concat %c0_i32, %a : i32, i32
    %1 = comb.concat %c0_i59, %m : i59, i5
    %2 = comb.shl %0, %1 {sv.namehint = "d"} : i64
    %3 = comb.concat %c0_i32, %b : i32, i32
    %4 = comb.concat %c0_i59, %n : i59, i5
    %5 = comb.shl %3, %4 {sv.namehint = "e"} : i64
    %6 = comb.mul %2, %5 : i64
    return %6 : i64
  }
}
