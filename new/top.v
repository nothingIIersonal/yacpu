`timescale 1ns / 1ps


`include "parameters.vh"


module top
(
    input  wire in_CLK,

    input  wire in_UART_RX,  // from TX to MCU
    output wire out_UART_TX  // from MCU to RX
);


    wire system_en;
    wire system_clk;
    wire system_rst;


// PERIPHERAL_CONTROLLER
    peripheral_controller_mem
    peripheral_controller_mem_inst
    (
        .in_clk  ( system_clk ),
        .out_en  ( system_en  ),
        .out_rst ( system_rst )
    );
//// PERIPHERAL_CONTROLLER


// ENABLE_PROTECTOR
    enable_protector
    enable_protector_inst
    (
        .in_clk  ( in_CLK     ),
        .in_en   ( system_en  ),
        .out_clk ( system_clk )
    );
//// ENABLE_PROTECTOR


// CPU
    cpu
    cpu_inst
    (
        .in_clk ( system_clk ),
        .in_rst ( system_rst )
    );
//// CPU


// GPU
    gpu
    gpu_inst
    (
        .in_clk ( system_clk ),
        .in_rst ( system_rst )
    );
//// GPU


// DATA_MEM
    memory #(
        .WORD_WIDTH ( DATA_MEM_WORD_WIDTH ),
        .CAPACITY   ( DATA_MEM_CAPACITY   )
    )
    data_mem_inst
    (
        .in_clk ( system_clk )
    );
//// DATA_MEM


// STACK_MEM
    memory #(
        .WORD_WIDTH ( STACK_MEM_WORD_WIDTH ),
        .CAPACITY   ( STACK_MEM_CAPACITY   )
    )
    stack_mem_inst
    (
        .in_clk ( system_clk )
    );
//// STACK_MEM


// PROGRAM_MEM
    memory #(
        .WORD_WIDTH ( PROGRAM_MEM_WORD_WIDTH ),
        .CAPACITY   ( PROGRAM_MEM_CAPACITY   )
    )
    program_mem_inst
    (
        // global
        .in_clk               ( system_clk ),
        .in_rst               ( system_rst )

        // read
        .in_read_addr         ( ),
        .in_read_ready        ( ),
        .out_data_reg         ( ),
        .out_data_ready_reg   ( ),

        // write
        .in_write_addr        ( ),
        .in_write_data        ( ),
        .in_write_ready       ( ),
        .out_write_ready_reg  ( )
    );
//// PROGRAM_MEM


endmodule
