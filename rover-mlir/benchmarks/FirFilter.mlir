// module FirFilter #(
//     parameter BW = 32
// ) 
// (
//     input logic [BW-1:0] z1,
//     input logic [BW-1:0] z2,
//     input logic [BW-1:0] z3,
//     input logic [BW-1:0] z4,
//     input logic [BW-1:0] add0,
//     input logic [$clog2(BW)-1:0] s,
//     output logic [BW - 1:0] out
// );  
// 
// 
// logic [BW -1 : 0] add1;
// logic [BW -1 : 0] add2;
// logic [BW -1 : 0] add3;
// logic [BW -1 : 0] add4;
// 
// assign add1 = (add0 + z1) >> s;
// assign add2 = (add1 + z2) >> s;
// assign add3 = (add2 + z3) >> s;
// assign add4 = (add3 + z4);
// assign out = add4;
// 
// endmodule

module @ir {
  func.func @FirFilter(%z1 : i32, %z2 : i32, %z3 : i32, %z4 : i32, %add0 : i32, %s : i5) -> i32 {
    %c0_i27 = hw.constant 0 : i27
    %0 = comb.add %add0, %z1 : i32
    %1 = comb.concat %c0_i27, %s : i27, i5
    %2 = comb.shru %0, %1 {sv.namehint = "add1"} : i32
    %3 = comb.add %2, %z2 : i32
    %4 = comb.shru %3, %1 {sv.namehint = "add2"} : i32
    %5 = comb.add %4, %z3 : i32
    %6 = comb.shru %5, %1 {sv.namehint = "add3"} : i32
    %7 = comb.add %6, %z4 {sv.namehint = "add4"} : i32
    func.return %7 : i32
  }
}
