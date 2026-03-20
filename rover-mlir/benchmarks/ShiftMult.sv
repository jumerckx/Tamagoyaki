module ShiftMult #(
    parameter BW = 32
)  // Parameterized width for the multiplier
(
    input logic [BW-1:0] a,
    input logic [BW-1:0] b,
    input logic [$clog2(BW)-1:0] m,
    input logic [$clog2(BW)-1:0] n,
    output logic [2*BW-1:0] out
);  

wire [ 2*BW - 1 : 0 ] d, e;
wire [$clog2(BW):0] sum;

assign d = a << m;
assign e = b << n;
assign out = d * e;

// Optimized
// assign d = a * b;
// assign sum = m+n;
// assign out = d << sum;
endmodule