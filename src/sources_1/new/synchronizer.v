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
 * Synchronizer for debounce module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 *
 */



module synchronizer
#
(
    parameter SYNC_REG_SIZE = 2
)
(
    input  wire clk_in,
    input  wire rst_in,

    input  wire data_in,

    output wire data_out
);

    reg [SYNC_REG_SIZE - 1: 0] data_reg;


    assign data_out = data_reg[0];


    initial
    begin
        data_reg <= {SYNC_REG_SIZE{1'b0}};
    end


    always @(posedge clk_in)
    begin
        if (rst_in) begin
            data_reg <= {SYNC_REG_SIZE{1'b0}};
        end else begin
            data_reg <= {data_in, data_reg[SYNC_REG_SIZE - 1: 1]};
        end
    end

endmodule
