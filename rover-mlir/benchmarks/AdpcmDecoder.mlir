// module AdpcmDecoder #(
//     parameter BW = 32
// )( 
//     input  logic [BW-1:0] step,
//     input  logic [BW-1:0] delta,
//     output logic [BW-1:0] vpdiff
// );
// 
// 
// wire [BW - 1 : 0] div1, div2, div3;
// wire [BW - 1 : 0] out1, out2, out3;
// wire [2:0] delta7;
// logic sel1, sel2, sel3;
// 
// assign delta7 = delta & 3'd7;
// 
// 
// assign sel1 = (delta7 & 3'd4) == 0;
// assign sel2 = (delta7 & 2'd2) == 0;
// assign sel3 = (delta7 & 1'd1) == 0;
// 
// assign div1 = (step >> 1'd1);
// assign div2 = (step >> 2'd2);
// assign div3 = (step >> 3'd3);
// 
// assign out1 = sel1 ? div3 + step : div3;
// assign out2 = sel2 ? out1 + div1 : out1;
// assign out3 = sel3 ? out2 + div2 : out2;
// 
// assign vpdiff = out3;
// 
// // Optimised Version
// 
// 
// endmodule

module @ir {
  func.func @AdpcmDecoder(%step : i32, %delta : i32) -> i32 {
    %c0_i3 = hw.constant 0 : i3
    %c0_i2 = hw.constant 0 : i2
    %false = hw.constant false
    %true = hw.constant true
    %0 = comb.extract %delta from 2 : (i32) -> i1
    %1 = comb.xor %0, %true {sv.namehint = "sel1"} : i1
    %2 = comb.extract %delta from 1 : (i32) -> i1
    %3 = comb.xor %2, %true {sv.namehint = "sel2"} : i1
    %4 = comb.extract %delta from 0 : (i32) -> i1
    %5 = comb.xor %4, %true {sv.namehint = "sel3"} : i1
    %6 = comb.extract %step from 1 : (i32) -> i31
    %7 = comb.concat %false, %6 : i1, i31
    %8 = comb.extract %step from 2 : (i32) -> i30
    %9 = comb.concat %c0_i2, %8 : i2, i30
    %10 = comb.extract %step from 3 : (i32) -> i29
    %11 = comb.concat %c0_i3, %10 : i3, i29
    %12 = comb.add %11, %step : i32
    %13 = comb.mux %1, %12, %11 : i32
    %14 = comb.add %13, %7 : i32
    %15 = comb.mux %3, %14, %13 : i32
    %16 = comb.add %15, %9 : i32
    %17 = comb.mux %5, %16, %15 {sv.namehint = "out3"} : i32
    func.return %17 : i32
  }
}
