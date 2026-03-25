// module ShiftedFma #(
//     parameter BW = 32
// )  // Parameterized width for the multiplier
// (
//     input logic [BW-1:0] a,
//     input logic [BW-1:0] b,
//     input logic [$clog2(BW)-1:0] s,
//     input logic [2*BW-1:0] c,
//     output logic [2*BW:0] out
// );  
// 
// wire [ 2*BW : 0 ] d, e;
// wire [$clog2(BW):0] sum;
// 
// assign d = a * b;
// assign e = d << s;
// assign out = e + c;
// 
// // Optimized
// // assign d = (a << s);
// // assign e = d * b;
// // assign out = e + c;
// 
// endmodule

module @ir {
  func.func @ShiftedFma(%a : i32, %b : i32, %s : i5, %c : i64) -> i65 {
    %false = hw.constant false
    %c0_i60 = hw.constant 0 : i60
    %c0_i33 = hw.constant 0 : i33
    %0 = comb.concat %c0_i33, %a : i33, i32
    %1 = comb.concat %c0_i33, %b : i33, i32
    %2 = comb.mul %0, %1 {sv.namehint = "d"} : i65
    %3 = comb.concat %c0_i60, %s : i60, i5
    %4 = comb.shl %2, %3 {sv.namehint = "e"} : i65
    %5 = comb.concat %false, %c : i1, i64
    %6 = comb.add %4, %5 : i65
    func.return %6 : i65
  }
}
