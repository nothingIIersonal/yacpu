`timescale 1ns / 1ps


`include "cpu_core_parameters.vh" 


module cpu_core
(
    input  wire                                    in_clk,
    input  wire                                    in_clke,
    input  wire                                    in_rst,
    input  wire                                    in_en,

    /*
        UART_Programmer -> CPU
    */
    input  wire [`COMMAND_WIDTH - 1: 0]            in_flash_command,
    input  wire                                    in_flash_signal,
    input  wire [$clog2(`PROGRAM_MEM_SIZE) - 1: 0] in_flash_mem_addr,

    /*
        CPU -> UART_RX
    */
    output wire                                    out_uart_rx_read,

    /*
        UART_RX -> CPU
    */
    input  wire                                    in_uart_rx_empty,
    input  wire [`UART_RXTX_WIDTH - 1: 0]          in_uart_rx_data,

    /*
        CPU -> UART_TX
    */
    output wire                                    out_uart_tx_start,
    output wire [`UART_RXTX_WIDTH - 1: 0]          out_uart_tx_data,

    /*
        UART_TX -> CPU
    */
    input  wire                                    in_uart_tx_done
);

    reg  [`PC_REG_WIDTH             - 1: 0]      pc_reg;
    reg  [`PC_REG_WIDTH             - 1: 0]      new_pc_reg;

    reg  [`COMMAND_WIDTH            - 1: 0]      program_mem [0: `PROGRAM_MEM_SIZE - 1];
    reg  [`DATA_WIDTH               - 1: 0]      data_mem    [0: `DATA_MEM_SIZE    - 1];
    reg  [`STACK_DATA_WIDTH         - 1: 0]      stack_mem   [0: `STACK_MEM_SIZE   - 1];
    reg  [`DATA_WIDTH               - 1: 0]      gp_reg_file [0: `GP_REG_FILE_SIZE - 1]; // general purpose register file. 0 -> r1, 1 -> r2, ...

    reg  [`FLAGS_REG_WIDTH          - 1: 0]      flags_reg;
    reg  [$clog2(`STACK_MEM_SIZE)   - 1: 0]      sp_reg;
    reg  [$clog2(`STACK_MEM_SIZE)   - 1: 0]      sp_end_reg;

    reg  [$clog2(`GP_REG_FILE_SIZE) - 1: 0]      gp_reg_file_adr_for_uart_tx_data_reg;
    reg                                          uart_rx_read_reg;
    reg                                          uart_tx_start_reg;

    reg  [`PC_REG_WIDTH             - 1: 0]      old_pc_value_for_ret_reg;

    reg  [`DATA_WIDTH               - 1: 0]      new_data_reg;
    reg  [`FLAGS_REG_WIDTH          - 1: 0]      new_flags_reg;

    reg  [$clog2(`GP_REG_FILE_SIZE) - 1: 0]      reg_file_adr_to_write_reg;
    reg  [$clog2(`DATA_MEM_SIZE)    - 1: 0]      data_mem_adr_to_write_reg;

    reg                                          gp_reg_file_we_reg;
    reg                                          data_mem_we_reg;
    reg                                          stack_mem_we_reg;

    reg  [`COMMAND_WIDTH            - 1: 0]      cmd_1_reg, cmd_2_reg;


    wire [`OPCODE_WIDTH - 1: 0]
        op_cmd_1 = cmd_1_reg[`COMMAND_WIDTH - 1 -: `OPCODE_WIDTH],
        op_cmd_2 = cmd_2_reg[`COMMAND_WIDTH - 1 -: `OPCODE_WIDTH];


    ////
    // select register from general purpose register file for UART data out
    assign out_uart_tx_data = gp_reg_file[gp_reg_file_adr_for_uart_tx_data_reg];
    ////


    ////
    // assign UART_RX 'read' out signal and UART_TX 'start' out signal
    assign out_uart_rx_read  = uart_rx_read_reg;
    assign out_uart_tx_start = uart_tx_start_reg;
    ////


    ////
    // command connects
    //
    // NOP_cmd wires
    // there is not a single wire here
    //
    // MOV_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mov_reg_to_write_adr                  = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_mov_literal_to_read                   = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    //
    // READL_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readl_reg_to_write_adr                = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_readl_base_literal_to_read            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_readl_offset_literal_to_read          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - `DATA_WIDTH               - 1 -:        `DATA_WIDTH       ];
    //
    // READR_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readr_reg_to_write_adr                = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_readr_base_literal_to_read            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readr_reg_offset_to_read_adr          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - `DATA_WIDTH               - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // LOADR_cmd wires
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadr_base_literal_to_write           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_loadr_reg_offset_to_write_adr         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH                                           - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_loadr_reg_to_read_adr                 = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH - $clog2(`GP_REG_FILE_SIZE)               - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // LOADL_cmd wires
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_base_literal_to_write           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_offset_literal_to_write         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH                                           - 1 -:        `DATA_WIDTH       ];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_literal_to_read                 = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH - `DATA_WIDTH                             - 1 -:        `DATA_WIDTH       ];
    //
    // MOD_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mod_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mod_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_mod_literal_op_2                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -:        `DATA_WIDTH       ];
    //
    // DIV_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_div_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_div_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_div_literal_op_2                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -:        `DATA_WIDTH       ];
    //
    // ADD_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_op_2_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // CMP_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_cmp_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_cmp_reg_op_2_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // INC_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_inc_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // DEC_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_dec_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // TINEQ_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_1_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_2_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_3_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // PUSHR_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_pushr_reg_adr                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // PUSHL_cmd wires
    wire [`DATA_WIDTH               - 1: 0]       cmd_2_pushl_literal                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    //
    // POP_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_pop_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // FJMP_cmd wires
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_fjmp_label                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_2_fjmp_flag                             = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_fjmp_label                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_1_fjmp_flag                             = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    //
    // FNJMP_cmd wires
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_fnjmp_label                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_2_fnjmp_flag                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_fnjmp_label                           = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_1_fnjmp_flag                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    //
    // JMP_cmd wires
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_jmp_label                             = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_jmp_label                             = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    //
    // CALL_cmd wires
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_call_label                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_call_label                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    //
    // RET_cmd wires
    // there is not a single wire here
    //
    // UGET_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_uget_reg_adr                          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // USEND_cmd wires
    wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_usend_reg_adr                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // HALT_cmd wires
    // there is not a single wire here
    //
    // end of command connects
    ////


    integer i;
    initial begin
        pc_reg      = {`PC_REG_WIDTH{1'b0}};
        new_pc_reg  = {`PC_REG_WIDTH{1'b0}};

        for (i = 0; i < `DATA_MEM_SIZE; i = i + 1) begin
            data_mem[i] = {`DATA_WIDTH{1'b0}};
        end

        for (i = 0; i < `STACK_MEM_SIZE; i = i + 1) begin
            stack_mem[i] = {`STACK_DATA_WIDTH{1'b0}};
        end

        for (i = 0; i < `PROGRAM_MEM_SIZE; i = i + 1) begin
            program_mem[i] = {`COMMAND_WIDTH{1'b0}};
        end

        cmd_1_reg = {`COMMAND_WIDTH{1'b0}};
        cmd_2_reg = {`COMMAND_WIDTH{1'b0}};

        for (i = 0; i < `DATA_WIDTH; i = i + 1) begin
            gp_reg_file[i] = {`DATA_WIDTH{1'b0}};
        end

        old_pc_value_for_ret_reg = {`PC_REG_WIDTH{1'b0}};
        new_data_reg             = {`DATA_WIDTH{1'b0}};
        new_flags_reg            = {`FLAGS_REG_WIDTH{1'b0}};
        flags_reg                = {`FLAGS_REG_WIDTH{1'b0}};
        sp_reg                   = {$clog2(`STACK_MEM_SIZE){1'b0}};
        sp_end_reg               = {$clog2(`STACK_MEM_SIZE){1'b1}};

        gp_reg_file_adr_for_uart_tx_data_reg  = {$clog2(`GP_REG_FILE_SIZE){1'b0}};
        uart_rx_read_reg                      = 1'b0;
        uart_tx_start_reg                     = 1'b0;

        data_mem_we_reg    = 1'b0;
        stack_mem_we_reg   = 1'b0;
        gp_reg_file_we_reg = 1'b0;

        reg_file_adr_to_write_reg  = {$clog2(`GP_REG_FILE_SIZE){1'b0}};
        data_mem_adr_to_write_reg  = {$clog2(`DATA_MEM_SIZE){1'b0}};

        $readmemb("D:\\Other\\Vivado_projects\\mirea\\schemotech_5sem\\lab6\\compiler\\mems\\base_firmware.mem", program_mem);
    end


    ////
    // Program memory processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            for (i = 0; i < `PROGRAM_MEM_SIZE; i = i + 1) begin
                program_mem[i] = {`COMMAND_WIDTH{1'b0}};
            end
        end else if (in_clke) begin
            if (in_flash_signal) begin
                program_mem[in_flash_mem_addr] <= in_flash_command;
            end
        end
    end
    // end of Program memory processing
    ////


    ////
    // PC processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            pc_reg <= {`PC_REG_WIDTH{1'b0}};
        end else if (in_en & in_clke) begin
            pc_reg <= new_pc_reg;
        end
    end
    // end of PC processing
    ////


    ////
    // new PC processing
    always @(*)
    begin
        if (in_rst) begin
            new_pc_reg               <= {`PC_REG_WIDTH{1'b0}};
            old_pc_value_for_ret_reg <= {`PC_REG_WIDTH{1'b0}};
        end else begin
            if (op_cmd_2 == `JMP_cmd) begin
                new_pc_reg <= cmd_2_jmp_label;
            end else if ((op_cmd_2 == `FJMP_cmd) && (flags_reg[cmd_2_fjmp_flag])) begin
                new_pc_reg <= cmd_2_fjmp_label;
            end else if ((op_cmd_2 == `FNJMP_cmd) && (~flags_reg[cmd_2_fnjmp_flag])) begin
                new_pc_reg <= cmd_2_fnjmp_label;
            end else if (op_cmd_2 == `CALL_cmd) begin
                new_pc_reg               <= cmd_2_call_label;
                old_pc_value_for_ret_reg <= pc_reg;
            end else if (op_cmd_2 == `RET_cmd) begin
                new_pc_reg <= stack_mem[sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}];
            end else if (!(op_cmd_1 == `FJMP_cmd  || op_cmd_1 == `FNJMP_cmd || op_cmd_1 == `JMP_cmd   ||
                           op_cmd_1 == `CALL_cmd  || op_cmd_1 == `RET_cmd   || op_cmd_1 == `UGET_cmd  || 
                           op_cmd_1 == `USEND_cmd ||
                           op_cmd_2 == `FJMP_cmd  || op_cmd_2 == `FNJMP_cmd || op_cmd_2 == `JMP_cmd   ||
                           op_cmd_2 == `CALL_cmd  || op_cmd_2 == `RET_cmd))
            begin
                new_pc_reg <= pc_reg + {{`PC_REG_WIDTH - 1{1'b0}}, 1'b1};
            end else begin
                new_pc_reg               <= new_pc_reg;
                old_pc_value_for_ret_reg <= old_pc_value_for_ret_reg;
            end
        end
    end
    // end of new PC processing
    ////


    ////
    // CMD pipeline
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            cmd_1_reg <= cmd_1_reg ^ cmd_1_reg;
            cmd_2_reg <= cmd_2_reg ^ cmd_2_reg;
        end else if (in_en & in_clke) begin
            if (op_cmd_1 == `FJMP_cmd || op_cmd_1 == `FNJMP_cmd || op_cmd_1 == `JMP_cmd  ||
                op_cmd_1 == `CALL_cmd || op_cmd_1 == `RET_cmd   || op_cmd_1 == `UGET_cmd || 
                op_cmd_1 == `USEND_cmd)
            begin
                cmd_1_reg <= cmd_1_reg ^ cmd_1_reg; // put 'nop'
            end else if (op_cmd_2 == `FJMP_cmd || op_cmd_2 == `FNJMP_cmd ||
                         op_cmd_2 == `JMP_cmd  || op_cmd_2 == `CALL_cmd  ||
                         op_cmd_2 == `RET_cmd)
            begin
                cmd_1_reg <= cmd_1_reg ^ cmd_1_reg; // put 'nop'
            end else begin
                cmd_1_reg <= program_mem[pc_reg]; // the first  stage of pipeline  -> fetch                      (save command to register and parse it)
            end

            cmd_2_reg <= cmd_1_reg;               // the second stage of pipeline  -> selection + execute + save (generate new data, address to write and 'we' signals)
                                                  ////   the data is saved on the third clock cycle (in fact, the beginning of the first stage).
        end
    end
    // end of CMD pipeline
    ////


    ////
    // the second stage of pipeline -> selection + execute + save (generate new data, address to write and 'we' signals)
    always @(*)
    begin
        if (in_rst) begin
            new_data_reg              <= {`DATA_WIDTH{1'b0}};
            reg_file_adr_to_write_reg <= {$clog2(`GP_REG_FILE_SIZE){1'b0}};
            data_mem_adr_to_write_reg <= {$clog2(`DATA_MEM_SIZE){1'b0}};
            new_flags_reg             <= {`FLAGS_REG_WIDTH{1'b0}};
        end else begin
            //
            // generate new data and address to write
            case (op_cmd_2)
                // `NOP_cmd: begin

                // end
                `MOV_cmd: begin
                    new_data_reg              <= cmd_2_mov_literal_to_read;
                    reg_file_adr_to_write_reg <= cmd_2_mov_reg_to_write_adr;
                end
                `READL_cmd: begin
                    new_data_reg              <= data_mem[cmd_2_readl_base_literal_to_read + cmd_2_readl_offset_literal_to_read];
                    reg_file_adr_to_write_reg <= cmd_2_readl_reg_to_write_adr;
                end
                `READR_cmd: begin
                    new_data_reg              <= data_mem[cmd_2_readr_base_literal_to_read + gp_reg_file[cmd_2_readr_reg_offset_to_read_adr]];
                    reg_file_adr_to_write_reg <= cmd_2_readr_reg_to_write_adr;
                end
                `LOADR_cmd: begin
                    new_data_reg              <= gp_reg_file[cmd_2_loadr_reg_to_read_adr];
                    data_mem_adr_to_write_reg <= cmd_2_loadr_base_literal_to_write + gp_reg_file[cmd_2_loadr_reg_offset_to_write_adr];
                end
                `LOADL_cmd: begin
                    new_data_reg              <= cmd_2_loadl_literal_to_read;
                    data_mem_adr_to_write_reg <= cmd_2_loadl_base_literal_to_write + cmd_2_loadl_offset_literal_to_write;
                end
                `MOD_cmd: begin
                    new_data_reg                      <= gp_reg_file[cmd_2_mod_reg_op_1_adr] % cmd_2_mod_literal_op_2;
                    reg_file_adr_to_write_reg         <= cmd_2_mod_reg_res_adr;

                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_mod_reg_op_1_adr] % cmd_2_mod_literal_op_2 == {`DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
                end
                `DIV_cmd: begin
                    new_data_reg                      <= gp_reg_file[cmd_2_div_reg_op_1_adr] / cmd_2_div_literal_op_2;
                    reg_file_adr_to_write_reg         <= cmd_2_div_reg_res_adr;

                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_div_reg_op_1_adr] / cmd_2_div_literal_op_2 == {`DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
                end
                `ADD_cmd: begin
                    new_data_reg                      <= gp_reg_file[cmd_2_add_reg_op_1_adr] + gp_reg_file[cmd_2_add_reg_op_2_adr];
                    reg_file_adr_to_write_reg         <= cmd_2_add_reg_res_adr;

                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_add_reg_op_1_adr] + gp_reg_file[cmd_2_add_reg_op_2_adr] <= {`DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
                end
                `CMP_cmd: begin
                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_cmp_reg_op_1_adr] <= gp_reg_file[cmd_2_cmp_reg_op_2_adr]) ? 1'b1 : 1'b0;
                end
                `INC_cmd: begin
                    new_data_reg                      <= gp_reg_file[cmd_2_inc_reg_adr] + {{`DATA_WIDTH - 1{1'b0}}, 1'b1};
                    reg_file_adr_to_write_reg         <= cmd_2_inc_reg_adr;

                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_inc_reg_adr] + {{`DATA_WIDTH - 1{1'b0}}, 1'b1} <= {`DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
                end
                `DEC_cmd: begin
                    new_data_reg                      <= gp_reg_file[cmd_2_dec_reg_adr] - {{`DATA_WIDTH - 1{1'b0}}, 1'b1};
                    reg_file_adr_to_write_reg         <= cmd_2_dec_reg_adr;

                    new_flags_reg[`LE_FLAGS_REG_CODE] <= (gp_reg_file[cmd_2_dec_reg_adr] - {{`DATA_WIDTH - 1{1'b0}}, 1'b1} <= {`DATA_WIDTH{1'b0}}) ? 1'b1 : 1'b0;
                end
                `TINEQ_cmd: begin
                    if ((gp_reg_file[cmd_2_tineq_reg_op_1_adr] + gp_reg_file[cmd_2_tineq_reg_op_2_adr] > gp_reg_file[cmd_2_tineq_reg_op_3_adr]) &&
                        (gp_reg_file[cmd_2_tineq_reg_op_1_adr] + gp_reg_file[cmd_2_tineq_reg_op_3_adr] > gp_reg_file[cmd_2_tineq_reg_op_2_adr]) &&
                        (gp_reg_file[cmd_2_tineq_reg_op_2_adr] + gp_reg_file[cmd_2_tineq_reg_op_3_adr] > gp_reg_file[cmd_2_tineq_reg_op_1_adr]))
                    begin
                        new_flags_reg[`TQ_FLAGS_REG_CODE] <= 1'b1;
                    end else begin
                        new_flags_reg[`TQ_FLAGS_REG_CODE] <= 1'b0;
                    end
                end
                `PUSHR_cmd: begin
                    new_data_reg <= gp_reg_file[cmd_2_pushr_reg_adr];
                end
                `PUSHL_cmd: begin
                    new_data_reg <= cmd_2_pushl_literal;
                end
                `POP_cmd: begin
                    new_data_reg              <= stack_mem[sp_reg - 1][`DATA_WIDTH - 1: 0]; // or [`STACK_DATA_WIDTH - N: 0]
                    reg_file_adr_to_write_reg <= cmd_2_pop_reg_adr;
                end
                // `FJMP_cmd: begin

                // end
                // `FNJMP_cmd: begin

                // end
                // `JMP_cmd: begin

                // end
                // `CALL_cmd: begin

                // end
                // `RET_cmd: begin

                // end
                `UGET_cmd: begin
                    new_data_reg              <= in_uart_rx_data;
                    reg_file_adr_to_write_reg <= cmd_2_uget_reg_adr;
                end
                // `USEND_cmd: begin

                // end
                // `HALT_cmd: begin

                // end
                default: begin
                    new_data_reg                      <= {`DATA_WIDTH{1'b0}};
                    reg_file_adr_to_write_reg         <= {$clog2(`GP_REG_FILE_SIZE){1'b0}};
                    data_mem_adr_to_write_reg         <= {$clog2(`DATA_MEM_SIZE){1'b0}};
                    new_flags_reg[`LE_FLAGS_REG_CODE] <= 1'b0;
                    new_flags_reg[`TQ_FLAGS_REG_CODE] <= 1'b0;
                end
            endcase
            //
            // generate new flags data for UART
            new_flags_reg[`UR_FLAGS_REG_CODE] <= (!in_uart_rx_empty);
            new_flags_reg[`UT_FLAGS_REG_CODE] <= in_uart_tx_done;
        end
    end
    //
    always @(*)
    begin
        if (in_rst) begin
            gp_reg_file_we_reg <= 1'b0;
            data_mem_we_reg    <= 1'b0;
            stack_mem_we_reg   <= 1'b0;
        end else begin
            // generate write enable signals for registers, flags, data memory and stack memory
            //
            // generate write enable signal for register file
            case (op_cmd_2)
                `MOV_cmd,
                `READL_cmd,
                `READR_cmd,
                `MOD_cmd,
                `DIV_cmd,
                `ADD_cmd,
                `DEC_cmd,
                `INC_cmd,
                `POP_cmd,
                `UGET_cmd : begin
                    gp_reg_file_we_reg <= 1'b1;
                end
                default   : begin
                    gp_reg_file_we_reg <= 1'b0;
                end
            endcase
            //
            // generate write enable signal for flags register
            // there is no logic here because the flags can be changed at any time
            //
            // generate write enable signal for data memory
            case (op_cmd_2)
                `LOADR_cmd,
                `LOADL_cmd  : begin
                    data_mem_we_reg <= 1'b1;
                end
                default     : begin
                    data_mem_we_reg <= 1'b0;
                end
            endcase
            //
            // generate write enable signal for stack memory
            case (op_cmd_2)
                `PUSHR_cmd,
                `PUSHL_cmd,
                `POP_cmd,
                `CALL_cmd,
                `RET_cmd    : begin
                    stack_mem_we_reg <= 1'b1;
                end
                default     : begin
                    stack_mem_we_reg <= 1'b0;
                end
            endcase
            //
        end
    end
    //
    // save new data
    //
    // general purpose registers processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            for (i = 0; i < `DATA_WIDTH; i = i + 1) begin
                gp_reg_file[i] <= {`DATA_WIDTH{1'b0}};
            end
        end else if (in_en & in_clke) begin
            gp_reg_file[reg_file_adr_to_write_reg] <= gp_reg_file_we_reg ? new_data_reg : gp_reg_file[reg_file_adr_to_write_reg];
        end
    end
    // end of general purpose registers processing
    //
    // flags register processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            flags_reg <= {`FLAGS_REG_WIDTH{1'b0}};
        end else if (in_en & in_clke) begin
            flags_reg <= new_flags_reg;
        end
    end
    // end of flags register processing
    //
    // data memory processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            for (i = 0; i < `DATA_MEM_SIZE; i = i + 1) begin
                data_mem[i] <= {`DATA_WIDTH{1'b0}};
            end
        end else if (in_en & in_clke) begin
            data_mem[data_mem_adr_to_write_reg] <= data_mem_we_reg ? new_data_reg : data_mem[data_mem_adr_to_write_reg];
        end
    end
    // end of data memory processing
    //
    // stack memory processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            for (i = 0; i < `STACK_MEM_SIZE; i = i + 1) begin
                stack_mem[i] <= {`STACK_DATA_WIDTH{1'b0}};
            end

            sp_reg           <= {$clog2(`STACK_MEM_SIZE){1'b0}};
            sp_end_reg       <= {$clog2(`STACK_MEM_SIZE){1'b1}};
        end else if (in_en & in_clke) begin
            if ((op_cmd_2 == `PUSHR_cmd) || (op_cmd_2 == `PUSHL_cmd)) begin
                stack_mem[sp_reg] <= stack_mem_we_reg ? {1'b0, new_data_reg} : stack_mem[sp_reg];
                sp_reg            <= sp_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `POP_cmd) begin
                stack_mem[sp_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}] <= stack_mem_we_reg ? {`STACK_DATA_WIDTH{1'b0}} : stack_mem[sp_end_reg];
                sp_reg                                                          <= sp_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `CALL_cmd) begin
                stack_mem[sp_end_reg] <= stack_mem_we_reg ? old_pc_value_for_ret_reg : stack_mem[sp_end_reg];
                sp_end_reg            <= sp_end_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `RET_cmd) begin
                stack_mem[sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}] <= stack_mem_we_reg ? {`STACK_DATA_WIDTH{1'b0}} : stack_mem[sp_end_reg];
                sp_end_reg                                                          <= sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end
        end
    end
    // end of stack memory processing
    //
    // UART processing
    //
    // UART Receiver 'read' proccessing
    always @(*)
    begin
        if (in_rst) begin
            uart_rx_read_reg <= 1'b0;
        end else if (in_en & in_clke) begin
            if (op_cmd_1 == `UGET_cmd) begin
                uart_rx_read_reg <= 1'b1;
            end else begin
                uart_rx_read_reg <= 1'b0;
            end
        end else begin
            uart_rx_read_reg <= 1'b0;
        end
    end
    // end of UART Receiver 'start' proccessing
    //
    // UART Transmitter processing
    always @(posedge in_clk)
    begin
        if (in_rst) begin
            gp_reg_file_adr_for_uart_tx_data_reg     <= {$clog2(`GP_REG_FILE_SIZE){1'b0}};
            uart_tx_start_reg                        <= 1'b0;
        end else if (in_en & in_clke) begin
            if (op_cmd_2 == `USEND_cmd) begin
                gp_reg_file_adr_for_uart_tx_data_reg <= cmd_2_usend_reg_adr;
                uart_tx_start_reg                    <= 1'b1;
            end else begin
                uart_tx_start_reg                    <= 1'b0;
            end
        end
    end
    // end of UART Transmitter processing
    //
    // end of the second stage of pipeline -> selection + execute + save (generate new data, address to write and 'we' signals)
    ////

endmodule