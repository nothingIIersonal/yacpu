`timescale 1ns / 1ps


module uart
#
(
    parameter RX_CLK_RATE_MHz =  100,
    parameter TX_CLK_RATE_MHz =  100,
    parameter RX_DATA_WIDTH   =    8,
    parameter TX_DATA_WIDTH   =    8,
    parameter RX_BAUDRATE     = 9600,
    parameter TX_BAUDRATE     = 9600,
    parameter RX_BUFFER_SIZE  =   32
)
(
    input  wire                         in_clk,
    input  wire                         in_rst,

    input  wire                         in_rx_en,
    input  wire                         in_rx_data,
    input  wire                         in_rx_read,
    output wire                         out_rx_empty,
    output wire                         out_rx_full,
    output wire  [RX_DATA_WIDTH - 1: 0] out_rx_data,
    output wire                         out_rx_done,

    input  wire                         in_tx_en,
    input  wire                         in_tx_start,
    input  wire  [TX_DATA_WIDTH - 1: 0] in_tx_data,
    output wire                         out_tx_data,
    output wire                         out_tx_done
);

    wire [RX_DATA_WIDTH - 1: 0] rx_data;

    uart_rx
    #
    (
        .CLK_RATE_MHz ( RX_CLK_RATE_MHz ),
        .DATA_WIDTH   ( RX_DATA_WIDTH   ),
        .BAUDRATE     ( RX_BAUDRATE     )
    )
    uart_rx_inst
    (
        .in_clk       ( in_clk          ),
        .in_rst       ( in_rst          ),
        .in_en        ( in_rx_en        ),
        .in_data      ( in_rx_data      ),

        .out_data_reg ( rx_data         ),
        .out_done_reg ( out_rx_done     )
    );

    fifo_buffer #(
        .DATA_WIDTH ( RX_DATA_WIDTH  ),
        .FIFO_SIZE  ( RX_BUFFER_SIZE )
    )
    fifo_buffer_inst
    (
        .in_clk     ( in_clk         ),
        .in_clke    ( 1'b1           ),
        .in_rst     ( in_rst         ),
        .in_en      ( 1'b1           ),
        .in_read    ( in_rx_read     ),
        .in_write   ( out_rx_done    ),
        .in_data    ( rx_data        ),
        .out_empty  ( out_rx_empty   ),
        .out_full   ( out_rx_full    ),
        .out_data   ( out_rx_data    )
    );

    uart_tx
    #
    (
        .CLK_RATE_MHz ( TX_CLK_RATE_MHz ),
        .DATA_WIDTH   ( TX_DATA_WIDTH   ),
        .BAUDRATE     ( TX_BAUDRATE     )
    )
    uart_tx_inst
    (
        .in_clk       ( in_clk          ),
        .in_rst       ( in_rst          ),
        .in_en        ( in_tx_en        ),
        .in_start     ( in_tx_start     ),
        .in_data      ( in_tx_data      ),

        .out_data_reg ( out_tx_data     ),
        .out_done_reg ( out_tx_done     )
    );

endmodule
