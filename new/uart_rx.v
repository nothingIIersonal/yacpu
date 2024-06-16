`timescale 1ns / 1ps


module uart_rx
#
(
    parameter CLK_RATE_MHz =    100,
    parameter DATA_WIDTH   =      8,
    parameter BAUDRATE     =  57600
)
(
    input  wire                        in_clk,

    input  wire                        in_data,

    output reg   [DATA_WIDTH - 1: 0]   out_data_reg,
    output reg                         out_done_reg
);


endmodule
