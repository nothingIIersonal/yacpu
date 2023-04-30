/*
 * Copyright (C) 2022 nothingIIersonal.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */



`timescale 1ns / 1ps



/*
 *   __     __      __  __  _____ _    _ 
 *   \ \   / //\   |  \/  |/ ____| |  | |
 *    \ \_/ //  \  | \  / | |    | |  | |
 *     \   // /\ \ | |\/| | |    | |  | |
 *      | |/ ____ \| |  | | |____| |__| |
 *      |_/_/    \_\_|  |_|\_____|\____/ 
 *
 *
 * Top MCU module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 * Designer : Glazunov  N. M. (https://github.com/nikikust        )
 *
 *
 *               Laboratory work No. 6 on the subject
 *               "Circuitry of computer devices and systems"
 *               
 *               Tested on Digilent Nexys A7 board
 *
 *               RTU MIREA,
 *               Institute of Information Technologies,
 *               Department of Computer Engineering.
 *
 */



// `define DEBUG
`define SEVEN_SEGMENT_USE


`define SYSTEM_CLOCK_MHz                                 100


`ifndef DEBUG
    `define DEBOUNCE_SYNC_REG_SIZE                        16
    `define DEBOUNCE_COUNTER_M                         65536
`else
    `define DEBOUNCE_SYNC_REG_SIZE                         2
    `define DEBOUNCE_COUNTER_M                             4
`endif


`ifdef SEVEN_SEGMENT_USE
    `define SEVEN_SEGMENT_COUNT                            8
    `define SEVEN_SEGMENT_USED                             8
    `define SEVEN_SEGMENT_MASK        `SEVEN_SEGMENT_COUNT - `SEVEN_SEGMENT_USED          \
                                      ?                                                   \
                                    {{`SEVEN_SEGMENT_COUNT - `SEVEN_SEGMENT_USED{1'b1}},  \
                                                             {`SEVEN_SEGMENT_USED{1'b0}}} \
                                      :                                                   \
                                      {`SEVEN_SEGMENT_COUNT{1'b0}}
`endif


`define TX_CLK_RATE_MHz                    `SYSTEM_CLOCK_MHz
`define RX_CLK_RATE_MHz                    `SYSTEM_CLOCK_MHz
`define TX_DATA_WIDTH                                      8
`define RX_DATA_WIDTH                                      8
`define BOUDRATE                                        9600


module top
(
    input  wire                                CLK_100MHz_in,
    input  wire                                RST_in,          // Button: CPU_RESETN
    input  wire                                FLASH_ENABLE_in, // Button: BTNL

    input  wire                                UART_TXD_in,     // from TX to MCU
    output wire                                UART_RXD_out,    // from MCU to RX

`ifdef SEVEN_SEGMENT_USE
    output wire  [`SEVEN_SEGMENT_COUNT - 1: 0] AN,
    output wire  [7: 0]                        SEG,
