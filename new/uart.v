`timescale 1ns / 1ps


module uart
(
    input  wire in_clk
);


// UART_RX
    uart_rx
    uart_rx_inst
    (
        in_clk ( in_clk )
    );
//// UART_RX


// UART_TX
    uart_tx
    uart_tx_inst
    (
        in_clk ( in_clk )
    );
//// UART_TX


endmodule
