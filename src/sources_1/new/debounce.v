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
 * Debounce module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 *
 */



module debounce
#
(
    parameter SYNC_REG_SIZE  = 2,
    parameter COUNTER_M      = 4
)
(
    input  wire clk_in,
    input  wire rst_in,

    input  wire signal_in,

    output reg  signal_out_reg,
    output reg  signal_out_enable_reg
);

    reg [$clog2(COUNTER_M) - 1: 0] counter;


    wire sync_out;
    wire counter_full = (counter == (COUNTER_M - 1));


    initial
    begin
        signal_out_reg        <= 1'b0;
        signal_out_enable_reg <= 1'b0;
        counter               <= {$clog2(COUNTER_M){1'b0}};
    end


    always @(posedge clk_in)
    begin
        if (rst_in) begin
            signal_out_reg        <= 1'b0;
            signal_out_enable_reg <= 1'b0;
            counter               <= {$clog2(COUNTER_M){1'b0}};
        end else begin
            counter               <= (sync_out == signal_out_reg) ? {$clog2(COUNTER_M){1'b0}} : counter + {{$clog2(COUNTER_M) - 1{1'b0}}, {1'b1}};

            if (counter_full)
                signal_out_reg    <= sync_out;
            signal_out_enable_reg <= counter_full & sync_out;
        end
    end


    synchronizer
    #
    (
        .SYNC_REG_SIZE ( SYNC_REG_SIZE )
    )
    synchronizer_inst
    (
        .clk_in        ( clk_in        ), // in
        .rst_in        ( rst_in        ), // in
        .data_in       ( signal_in     ), // in

        .data_out      ( sync_out      )  // out
    );

endmodule
