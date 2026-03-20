module ShiftedFma #(
    parameter BW = 32
)  // Parameterized width for the multiplier
(
    input logic [BW-1:0] a,
    input logic [BW-1:0] b,
    input logic [$clog2(BW)-1:0] s,
    input logic [2*BW-1:0] c,
    output logic [2*BW:0] out
);  

wire [ 2*BW : 0 ] d, e;
wire [$clog2(BW):0] sum;

assign d = a * b;
assign e = d << s;
assign out = e + c;

// Optimized
// assign d = (a << s);
// assign e = d * b;
// assign out = e + c;

endmodule