`timescale 1ns / 1ps


module seven_seg_controller
#
(
    parameter SYSTEM_CLOCK_MHz    = 100,
    parameter SEVEN_SEGMENT_COUNT =   8
)
(
    input   wire                                    in_clk,
    input   wire                                    in_rst,
    input   wire                                    in_en,

    input   wire   [SEVEN_SEGMENT_COUNT - 1: 0]     in_mask,
    input   wire   [SEVEN_SEGMENT_COUNT * 4 - 1: 0] in_value,

    output  wire   [SEVEN_SEGMENT_COUNT - 1: 0]     out_anodes,
    output  reg    [7: 0]                           out_seg_reg
);

////
// clock divider
    localparam SEVEN_SEGMENT_DIVIDER_VALUE = (SYSTEM_CLOCK_MHz * 1000000 / (SEVEN_SEGMENT_COUNT * 200)); // 200Hz per segment

    reg [$clog2(SEVEN_SEGMENT_DIVIDER_VALUE) - 1: 0] clk_seven_segment_counter_reg;
    reg                                              clke_seven_segment_reg;

    initial
    begin
        clk_seven_segment_counter_reg <= {$clog2(SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}};
        clke_seven_segment_reg        <= 1'b0;
    end

    always @(posedge in_clk)
    begin
        if (in_rst) begin
            clk_seven_segment_counter_reg <= {$clog2(SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}};
            clke_seven_segment_reg        <= 1'b0;
        end else if (in_en) begin
            clke_seven_segment_reg        <= (clk_seven_segment_counter_reg == {$clog2(SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}}) ? 1'b1 : 1'b0;
            clk_seven_segment_counter_reg <= (clk_seven_segment_counter_reg == (SEVEN_SEGMENT_DIVIDER_VALUE - 1))
                                             ?
                                             {$clog2(SEVEN_SEGMENT_DIVIDER_VALUE){1'b0}}
                                             :
                                             (clk_seven_segment_counter_reg + {{$clog2(SEVEN_SEGMENT_DIVIDER_VALUE) - 1{1'b0}}, 1'b1});
        end
    end

    wire clke = clke_seven_segment_reg;
////

    reg [2: 0]                       digit_counter_reg;
    reg [SEVEN_SEGMENT_COUNT - 1: 0] out_anodes_reg;

    wire [3: 0]                      number_splitter [0: SEVEN_SEGMENT_COUNT - 1];
    wire [3: 0]                      current_digit = number_splitter[digit_counter_reg];

    initial
    begin
        out_seg_reg       <= 8'h00;
        digit_counter_reg <= 3'h0;
        out_anodes_reg    <= {SEVEN_SEGMENT_COUNT{1'b0}};
    end

    assign out_anodes = out_anodes_reg | in_mask;

    genvar i;
    generate
        for (i = 0; i < SEVEN_SEGMENT_COUNT; i = i + 1)
        begin : splitter_generating
            assign number_splitter[i] = in_value[((i + 1) * 4 - 1)-: 4];
        end
    endgenerate

    always @(digit_counter_reg)
    begin
        out_anodes_reg <= ~({{SEVEN_SEGMENT_COUNT - 1{1'b0}}, {1'b1}} << digit_counter_reg);
    end

    always @(current_digit)
    begin
        case (current_digit)         //  gfedcba
            4'h0:    out_seg_reg <= ~8'b00111111; // c0
            4'h1:    out_seg_reg <= ~8'b00000110; // f9
            4'h2:    out_seg_reg <= ~8'b01011011; // a4
            4'h3:    out_seg_reg <= ~8'b01001111; // b0
            4'h4:    out_seg_reg <= ~8'b01100110; // 99
            4'h5:    out_seg_reg <= ~8'b01101101; // 92
            4'h6:    out_seg_reg <= ~8'b01111101; // 82
            4'h7:    out_seg_reg <= ~8'b00000111; // f8
            4'h8:    out_seg_reg <= ~8'b01111111; // 80
            4'h9:    out_seg_reg <= ~8'b01101111; // 90
            4'hA:    out_seg_reg <= ~8'b01110111; // 88
            4'hB:    out_seg_reg <= ~8'b01111100; // 83
            4'hC:    out_seg_reg <= ~8'b00111001; // c6
            4'hD:    out_seg_reg <= ~8'b01011110; // a1
            4'hE:    out_seg_reg <= ~8'b01111001; // 86
            4'hF:    out_seg_reg <= ~8'b01110001; // 8e
            default: out_seg_reg <= ~8'b10000000; // 7f
        endcase
    end

    always @(posedge in_clk)
    begin
        if (in_rst) begin
            digit_counter_reg <= 3'h0;
        end else if (clke) begin
            if (in_en) begin
                digit_counter_reg <= digit_counter_reg + 3'h1; // overflow allowed
            end
        end
    end

endmodule