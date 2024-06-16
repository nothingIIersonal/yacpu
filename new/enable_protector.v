`timescale 1ns / 1ps


module enable_protector
(
    input  wire in_clk,
    input  wire in_en,
    output wire out_clk
)


    assign out_clk = in_en ? in_clk : 1'b0;


endmodule
