`timescale 1ns / 1ps


module fifo_buffer
#
(
    parameter DATA_WIDTH = 8,
    parameter FIFO_SIZE  = 32
)
(
    input  wire                     in_clk,
    input  wire                     in_clke,
    input  wire                     in_rst,
    input  wire                     in_en,

    input  wire                     in_read,
    input  wire                     in_write,
    input  wire [DATA_WIDTH - 1: 0] in_data,

    output wire                     out_empty,
    output wire                     out_full,
    output reg  [DATA_WIDTH - 1: 0] out_data
);

    reg [DATA_WIDTH - 1: 0]         fifo_mem          [FIFO_SIZE - 1: 0];
    reg [$clog2(FIFO_SIZE): 0]      fifo_counter_reg;

    assign out_empty = (fifo_counter_reg == {$clog2(FIFO_SIZE) + 1{1'b0}});
    assign out_full  = (fifo_counter_reg == FIFO_SIZE);

    integer i;

    initial
    begin
        out_data         <= {DATA_WIDTH{1'b0}};
        fifo_counter_reg <= {$clog2(FIFO_SIZE) + 1{1'b0}};
        for (i = 0; i < FIFO_SIZE; i = i + 1) begin
            fifo_mem[i]  <= {DATA_WIDTH{1'b0}};
        end
    end

    always @(posedge in_clk)
    begin
        if (in_rst) begin
            out_data         <= {DATA_WIDTH{1'b0}};
            fifo_counter_reg <= {$clog2(FIFO_SIZE) + 1{1'b0}};
            for (i = 0; i < FIFO_SIZE; i = i + 1) begin
                fifo_mem[i]  <= {DATA_WIDTH{1'b0}};
            end
        end else if (in_en & in_clke) begin
            if (in_read) begin
                if (!out_empty) begin
                    out_data                   <= fifo_mem[0];
                    fifo_counter_reg           <= fifo_counter_reg - {{$clog2(FIFO_SIZE){1'b0}}, 1'b1};
                    fifo_mem[FIFO_SIZE - 1]    <= {DATA_WIDTH{1'b0}};
                    for (i = 0; i < FIFO_SIZE - 1; i = i + 1) begin
                        fifo_mem[i]            <= fifo_mem[i + 1];
                    end
                end
            end else if (in_write) begin
                if (!out_full) begin
                    fifo_mem[fifo_counter_reg] <= in_data;
                    fifo_counter_reg           <= fifo_counter_reg + {{$clog2(FIFO_SIZE){1'b0}}, 1'b1};
                end
            end
        end
    end

endmodule
