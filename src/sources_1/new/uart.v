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
 * UART module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 * Designer : Glazunov  N. M. (https://github.com/nikikust        )
 *
 */



module uart
#
(
    parameter TX_CLK_RATE_MHz =  100,
    parameter RX_CLK_RATE_MHz =  100,
    parameter TX_DATA_WIDTH   =    8,
    parameter RX_DATA_WIDTH   =    8,
    parameter BOUDRATE        = 9600
)
(
    input  wire                        clk_in,
    input  wire                        rst_in,

    /*
        Enable signals
    */
    input  wire                        tx_en_in,
    input  wire                        rx_en_in,

    /*
        TX
    */
    input  wire [TX_DATA_WIDTH - 1: 0] txdata_in,
    output wire                        tx_out,
    output wire                        done_transmit_out,

    /*
        RX
    */
    input  wire                        rx_in,
    output wire [RX_DATA_WIDTH - 1: 0] rxdata_out,
    output wire                        done_receive_out
);

    localparam rx_clk_counter_width = $clog2(RX_CLK_RATE_MHz * 1000000 / BOUDRATE);
    localparam tx_clk_counter_width = $clog2(TX_CLK_RATE_MHz * 1000000 / BOUDRATE);
    localparam rx_counter_reg_width = $clog2(RX_DATA_WIDTH);
    localparam tx_counter_reg_width = $clog2(TX_DATA_WIDTH);
    localparam rx_clk_counter_inv   = RX_CLK_RATE_MHz * 1000000 / BOUDRATE;
    localparam tx_clk_counter_inv   = TX_CLK_RATE_MHz * 1000000 / BOUDRATE;


    uart_rx
    #
    (
        .CLK_RATE_MHz      ( RX_CLK_RATE_MHz * 1000000 ),
        .DATA_WIDTH        ( RX_DATA_WIDTH             ),
        .CLK_COUNTER_WIDTH ( rx_clk_counter_width      ),
        .COUNTER_REG_WIDTH ( rx_counter_reg_width      ),
        .CLK_COUNTER_INV   ( rx_clk_counter_inv        ),
        .BOUDRATE          ( BOUDRATE                  )
    )
    uart_rx_inst
    (
        .clk_in            ( clk_in           ), // in
        .rst_in            ( rst_in           ), // in

        .rx_en_in          ( rx_en_in         ), // in
        .rx_in             ( rx_in            ), // in
        .rxdata_out        ( rxdata_out       ), // out
        .done_receive_out  ( done_receive_out )  // out
    );


    uart_tx
    #
    (
        .CLK_RATE_MHz      ( TX_CLK_RATE_MHz * 1000000 ),
        .DATA_WIDTH        ( TX_DATA_WIDTH             ),
        .CLK_COUNTER_WIDTH ( tx_clk_counter_width      ),
        .COUNTER_REG_WIDTH ( tx_counter_reg_width      ),
        .CLK_COUNTER_INV   ( tx_clk_counter_inv        ),
        .BOUDRATE          ( BOUDRATE                  )
    )
    uart_tx_inst
    (
        .clk_in            ( clk_in            ), // in
        .rst_in            ( rst_in            ), // in

        .tx_en_in          ( tx_en_in          ), // in
        .txdata_in         ( txdata_in         ), // in
        .tx_out            ( tx_out            ), // out
        .done_transmit_out ( done_transmit_out )  // out
    );

endmodule