`endif

    output reg                                 cpu_working_out, // LED: LED16_G
    output reg                                 cpu_flashing_out // LED: LED16_R
);

    reg                                     rst_debounce_delayed;
    reg                                     flash_debounce_delayed;


    wire                                    rst_debounce;

    wire                                    flash_debounce;
    wire                                    flash_clk;
    wire                                    flash_signal;
    wire [$clog2(`PROGRAM_MEM_SIZE) - 1: 0] flash_mem_addr;
    wire [`COMMAND_WIDTH - 1: 0]            flash_command;

    wire                                    cpu_en;

    wire                                    uart_transmitted;
    wire                                    uart_receive;
    wire  [`TX_DATA_WIDTH - 1: 0]           uart_txdata;
    wire                                    uart_transmit;
    wire                                    uart_received_uart_programmer;
    wire                                    uart_received_cpu;
    wire  [`RX_DATA_WIDTH - 1: 0]           uart_rxdata;

`ifdef SEVEN_SEGMENT_USE
    wire  [`SEVEN_SEGMENT_USED * 4 - 1: 0]  seven_seg_value = flash_command;
`endif


    initial
    begin
        rst_debounce_delayed   <= 1'b0;
        flash_debounce_delayed <= 1'b0;
        cpu_working_out        <= 1'b0;
        cpu_flashing_out       <= 1'b0;
    end


    always @(posedge CLK_100MHz_in) rst_debounce_delayed   <= rst_debounce;
    always @(posedge CLK_100MHz_in) flash_debounce_delayed <= flash_debounce;


    always @(*)
    begin
        cpu_working_out  <=  cpu_en ? 1'b1 : 1'b0;
        cpu_flashing_out <= ~cpu_en ? 1'b1 : 1'b0;
    end


    uart_programmer
    #
    (
        .RX_DATA_WIDTH ( `RX_DATA_WIDTH )
    )
    uart_programmer_inst
    (
        .CLK_100MHz_in             ( CLK_100MHz_in                 ), // in
        .rst_in                    ( rst_debounce                  ), // in
        .flash_enable_in           ( flash_debounce                ), // in

        /*
            UART RX -> UART Programmer
        */
        .uart_receive_in           ( uart_receive                  ), // in
        .uart_rxdata_in            ( uart_rxdata                   ), // in

        /*
            UART Programmer -> UART RX
        */
        .uart_received_reg_out     ( uart_received_uart_programmer ), // out

        /*
            UART Programmer -> CPU
        */
        .flash_clk_out             ( flash_clk                     ), // out
        .flash_command_reg_out     ( flash_command                 ), // out
        .flash_signal_reg_out      ( flash_signal                  ), // out
        .flash_mem_addr_reg_out    ( flash_mem_addr                ), // out
        .cpu_en_reg_out            ( cpu_en                        )  // out
    );



    cpu_core
    cpu_core_inst
    (
        .CLK_100MHz_in         ( CLK_100MHz_in & cpu_en                           ), // in
        .cpu_reset_in          ( rst_debounce_delayed | flash_debounce_delayed    ), // in

        /*
            UART Programmer -> CPU
        */
        .flash_clk_in          ( flash_clk                                        ), // in
        .flash_command_in      ( flash_command                                    ), // in
        .flash_signal_in       ( flash_signal                                     ), // in
        .flash_mem_addr_in     ( flash_mem_addr                                   ), // in

        /*
            UART -> CPU
        */
        .uart_transmitted_in   ( uart_transmitted                                 ), // in
        .uart_receive_in       ( uart_receive                                     ), // in
        .uart_data_in          ( uart_rxdata                                      ), // in

        /*
            CPU -> UART
        */
        .uart_transmit_out     ( uart_transmit                                    ), // out
        .uart_received_out     ( uart_received_cpu                                ), // out
        .uart_data_out         ( uart_txdata                                      )  // out
    );



    uart
    #
    (
        .TX_CLK_RATE_MHz ( `TX_CLK_RATE_MHz ),
        .RX_CLK_RATE_MHz ( `RX_CLK_RATE_MHz ),
        .TX_DATA_WIDTH   ( `TX_DATA_WIDTH   ),
        .RX_DATA_WIDTH   ( `RX_DATA_WIDTH   ),
        .BOUDRATE        ( `BOUDRATE        )
    )
    uart_inst
    (
        .clk_in            ( CLK_100MHz_in                                              ), // in
        .rst_in            ( rst_debounce                                               ), // in

        /*
            Enable signals
        */
        .tx_en_in          ( uart_transmit                                              ), // in
        .rx_en_in          ( cpu_en ? uart_received_cpu : uart_received_uart_programmer ), // in

        /*
            TX
        */
        .txdata_in         ( uart_txdata                                                ), // in
        .tx_out            ( UART_RXD_out                                               ), // out
        .done_transmit_out ( uart_transmitted                                           ), // out

        /*
            RX
        */
        .rx_in             ( UART_TXD_in                                                ), // in 
        .rxdata_out        ( uart_rxdata                                                ), // out
        .done_receive_out  ( uart_receive                                               )  // out
    );


`ifdef SEVEN_SEGMENT_USE

    `define SEVEN_SEGMENT_DIVIDER_VALUE (`SYSTEM_CLOCK_MHz * 1000000 / 1000)


    reg                                               clke_seven_segment_reg        = 1'b0;
    reg [$clog2(`SEVEN_SEGMENT_DIVIDER_VALUE) - 1: 0] clk_seven_segment_counter_reg = {$clog2(`SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}};


    always @(posedge CLK_100MHz_in)
    begin
        clk_seven_segment_counter_reg <= clk_seven_segment_counter_reg == (`SEVEN_SEGMENT_DIVIDER_VALUE - 1)
                                         ?
                                         {$clog2(`SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}}
                                         :
                                         clk_seven_segment_counter_reg + {{$clog2(`SEVEN_SEGMENT_DIVIDER_VALUE) - 1{1'b0}}, 1'b1};
        clke_seven_segment_reg        <= !clk_seven_segment_counter_reg
                                         ?
                                         1'b1
                                         :
                                         1'b0;
    end


    seven_seg_controller
    #
    (
        .SEVEN_SEGMENT_COUNT ( `SEVEN_SEGMENT_COUNT )
    )
    seven_seg_controller_inst
    (
        .clk_in      ( CLK_100MHz_in          ),
        .clke_in     ( clke_seven_segment_reg ),
        .rst_in      ( 1'b0                   ),
        .mask_in     ( `SEVEN_SEGMENT_MASK    ),
        .value_in    ( seven_seg_value        ),
        .anodes_out  ( AN                     ),
        .seg_reg_out ( SEG                    )
    );

`endif


    ////
    // debouncers
    debounce
    #
    (
        .SYNC_REG_SIZE ( `DEBOUNCE_SYNC_REG_SIZE ),
        .COUNTER_M     ( `DEBOUNCE_COUNTER_M     )
    )
    debounce_R_inst
    (
        .clk_in                 ( CLK_100MHz_in   ), // in
        .rst_in                 ( 1'b0            ), // in
        .signal_in              ( RST_in          ), // in

        .signal_out_reg         ( /* NOT USED */  ), // out
        .signal_out_enable_reg  ( rst_debounce    )  // out
    );
    //
    debounce
    #
    (
        .SYNC_REG_SIZE ( `DEBOUNCE_SYNC_REG_SIZE ),
        .COUNTER_M     ( `DEBOUNCE_COUNTER_M     )
    )
    debounce_L_inst
    (
        .clk_in                 ( CLK_100MHz_in   ), // in
        .rst_in                 ( 1'b0            ), // in
        .signal_in              ( FLASH_ENABLE_in ), // in

        .signal_out_reg         ( /* NOT USED */  ), // out
        .signal_out_enable_reg  ( flash_debounce  )  // out
    );
    ////

endmodule
