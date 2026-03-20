module MulSel #(
    parameter BW = 32
) 
(
    input logic [BW-1:0] a,
    input logic [BW-1:0] b,
    input logic [BW-1:0] c,
    input logic s,
    output logic [2*BW - 1:0] out
);  

assign out = s ? a * b : a * c;

endmodule