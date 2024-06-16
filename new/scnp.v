`timescale 1ns / 1ps


module scnp
(
    input  wire in_clk,
    output reg  out_en
);


    uart
    uart_inst
    (
        in_clk ( in_clk )
    )


endmodule
