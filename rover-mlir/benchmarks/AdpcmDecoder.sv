module AdpcmDecoder #(
    parameter BW = 32
)( 
    input  logic [BW-1:0] step,
    input  logic [BW-1:0] delta,
    output logic [BW-1:0] vpdiff
);


wire [BW - 1 : 0] div1, div2, div3;
wire [BW - 1 : 0] out1, out2, out3;
wire [2:0] delta7;
logic sel1, sel2, sel3;

assign delta7 = delta & 3'd7;


assign sel1 = (delta7 & 3'd4) == 0;
assign sel2 = (delta7 & 2'd2) == 0;
assign sel3 = (delta7 & 1'd1) == 0;

assign div1 = (step >> 1'd1);
assign div2 = (step >> 2'd2);
assign div3 = (step >> 3'd3);

assign out1 = sel1 ? div3 + step : div3;
assign out2 = sel2 ? out1 + div1 : out1;
assign out3 = sel3 ? out2 + div2 : out2;

assign vpdiff = out3;

// Optimised Version


endmodule