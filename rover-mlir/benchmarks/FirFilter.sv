module FirFilter #(
    parameter BW = 32
) 
(
    input logic [BW-1:0] z1,
    input logic [BW-1:0] z2,
    input logic [BW-1:0] z3,
    input logic [BW-1:0] z4,
    input logic [BW-1:0] add0,
    input logic [$clog2(BW)-1:0] s,
    output logic [BW - 1:0] out
);  


logic [BW -1 : 0] add1;
logic [BW -1 : 0] add2;
logic [BW -1 : 0] add3;
logic [BW -1 : 0] add4;

assign add1 = (add0 + z1) >> s;
assign add2 = (add1 + z2) >> s;
assign add3 = (add2 + z3) >> s;
assign add4 = (add3 + z4);
assign out = add4;

endmodule