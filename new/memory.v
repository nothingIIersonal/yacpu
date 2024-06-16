`timescale 1ns / 1ps


`include "hwid.vh"


module memory
#
(
    parameter WORD_WIDTH =  8, //  bits
    parameter CAPACITY   = 64  // words
)
(
    // global
    input  wire                             in_clk,
    input  wire                             in_rst,

    // read
    input  wire  [$clog2(CAPACITY)  - 1: 0] in_read_addr,
    input  wire                             in_read_ready,
    output reg   [WORD_WIDTH        - 1: 0] out_data_reg,
    output reg                              out_data_ready_reg,

    // write
    input  wire  [$clog2(CAPACITY)  - 1: 0] in_write_addr,
    input  wire  [WORD_WIDTH        - 1: 0] in_write_data,
    input  wire                             in_write_ready,
    output reg                              out_write_ready_reg,
    output reg                              out_write_denied_reg,

    // hwid
    input  wire  [HWID_WIDTH - 1:        0] in_hwid

);


    reg [$clog2(CAPACITY) - 1: 0]  read_addr_reg;
    reg                            read_ready_reg;


    reg [$clog2(CAPACITY) - 1: 0]  write_addr_reg;
    reg [WORD_WIDTH       - 1: 0]  write_data_reg;
    reg                            write_ready_reg;

    reg                            hwid_reg;

    reg [WORD_WIDTH       - 1: 0]  memory_reg       [0: CAPACITY - 1];


    integer i;


    localparam
        STATE_RST = 0,
        STATE_IDLE = 1,
        STATE_READ = 2,
        STATE_WRITE = 3;
    reg [2: 0] state_reg = STATE_RST;


    // synchronize input values
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            read_addr_reg   <= {$clog2(CAPACITY){1'b0}};
            read_ready_reg  <= 1'b0;
            write_addr_reg  <= {$clog2(CAPACITY){1'b0}};
            write_data_reg  <= {WORD_WIDTH{1'b0}};
            write_ready_reg <= 1'b1;
            hwid_reg        <= {HWID_WIDTH{1'b0}};
        end else begin
            read_addr_reg   <= in_read_addr;
            read_ready_reg  <= in_read_ready;
            write_addr_reg  <= in_write_addr;
            write_data_reg  <= in_write_data;
            write_ready_reg <= in_write_ready;
            hwid_reg        <= in_hwid;
        end
    end


    // process
    always @(posedge in_clk)
    begin
        case (state_reg)
            STATE_RST: begin
                out_data_reg         <= {WORD_WIDTH{1'b0}};
                out_data_ready_reg   <= 1'b1;
                out_write_ready_reg  <= 1'b1;
                out_write_denied_reg <= 1'b0;

                for (i = 0; i < CAPACITY; i = i + 1) begin
                    memory_reg[i] <= {WORD_WIDTH{1'b0}};
                end

                state_reg <= STATE_IDLE;
            end
            STATE_IDLE: begin
                if (in_rst) begin
                    state_reg <= STATE_RST;
                end else if (read_ready_reg) begin
                    out_data_ready_reg   <= 1'b0;
                    out_write_ready_reg  <= 1'b0;
                    out_write_denied_reg <= 1'b0;
                    state_reg            <= STATE_READ;
                end else if (write_ready_reg) begin
                    out_data_ready_reg   <= 1'b0;
                    out_write_ready_reg  <= 1'b0;
                    out_write_denied_reg <= 1'b0;
                    state_reg            <= STATE_WRITE;
                end
            end
            STATE_READ: begin
                if (in_rst) begin
                    state_reg <= STATE_RST;
                end else begin
                    out_data_reg        <= memory_reg[read_addr_reg];
                    out_data_ready_reg  <= 1'b1;
                    out_write_ready_reg <= 1'b1;
                    state_reg           <= STATE_IDLE;
                end
            end
            STATE_WRITE: begin
                if (in_rst) begin
                    state_reg <= STATE_RST;
                end else begin
                    casex (write_addr_reg)
                        // MMIO UART SPACE
                        MMIO_UART_BEGIN_ADDRESS_MASK,
                        MMIO_UART_END_ADDRESS_MASK  : begin
                            casex (write_addr_reg)
                                MMIO_UART_STATUS_ADDRESS_MASK,
                                MMIO_UART_TXD_ADDRESS_MASK   : begin
                                    out_write_denied_reg <= 1'b1;
                                end
                            endcase
                        end

                        // MMIO PROGRAM SPACE
                        MMIO_PROGRAM_BEGIN_ADDRESS_MASK,
                        MMIO_PROGRAM_END_ADDRESS_MASK  : begin
                            case (hwid_reg)
                                HWID_SCNP: begin
                                    memory_reg[write_addr_reg] <= write_data_reg;
                                    out_data_ready_reg         <= 1'b1;
                                    out_write_ready_reg        <= 1'b1;
                                end
                                default: begin
                                    out_write_denied_reg       <= 1'b1;
                                end
                            endcase
                        end

                        default: begin
                            memory_reg[write_addr_reg] <= write_data_reg;
                            out_data_ready_reg         <= 1'b1;
                            out_write_ready_reg        <= 1'b1;
                        end
                    endcase
                    state_reg <= STATE_IDLE;
                end
            end
            default: begin
                state_reg <= STATE_RST;
            end
        endcase
    end


endmodule
