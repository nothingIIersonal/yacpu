`timescale 1ns / 1ps


module uart_programmer
#
(
    parameter RX_DATA_WIDTH = 8
)
(
    input  wire                                     in_clk,
    input  wire                                     in_clke,
    input  wire                                     in_rst,

    input  wire                                     in_flash,

    /*
        UART_RX -> UART_Programmer
    */
    input  wire                                     in_uart_rx_empty,
    input  wire [RX_DATA_WIDTH - 1: 0]              in_uart_rx_data,

    /*
        UART_Programmer -> UART_RX
    */
    output reg                                      out_uart_rx_read,

    /*
        UART_Programmer -> CPU
    */
    output reg                                      out_cpu_en_reg,
    output reg                                      out_cpu_rst_reg,
    output reg  [`COMMAND_WIDTH - 1: 0]             out_flash_command_reg,
    output reg                                      out_flash_signal_reg,
    output reg  [$clog2(`PROGRAM_MEM_SIZE) - 1: 0]  out_flash_mem_addr_reg
);

    localparam [3: 0] // states
        IDLE           = 4'd0,
        READ_0         = 4'd1,
        READ_1         = 4'd2,
        READ_2         = 4'd3,
        CHECK_STOP     = 4'd4,
        FLASH          = 4'd5,
        INC_FLASH_ADDR = 4'd6,
        DONE           = 4'd7;

    localparam COMMAND_PART_COUNTER_M     = (`COMMAND_WIDTH / RX_DATA_WIDTH);
    localparam COMMAND_PART_COUNTER_WIDTH = $clog2(COMMAND_PART_COUNTER_M);

    reg [3: 0]                              state_reg;
    reg [COMMAND_PART_COUNTER_WIDTH - 1: 0] command_part_counter_reg;

    initial
    begin
        out_cpu_en_reg           = 1'b1;
        out_cpu_rst_reg          = 1'b0;
        out_uart_rx_read         = 1'b0;
        out_flash_command_reg    = {`COMMAND_WIDTH{1'b0}};
        out_flash_signal_reg     = 1'b0;
        out_flash_mem_addr_reg   = {$clog2(`PROGRAM_MEM_SIZE){1'b0}};

        state_reg                = IDLE;
        command_part_counter_reg = {COMMAND_PART_COUNTER_WIDTH{1'b0}};
    end

    always @(posedge in_clk)
    begin
        if (in_rst) begin
            out_cpu_en_reg           <= 1'b1;
            out_cpu_rst_reg          <= 1'b0;
            out_uart_rx_read         <= 1'b0;
            out_flash_command_reg    <= {`COMMAND_WIDTH{1'b0}};
            out_flash_signal_reg     <= 1'b0;
            out_flash_mem_addr_reg   <= {$clog2(`PROGRAM_MEM_SIZE){1'b0}};

            state_reg                <= IDLE;
            command_part_counter_reg <= {COMMAND_PART_COUNTER_WIDTH{1'b0}};
        end else if (in_clke) begin
            case (state_reg)
                IDLE: begin
                    out_flash_signal_reg   <= 1'b0;
                    out_flash_mem_addr_reg <= {$clog2(`PROGRAM_MEM_SIZE){1'b0}};

                    if (in_flash) begin
                        state_reg        <= READ_0;
                        out_cpu_en_reg   <= 1'b0;
                        out_cpu_rst_reg  <= 1'b1;
                    end else begin
                        out_cpu_en_reg   <= 1'b1;
                        out_cpu_rst_reg  <= 1'b0;
                    end
                end
                READ_0: begin
                    out_cpu_rst_reg      <= 1'b0;

                    if (!in_uart_rx_empty) begin
                        state_reg        <= READ_1;
                        out_uart_rx_read <= 1'b1;
                    end else begin
                        out_uart_rx_read <= 1'b0;
                    end
                end
                READ_1: begin
                    state_reg        <= READ_2;
                    out_uart_rx_read <= 1'b0;
                end
                READ_2: begin
                    out_flash_command_reg        <= {out_flash_command_reg[`COMMAND_WIDTH - RX_DATA_WIDTH - 1: 0], in_uart_rx_data};

                    if (command_part_counter_reg < (COMMAND_PART_COUNTER_M - 1)) begin
                        state_reg                <= READ_0;
                        command_part_counter_reg <= command_part_counter_reg + {{COMMAND_PART_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
                    end else begin
                        state_reg                <= CHECK_STOP;
                        command_part_counter_reg <= {COMMAND_PART_COUNTER_WIDTH{1'b0}};
                    end
                end
                CHECK_STOP: begin
                    if (out_flash_command_reg == {`COMMAND_WIDTH{1'b1}}) begin
                        state_reg <= DONE;
                    end else begin
                        state_reg <= FLASH;
                    end
                end
                FLASH: begin
                    state_reg              <= INC_FLASH_ADDR;
                    out_flash_signal_reg   <= 1'b1;
                end
                INC_FLASH_ADDR: begin
                    state_reg              <= READ_0;
                    out_flash_signal_reg   <= 1'b0;
                    out_flash_mem_addr_reg <= out_flash_mem_addr_reg + {{$clog2(`PROGRAM_MEM_SIZE) - 1{1'b0}}, 1'b1};
                end
                DONE: begin
                    state_reg <= IDLE;
                end
            endcase
        end
    end

endmodule
