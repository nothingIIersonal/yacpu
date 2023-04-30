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
 * UART Programmer module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 * Designer : Glazunov  N. M. (https://github.com/nikikust        )
 *
 */



module uart_programmer
#
(
    parameter RX_DATA_WIDTH = 8
)
(
    input  wire                                     CLK_100MHz_in,
    input  wire                                     rst_in,
    input  wire                                     flash_enable_in,

    /*
        UART -> UART Programmer
    */
    input  wire                                     uart_receive_in,
    input  wire [RX_DATA_WIDTH - 1: 0]              uart_rxdata_in,

    /*
        UART Programmer -> UART
    */
    output reg                                      uart_received_reg_out,

    /*
        UART Programmer -> CPU
    */
    output wire                                     flash_clk_out,
    output reg  [`COMMAND_WIDTH - 1: 0]             flash_command_reg_out,
    output reg                                      flash_signal_reg_out,
    output reg  [$clog2(`PROGRAM_MEM_SIZE) - 1: 0]  flash_mem_addr_reg_out,
    output reg                                      cpu_en_reg_out
);

    localparam COMMAND_PART_COUNTER_M           = `COMMAND_WIDTH / RX_DATA_WIDTH;
    localparam FLASH_COMMAND_PART_COUNTER_WIDTH = $clog2(COMMAND_PART_COUNTER_M);


    reg [3: 0]                                state_reg;

    reg [RX_DATA_WIDTH - 1: 0]                uart_rxdata_reg;

    reg                                       flash_enable_reg;
    reg                                       flash_done_reg;

    reg [FLASH_COMMAND_PART_COUNTER_WIDTH: 0] flash_command_part_counter_reg;


    assign flash_clk_out = CLK_100MHz_in & flash_enable_reg;


    localparam // states
        RST_STATE          = 4'h0,
        CLEAR_MEM_STATE    = 4'h1,
        WAIT_DATA_STATE    = 4'h2,
        PROCESS_DATA_STATE = 4'h3,
        SEND_SIGNAL_STATE  = 4'h4,
        FLASH_DONE_STATE   = 4'h5;


    initial
    begin
        state_reg                      <= RST_STATE;
        uart_rxdata_reg                <= {RX_DATA_WIDTH{1'b0}};
        uart_received_reg_out          <= 1'b0;
        flash_command_reg_out          <= {`COMMAND_WIDTH{1'b0}};
        flash_signal_reg_out           <= 1'b0;
        flash_mem_addr_reg_out         <= {$clog2(`PROGRAM_MEM_SIZE){1'b0}};
        cpu_en_reg_out                 <= 1'b0;
        flash_enable_reg               <= 1'b0;
        flash_done_reg                 <= 1'b0;
        flash_command_part_counter_reg <= {FLASH_COMMAND_PART_COUNTER_WIDTH{1'b0}};
    end


    always @(posedge CLK_100MHz_in)
    begin
        if (rst_in || flash_enable_in) begin
            state_reg                      <= RST_STATE;
            uart_rxdata_reg                <= {RX_DATA_WIDTH{1'b0}};
            uart_received_reg_out          <= 1'b0;
            flash_command_reg_out          <= {`COMMAND_WIDTH{1'b0}};
            flash_signal_reg_out           <= 1'b0;
            flash_mem_addr_reg_out         <= {$clog2(`PROGRAM_MEM_SIZE){1'b0}};
            cpu_en_reg_out                 <= 1'b1;
            flash_enable_reg               <= flash_enable_in;
            flash_done_reg                 <= 1'b0;
            flash_command_part_counter_reg <= {FLASH_COMMAND_PART_COUNTER_WIDTH{1'b0}};
        end else if (flash_done_reg) begin
            flash_enable_reg <= 1'b0;
            cpu_en_reg_out   <= 1'b1;
        end else if (cpu_en_reg_out) begin
            cpu_en_reg_out <= 1'b0;
        end else if (flash_enable_reg) begin
            case (state_reg)
                RST_STATE: begin
                    state_reg            <= CLEAR_MEM_STATE;
                    flash_signal_reg_out <= 1'b1;
                end
                CLEAR_MEM_STATE: begin
                    if (flash_mem_addr_reg_out >= {{$clog2(`PROGRAM_MEM_SIZE)}{1'b1}}) begin
                        state_reg              <= WAIT_DATA_STATE;
                        flash_signal_reg_out   <= 1'b0;
                        flash_mem_addr_reg_out <= {$clog2(`PROGRAM_MEM_SIZE){1'b0}};
                    end else begin
                        flash_mem_addr_reg_out <= flash_mem_addr_reg_out + {{$clog2(`PROGRAM_MEM_SIZE) - 1{1'b0}}, 1'b1};
                    end
                end
                WAIT_DATA_STATE: begin
                    if (uart_receive_in) begin
                        state_reg                      <= PROCESS_DATA_STATE;
                        uart_rxdata_reg                <= uart_rxdata_in;
                        uart_received_reg_out          <= 1'b1;
                    end else if (flash_command_part_counter_reg >= COMMAND_PART_COUNTER_M) begin
                        state_reg                      <= SEND_SIGNAL_STATE;
                        flash_command_part_counter_reg <= {FLASH_COMMAND_PART_COUNTER_WIDTH{1'b0}};
                    end
                end
                PROCESS_DATA_STATE: begin
                    uart_received_reg_out              <= 1'b0;

                    if (flash_command_part_counter_reg < COMMAND_PART_COUNTER_M) begin
                        state_reg                      <= WAIT_DATA_STATE;
                        flash_command_reg_out          <= {flash_command_reg_out[`COMMAND_WIDTH - RX_DATA_WIDTH - 1: 0], uart_rxdata_reg};
                        flash_command_part_counter_reg <= flash_command_part_counter_reg + {{FLASH_COMMAND_PART_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
                    end
                end
                SEND_SIGNAL_STATE: begin
                    state_reg                <= FLASH_DONE_STATE;

                    if (flash_command_reg_out == {`COMMAND_WIDTH{1'b1}}) begin
                        flash_done_reg       <= 1'b1;
                    end else begin
                        flash_signal_reg_out <= 1'b1;
                    end
                end
                FLASH_DONE_STATE: begin
                    state_reg                  <= flash_done_reg ? FLASH_DONE_STATE : WAIT_DATA_STATE;

                    if (flash_signal_reg_out) begin
                        flash_signal_reg_out   <= 1'b0;
                        flash_mem_addr_reg_out <= flash_mem_addr_reg_out + {{$clog2(`PROGRAM_MEM_SIZE) - 1{1'b0}}, 1'b1};
                    end
                end
            endcase
        end else begin
            flash_done_reg <= 1'b1;
        end
    end

endmodule
