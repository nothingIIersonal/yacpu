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
 * Testbench module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 *
 */



module testbench();

    localparam CLK_PERIOD = 20;


    reg           clk;
    reg           rst;
    reg           flash;

    reg   [3: 0]  i;
    reg   [13: 0] clk_counter;

    reg           clk_uart_half;
    reg           uart_tx_in;

    wire          uart_rx_out;


    localparam
        N_0            = 8'h00,
        N_1            = 8'h01,
        N_2            = 8'h02,
        N_3            = 8'h03,
        N_4            = 8'h04,
        N_5            = 8'h05,
        N_6            = 8'h06,
        N_7            = 8'h07,
        N_8            = 8'h08,
        N_9            = 8'h09,
        cmd_1_1        = 8'h08,
        cmd_1_2        = 8'hff,
        cmd_1_3        = 8'h00,
        cmd_1_4        = 8'h00,
        cmd_2_1        = 8'h09,
        cmd_2_2        = 8'h02,
        cmd_2_3        = 8'h00,
        cmd_2_4        = 8'h00,
        cmd_3_1        = 8'h42,
        cmd_3_2        = 8'h20,
        cmd_3_3        = 8'h00,
        cmd_3_4        = 8'h00,
        cmd_4_1        = 8'h90,
        cmd_4_2        = 8'h0c,
        cmd_4_3        = 8'h00,
        cmd_4_4        = 8'h00,
        cmd_stop       = 8'hFF;


    initial
    begin
        clk = 1'b0;
        rst = 1'b0;
        flash = 1'b0;
        uart_tx_in = 1'b1;
        clk_uart_half = 1'b0;
        clk_counter   = 14'h0000;

        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);
        #(20000 * CLK_PERIOD);


        // uart_tx_in    = 1'b1;
        
        // clk           = 1'b0;
        // clk_uart_half = 1'b0;

        // clk_counter   = 14'h0000;
        // flash         = 1'b0;

        // rst           = 1'b0;
        // #(2*CLK_PERIOD);
        // rst           = 1'b1;
        // #(30*CLK_PERIOD);
        // rst           = 1'b0;

        // flash         = 1'b1;
        // #(30*CLK_PERIOD);
        // flash         = 1'b0;


        // #(70000*CLK_PERIOD);


        // UART_data_gen(cmd_1_1);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_1_2);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_1_3);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_1_4);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_2_1);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_2_2);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_2_3);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_2_4);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_3_1);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_3_2);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_3_3);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_3_4);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_4_1);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_4_2);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_4_3);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_4_4);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_stop);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_stop);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_stop);
        // #(250000*CLK_PERIOD);
        // UART_data_gen(cmd_stop);
        // #(250000*CLK_PERIOD);


        // #(10000*CLK_PERIOD);
        // rst           = 1'b1;
        // #(3000*CLK_PERIOD);
        // rst           = 1'b0;
        // #(3000*CLK_PERIOD);
        // flash         = 1'b1;
        // #(30*CLK_PERIOD);
        // flash         = 1'b0;
        // #(1000*CLK_PERIOD);
        // rst           = 1'b1;
        // #(3000*CLK_PERIOD);
        // rst           = 1'b0;
        // #(70000*CLK_PERIOD);


        $finish;
    end


    always #10 clk <= ~clk;


    always @(posedge clk)
    begin
        if (clk_counter < 14'd10416) begin
            clk_counter   <= clk_counter + 14'h1;
            clk_uart_half <= 1'b0;
        end else begin
            clk_counter   <= 14'h0000;
            clk_uart_half <= 1'b1;
        end
    end


    task automatic UART_data_gen
    (
        input [7:0] code
    );
        begin
            @(posedge clk_uart_half) begin
                uart_tx_in     <= 0;
            end

            for (i = 0; i < 8; i = i + 1) begin
                @(posedge clk_uart_half) begin
                    uart_tx_in <= code[i];
                end
            end

            @(posedge clk_uart_half) begin
                uart_tx_in     <= 1;
            end
        end
    endtask


    always #10 clk <= ~clk;


    top
    top_inst
    (
        .CLK_100MHz_in    ( clk          ),
        .RST_in           ( rst          ),
        .FLASH_ENABLE_in  ( flash        ),

        .UART_TXD_in      ( uart_tx_in   ),
        .UART_RXD_out     ( uart_rx_out  ),

        .AN               (              ),
        .SEG              (              ),
        .cpu_working_out  (              ),
        .cpu_flashing_out (              )
    );

endmodule
