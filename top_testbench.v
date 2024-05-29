`timescale 1ns / 1ps


module top_testbench();

    localparam clk_period = 10;

    localparam
        CLK_RATE_MHz =  100,
        DATA_WIDTH   =    8,
        BAUDRATE     = 9600;

    localparam
        CLK_COUNTER_M     = CLK_RATE_MHz * 1000000 / BAUDRATE,
        CLK_COUNTER_M_2   = CLK_COUNTER_M / 2,
        CLK_COUNTER_WIDTH = $clog2(CLK_COUNTER_M);

    localparam
        N_0      = 8'h00,
        N_1      = 8'h01,
        N_2      = 8'h02,
        N_3      = 8'h03,
        N_4      = 8'h04,
        N_5      = 8'h05,
        N_6      = 8'h06,
        N_7      = 8'h07,
        N_8      = 8'h08,
        N_9      = 8'h09,
        cmd_1_1  = 8'h08,
        cmd_1_2  = 8'hff,
        cmd_1_3  = 8'h00,
        cmd_1_4  = 8'h00,
        cmd_2_1  = 8'h09,
        cmd_2_2  = 8'h02,
        cmd_2_3  = 8'h00,
        cmd_2_4  = 8'h00,
        cmd_3_1  = 8'h42,
        cmd_3_2  = 8'h20,
        cmd_3_3  = 8'h00,
        cmd_3_4  = 8'h00,
        cmd_4_1  = 8'h90,
        cmd_4_2  = 8'h0c,
        cmd_4_3  = 8'h00,
        cmd_4_4  = 8'h00,
        cmd_stop = 8'hFF,
        CHAR_CR  = 8'h0D,
        CHAR_R   = 8'h52,
        CHAR_0   = 8'h30,
        CHAR_1   = 8'h31,
        CHAR_2   = 8'h32,
        CHAR_3   = 8'h33,
        CHAR_4   = 8'h34,
        CHAR_5   = 8'h35,
        CHAR_6   = 8'h36,
        CHAR_7   = 8'h37,
        CHAR_8   = 8'h38,
        CHAR_9   = 8'h39,
        CHAR_A   = 8'h41,
        CHAR_B   = 8'h42,
        CHAR_C   = 8'h43,
        CHAR_D   = 8'h44,
        CHAR_E   = 8'h45,
        CHAR_F   = 8'h46;

    reg clk       = 1'b0;

    reg [CLK_COUNTER_WIDTH: 0] clk_counter_reg = {CLK_COUNTER_WIDTH{1'b0}};

    reg                      rxclk_reg = 1'b0;
    wire                     receive_data;

    reg                      txclk_reg = 1'b0;
    reg                      send_data = 1'b1;

    reg                      flash     = 1'b0;

    always #clk_period clk <= ~clk;

    initial
    begin
        #(1000000 * clk_period);

        flash = 1'b1;
        #(5 * clk_period);
        flash = 1'b0;

        uart_data_gen(cmd_1_1);
        uart_data_gen(cmd_1_2);
        uart_data_gen(cmd_1_3);
        uart_data_gen(cmd_1_4);
        uart_data_gen(cmd_2_1);
        uart_data_gen(cmd_2_2);
        uart_data_gen(cmd_2_3);
        uart_data_gen(cmd_2_4);
        uart_data_gen(cmd_3_1);
        uart_data_gen(cmd_3_2);
        uart_data_gen(cmd_3_3);
        uart_data_gen(cmd_3_4);
        uart_data_gen(cmd_4_1);
        uart_data_gen(cmd_4_2);
        uart_data_gen(cmd_4_3);
        uart_data_gen(cmd_4_4);
        uart_data_gen(cmd_stop);
        uart_data_gen(cmd_stop);
        uart_data_gen(cmd_stop);
        uart_data_gen(cmd_stop);

        #(1000000 * clk_period);
        $finish;
    end

    top
    top_inst
    (
        .in_CLK       ( clk          ),
        .in_RST       ( 1'b0         ),
        .in_FLASH     ( flash        ),
        .in_UART_TXD  ( send_data    ),
        .out_UART_RXD ( receive_data )
    );

    task automatic uart_data_gen
    (
        input [DATA_WIDTH - 1: 0] code
    );
        begin
            @(posedge rxclk_reg)
                send_data <= 0;

            for (integer i = 0; i < DATA_WIDTH; i = i + 1)
            begin
                @(posedge rxclk_reg)
                    send_data <= code[i];
            end

            @(posedge rxclk_reg)
                send_data <= 1;
        end
    endtask

    // clock proccessing
    //
    always @(posedge clk)
    begin
        case (clk_counter_reg)
            CLK_COUNTER_M: begin
                clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
            end
            default: begin
                clk_counter_reg <= clk_counter_reg + {{CLK_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
            end
        endcase

        rxclk_reg <= (clk_counter_reg == CLK_COUNTER_M_2) ? 1'b1 : 1'b0;
    end
    //
    always @(posedge clk)
    begin
        case (clk_counter_reg)
            CLK_COUNTER_M: begin
                clk_counter_reg <= {CLK_COUNTER_WIDTH{1'b0}};
            end
            default: begin
                clk_counter_reg <= clk_counter_reg + {{CLK_COUNTER_WIDTH - 1{1'b0}}, 1'b1};
            end
        endcase

        txclk_reg <= (clk_counter_reg == {CLK_COUNTER_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
    end
    //

endmodule
