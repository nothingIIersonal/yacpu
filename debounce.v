`timescale 1ns / 1ps


module debounce
#
(
    parameter SYNC_REG_WIDTH = 2,
    parameter COUNTER_M      = 4
)
(
    input  wire in_clk,
    input  wire in_clke,
    input  wire in_rst,
    input  wire in_en,

    input  wire in_signal,

    output reg  out_signal_reg,
    output reg  out_signal_enable_reg
);

    reg [$clog2(COUNTER_M) - 1: 0] counter_reg;
    reg [SYNC_REG_WIDTH - 1: 0]    sync_reg;

    wire sync_out         = sync_reg[0];
    wire counter_reg_full = (counter_reg == (COUNTER_M - 1));

    initial
    begin
        out_signal_reg        <= 1'b0;
        out_signal_enable_reg <= 1'b0;
        counter_reg           <= {$clog2(COUNTER_M){1'b0}};
        sync_reg              <= {SYNC_REG_WIDTH{1'b0}};
    end

    always @(posedge in_clk)
    begin
        if (in_rst) begin
            out_signal_reg        <= 1'b0;
            out_signal_enable_reg <= 1'b0;
            counter_reg           <= {$clog2(COUNTER_M){1'b0}};
            sync_reg              <= {SYNC_REG_WIDTH{1'b0}};
        end else if (in_clke) begin
            if (in_en) begin
                if (counter_reg_full) begin
                    out_signal_reg    <= sync_out;
                end else begin
                    out_signal_reg    <= out_signal_reg;
                end

                if (sync_out == out_signal_reg) begin
                    counter_reg       <= {$clog2(COUNTER_M){1'b0}};
                end else begin
                    counter_reg       <= counter_reg + {{$clog2(COUNTER_M) - 1{1'b0}}, {1'b1}}; 
                end

                sync_reg              <= {in_signal, sync_reg[SYNC_REG_WIDTH - 1: 1]};
                out_signal_enable_reg <= counter_reg_full & sync_out;
            end
        end
    end

endmodule
