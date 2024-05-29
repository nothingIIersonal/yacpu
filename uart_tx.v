`timescale 1ns / 1ps


module uart_tx
#
(
    parameter CLK_RATE_MHz =  100,
    parameter DATA_WIDTH   =    8,
    parameter BAUDRATE     = 9600
)
(
    input  wire                        in_clk,
    input  wire                        in_rst,
    input  wire                        in_en,

    input  wire                        in_start,
    input  wire  [DATA_WIDTH - 1: 0]   in_data,

    output reg                         out_data_reg,
    output reg                         out_done_reg
);

    localparam [1: 0] // states
        STATE_IDLE       = 2'd0,
        STATE_START_BIT  = 2'd1,
        STATE_DATA_BITS  = 2'd2,
        STATE_DONE       = 2'd3;

    localparam
        CLK_COUNTER_M     = CLK_RATE_MHz * 1000000 / BAUDRATE,
        CLK_COUNTER_M_2   = CLK_COUNTER_M / 2,
        CLK_COUNTER_WIDTH = $clog2(CLK_COUNTER_M);

    localparam
        DATA_COUNTER_WIDTH = $clog2(DATA_WIDTH);

    reg [1: 0]                      state_reg;
    reg [DATA_WIDTH - 1: 0]         data_buf_reg;
    reg [DATA_COUNTER_WIDTH - 1: 0] data_counter_reg;
    reg [CLK_COUNTER_WIDTH - 1: 0]  clk_counter_reg;

    wire clke = (clk_counter_reg == {CLK_COUNTER_WIDTH{1'b0}}) ? 1'b1 : 1'b0;

    initial
    begin
        state_reg        <= STATE_IDLE;
        data_buf_reg     <= {DATA_WIDTH{1'b0}};
        data_counter_reg <= {DATA_COUNTER_WIDTH{1'b0}};
        clk_counter_reg  <= {CLK_COUNTER_WIDTH{1'b0}};
        out_data_reg     <= 1'b1;
        out_done_reg     <= 1'b1;
    end

    // data proccessing
    always @(posedge in_clk)
    begin
        if (in_rst == 1'b1) begin
            state_reg        <= STATE_IDLE;
            data_buf_reg     <= {DATA_WIDTH{1'b0}};
            data_counter_reg <= {DATA_COUNTER_WIDTH{1'b0}};
            out_data_reg     <= 1'b1;
            out_done_reg     <= 1'b1;
        end else if (in_en) begin
            case (state_reg)
                STATE_IDLE: begin
                    if (in_start) begin
                        state_reg    <= STATE_START_BIT;
                        data_buf_reg <= in_data;
                        out_done_reg <= 1'b0;
                    end else begin
                        out_done_reg <= 1'b1;
                    end
                end
                STATE_START_BIT: begin
                    if (clke) begin
                        state_reg    <= STATE_DATA_BITS;
                        out_data_reg <= 1'b0;
                    end
                end
                STATE_DATA_BITS: begin
                    if (clke) begin
                        out_data_reg         <= data_buf_reg[data_counter_reg];

                        if (data_counter_reg < {DATA_COUNTER_WIDTH{1'b1}}) begin
                            data_counter_reg <= data_counter_reg + {{DATA_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
                        end else begin
                            state_reg        <= STATE_DONE;
                            data_counter_reg <= {DATA_COUNTER_WIDTH{1'b0}};
                        end
                    end
                end
                STATE_DONE: begin
                    if (clke) begin
                        state_reg    <= STATE_IDLE;
                        out_data_reg <= 1'b1;
                        out_done_reg <= 1'b1;
                    end
                end
                default: begin
                    state_reg        <= STATE_IDLE;
                    data_buf_reg     <= {DATA_WIDTH{1'b0}};
                    data_counter_reg <= {DATA_COUNTER_WIDTH{1'b0}};
                    out_data_reg     <= 1'b1;
                    out_done_reg     <= 1'b1;
                end
            endcase
        end
    end

    // clock proccessing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
        end else if (in_en) begin
            case (state_reg)
                STATE_IDLE: begin
                    clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
                end
                STATE_START_BIT, STATE_DATA_BITS, STATE_DONE: begin
                    if (clk_counter_reg < CLK_COUNTER_M) begin
                        clk_counter_reg <= clk_counter_reg + {{CLK_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
                    end else begin
                        clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
                    end
                end
                default: begin
                    clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
                end
            endcase
        end
    end

endmodule
