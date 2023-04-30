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
 * Seven segment controller module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 *
 */



module seven_seg_controller
#
(
    parameter SEVEN_SEGMENT_COUNT = 8
)
(
    input   wire                                    clk_in,
    input   wire                                    clke_in,
    input   wire                                    rst_in,

    input   wire   [SEVEN_SEGMENT_COUNT - 1: 0]     mask_in,
    input   wire   [SEVEN_SEGMENT_COUNT * 4 - 1: 0] value_in,


    output  wire   [SEVEN_SEGMENT_COUNT - 1: 0]     anodes_out,
    output  reg    [7: 0]                           seg_reg_out
);

    reg [2: 0]                       digit_counter_reg;
    reg [SEVEN_SEGMENT_COUNT - 1: 0] anodes_out_reg;

    wire [3: 0]                      number_splitter [0: SEVEN_SEGMENT_COUNT - 1];
    wire [3: 0]                      current_digit = number_splitter[digit_counter_reg];


    initial
    begin
        seg_reg_out       = 8'h00;
        digit_counter_reg = 3'h0;
        anodes_out_reg    = {SEVEN_SEGMENT_COUNT{1'b0}};
    end


    assign anodes_out = anodes_out_reg | mask_in;


    genvar i;
    generate
        for (i = 0; i < SEVEN_SEGMENT_COUNT; i = i + 1)
        begin : splitter_generating
            assign number_splitter[i] = value_in[((i + 1) * 4 - 1)-: 4];
        end
    endgenerate


    always @(digit_counter_reg)
    begin
        anodes_out_reg <= ~({{SEVEN_SEGMENT_COUNT - 1{1'b0}}, {1'b1}} << digit_counter_reg);
    end


    always @(current_digit)
    begin
        case (current_digit)         //  gfedcba
            4'h0:    seg_reg_out <= ~8'b00111111; // c0
            4'h1:    seg_reg_out <= ~8'b00000110; // f9
            4'h2:    seg_reg_out <= ~8'b01011011; // a4
            4'h3:    seg_reg_out <= ~8'b01001111; // b0
            4'h4:    seg_reg_out <= ~8'b01100110; // 99
            4'h5:    seg_reg_out <= ~8'b01101101; // 92
            4'h6:    seg_reg_out <= ~8'b01111101; // 82
            4'h7:    seg_reg_out <= ~8'b00000111; // f8
            4'h8:    seg_reg_out <= ~8'b01111111; // 80
            4'h9:    seg_reg_out <= ~8'b01101111; // 90
            4'hA:    seg_reg_out <= ~8'b01110111; // 88
            4'hB:    seg_reg_out <= ~8'b01111100; // 83
            4'hC:    seg_reg_out <= ~8'b00111001; // c6
            4'hD:    seg_reg_out <= ~8'b01011110; // a1
            4'hE:    seg_reg_out <= ~8'b01111001; // 86
            4'hF:    seg_reg_out <= ~8'b01110001; // 8e
            default: seg_reg_out <= ~8'b10000000; // 7f
        endcase
    end


    always @(posedge clk_in)
    begin
        if (clke_in) begin
            if (rst_in) begin
                digit_counter_reg <= 3'h0;
            end else begin
                digit_counter_reg <= digit_counter_reg + 3'h1; // overflow allowed
            end
        end
    end

endmodule