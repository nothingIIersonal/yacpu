`timescale 1ns / 1ps


`include "cpu_core_parameters.vh" 


`define DEBUG

`define SYSTEM_CLOCK_MHz            100

`define DEBOUNCE_SYNC_REG_WIDTH     16
`define DEBOUNCE_COUNTER_M          65536

`define RX_CLK_RATE_MHz             `SYSTEM_CLOCK_MHz
`define TX_CLK_RATE_MHz             `SYSTEM_CLOCK_MHz
`define RX_BUFFER_SIZE              32
`define BAUDRATE                    9600


module top
(
    input  wire                                in_CLK,
    input  wire                                in_RST,             // Button: CPU_RESETN (Nexys 7), PIN88 (Tang Nano 20K)
    input  wire                                in_FLASH,           // Button: BTNL (Nexys 7), PIN87 (Tang Nano 20K)

    input  wire                                in_UART_TXD,        // from TX to MCU
    output wire                                out_UART_RXD        // from MCU to RX
);

`ifndef DEBUG
    wire                                     rst_debounce;
    wire                                     flash_debounce;
`else
    wire                                     rst_debounce   = in_RST;
    wire                                     flash_debounce = in_FLASH;
`endif

    wire [`COMMAND_WIDTH - 1: 0]             cpu_flash_command;
    wire                                     cpu_flash_signal;
    wire [$clog2(`PROGRAM_MEM_SIZE) - 1: 0]  cpu_flash_mem_addr;

    wire                                     cpu_en;
    wire                                     cpu_rst;

    wire                                     cpu_uart_rx_read;
    wire                                     uprog_uart_rx_read;
    wire [`UART_RXTX_WIDTH - 1: 0]           uart_rx_data;
    wire                                     uart_rx_empty;

    wire                                     uart_tx_start;
    wire [`UART_RXTX_WIDTH - 1: 0]           uart_tx_data;
    wire                                     uart_tx_done;


    cpu_core
    cpu_core_inst
    (
        .in_clk             ( in_CLK             ),
        .in_clke            ( 1'b1               ),
        .in_rst             ( cpu_rst            ),
        .in_en              ( cpu_en             ),

        .in_flash_command   ( cpu_flash_command  ),
        .in_flash_signal    ( cpu_flash_signal   ),
        .in_flash_mem_addr  ( cpu_flash_mem_addr ),

        .out_uart_rx_read   ( cpu_uart_rx_read   ),
        .in_uart_rx_empty   ( uart_rx_empty      ),
        .in_uart_rx_data    ( uart_rx_data       ),

        .out_uart_tx_start  ( uart_tx_start      ),
        .out_uart_tx_data   ( uart_tx_data       ),
        .in_uart_tx_done    ( uart_tx_done       )
    );


    uart #(
        .RX_CLK_RATE_MHz ( `RX_CLK_RATE_MHz ),
        .TX_CLK_RATE_MHz ( `TX_CLK_RATE_MHz ),
        .RX_DATA_WIDTH   ( `UART_RXTX_WIDTH ),
        .TX_DATA_WIDTH   ( `UART_RXTX_WIDTH ),
        .RX_BAUDRATE     ( `BAUDRATE        ),
        .TX_BAUDRATE     ( `BAUDRATE        ),
        .RX_BUFFER_SIZE  ( `RX_BUFFER_SIZE  )
    )
    uart_inst
    (
        .in_clk        ( in_CLK                                         ),
        .in_rst        ( rst_debounce                                   ),

        .in_rx_en      ( 1'b1                                           ),
        .in_rx_data    ( in_UART_TXD                                    ),
        .in_rx_read    ( cpu_en ? cpu_uart_rx_read : uprog_uart_rx_read ),
        .out_rx_empty  ( uart_rx_empty                                  ),
        .out_rx_full   ( /* NOT USED */                                 ),
        .out_rx_data   ( uart_rx_data                                   ),
        .out_rx_done   ( /* NOT USED */                                 ),

        .in_tx_en      ( 1'b1                                           ),
        .in_tx_start   ( uart_tx_start                                  ),
        .in_tx_data    ( uart_tx_data                                   ),
        .out_tx_data   ( out_UART_RXD                                   ),
        .out_tx_done   ( uart_tx_done                                   )
    );


    uart_programmer #(
        .RX_DATA_WIDTH ( `UART_RXTX_WIDTH )
    )
    uart_programmer_inst
    (
        .in_clk                  ( in_CLK             ),
        .in_clke                 ( 1'b1               ),
        .in_rst                  ( rst_debounce       ),

        .in_flash                ( flash_debounce     ),

        .in_uart_rx_empty        ( uart_rx_empty      ),
        .in_uart_rx_data         ( uart_rx_data       ),

        .out_uart_rx_read        ( uprog_uart_rx_read ),

        .out_cpu_en_reg          ( cpu_en             ),
        .out_cpu_rst_reg         ( cpu_rst            ),

        .out_flash_command_reg   ( cpu_flash_command  ),
        .out_flash_signal_reg    ( cpu_flash_signal   ),
        .out_flash_mem_addr_reg  ( cpu_flash_mem_addr )
    );


`ifndef DEBUG
    debounce #(
        .SYNC_REG_WIDTH  ( `DEBOUNCE_SYNC_REG_WIDTH ),
        .COUNTER_M       ( `DEBOUNCE_COUNTER_M      )
    )
    debounce_RST_inst
    (
        .in_clk                 ( in_CLK         ),
        .in_clke                ( 1'b1           ),
        .in_rst                 ( 1'b0           ),
        .in_en                  ( 1'b1           ),
        .in_signal              ( in_RST         ),

        .out_signal_reg         ( /* NOT USED */ ),
        .out_signal_enable_reg  ( rst_debounce   )
    );

    debounce #(
        .SYNC_REG_WIDTH  ( `DEBOUNCE_SYNC_REG_WIDTH ),
        .COUNTER_M       ( `DEBOUNCE_COUNTER_M      )
    )
    debounce_FLASH_inst
    (
        .in_clk                 ( in_CLK         ),
        .in_clke                ( 1'b1           ),
        .in_rst                 ( 1'b0           ),
        .in_en                  ( 1'b1           ),
        .in_signal              ( in_FLASH       ),

        .out_signal_reg         ( /* NOT USED */ ),
        .out_signal_enable_reg  ( flash_debounce )
    );
`endif

endmodule
