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
 * UART RX module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 * Designer : Glazunov  N. M. (https://github.com/nikikust        )
 *
 */



module uart_rx
#
(
    parameter CLK_RATE_MHz      =   100,
    parameter DATA_WIDTH        =     8,
    parameter CLK_COUNTER_WIDTH =    14,
    parameter COUNTER_REG_WIDTH =     4,
    parameter CLK_COUNTER_INV   = 10416,
    parameter BOUDRATE          =  9600
)
(
    input  wire                        clk_in,
    input  wire                        rst_in,

    input  wire                        rx_en_in,

    input  wire                        rx_in,

    output reg  [DATA_WIDTH - 1: 0]    rxdata_out,
    output reg                         done_receive_out
);

    reg [1: 0]                     state_reg;

    reg [DATA_WIDTH - 1: 0]        rxdata_temp;

    reg [COUNTER_REG_WIDTH: 0]     counter_reg;
    reg [CLK_COUNTER_WIDTH: 0]     clk_counter;

    reg                            rx_en_in_reg;
    reg                            rx_en_in_flag_reg;
    reg                            rx_initialization_reg;

    reg                            clk_rx_half;


    localparam // states
        WAIT_PACKET     = 3'h0,
        PROCESS_PACKET  = 3'h1,
        DONE_PACKET     = 3'h2;


    initial
    begin
        state_reg             <= WAIT_PACKET;

        counter_reg           <= {COUNTER_REG_WIDTH + 1'b1{1'b0}};
        clk_counter           <= {CLK_COUNTER_WIDTH + 1'b1{1'b0}};

        rx_en_in_reg          <= 1'b0;
        rx_en_in_flag_reg     <= 1'b0;
        rx_initialization_reg <= 1'b1;

        clk_rx_half           <= 1'b0;

        rxdata_out            <= {DATA_WIDTH{1'b0}};
        rxdata_temp           <= {DATA_WIDTH{1'b0}};
        done_receive_out      <= 1'b0;
    end


    always @(posedge clk_in)
    begin
        ////
        // Process enable and stop receive signals
        if (rx_en_in && done_receive_out) begin
            rx_en_in_reg     <= 1'b1;
            done_receive_out <= (state_reg == DONE_PACKET &&
                                 clk_rx_half              &&
                                 rx_in                      ) ? 1'b1 : 1'b0;
        end else if (rx_en_in_flag_reg) begin
            rx_en_in_reg      <= 1'b0;
            rx_en_in_flag_reg <= (state_reg == DONE_PACKET &&
                                  clk_rx_half              &&
                                  rx_in                      ) ? 1'b1 : 1'b0;
        end
        ////


        if (!rst_in) begin
            ////
            // Generate RX clock
            if (clk_counter < CLK_COUNTER_INV) begin
                if (clk_counter == (CLK_COUNTER_INV / 2)) begin
                    clk_rx_half <= 1'b1;
                end else begin
                    clk_rx_half <= 1'b0;
                end

                clk_counter     <= clk_counter + {{CLK_COUNTER_WIDTH{1'b0}}, 1'b1};
            end else begin
                clk_counter     <= {CLK_COUNTER_WIDTH + 1'b1{1'b0}};
            end
            ////

            ////
            // Receive data process
            if (clk_rx_half) begin
                case (state_reg)
                    WAIT_PACKET: begin
                        if (rx_in == 1'b0) begin
                            state_reg     <= PROCESS_PACKET;
                        end
                    end
                    PROCESS_PACKET: begin
                        rxdata_temp       <= {rx_in, rxdata_temp[DATA_WIDTH - 1: 1]};

                        if (counter_reg < DATA_WIDTH - 1) begin
                            counter_reg   <= counter_reg + {{COUNTER_REG_WIDTH{1'b0}}, 1'b1};
                        end else begin
                            state_reg     <= DONE_PACKET;
                            counter_reg   <= {COUNTER_REG_WIDTH + 1'b1{1'b0}};
                        end
                    end
                    DONE_PACKET: begin
                        if (rx_in == 1'b1) begin
                            state_reg                 <= WAIT_PACKET;

                            if (rx_initialization_reg) begin
                                rxdata_out            <= rxdata_temp;
                                done_receive_out      <= 1'b1;
                                rx_initialization_reg <= 1'b0;
                            end else if (~rx_en_in && rx_en_in_reg) begin
                                rxdata_out            <= rxdata_temp;
                                rx_en_in_flag_reg     <= 1'b1;
                                done_receive_out      <= 1'b1;
                            end else if (rx_en_in) begin
                                rxdata_out            <= rxdata_temp;
                                rx_en_in_flag_reg     <= 1'b1;
                            end
                        end
                    end
                endcase
            end
            ////
        end else begin
            state_reg             <= WAIT_PACKET;

            counter_reg           <= {COUNTER_REG_WIDTH + 1'b1{1'b0}};
            clk_counter           <= {CLK_COUNTER_WIDTH + 1'b1{1'b0}};

            rx_en_in_reg          <= 1'b0;
            rx_en_in_flag_reg     <= 1'b0;
            rx_initialization_reg <= 1'b1;

            clk_rx_half           <= 1'b0;

            rxdata_out            <= {DATA_WIDTH{1'b0}};
            rxdata_temp           <= {DATA_WIDTH{1'b0}};
            done_receive_out      <= 1'b0;
        end
    end

endmodule
