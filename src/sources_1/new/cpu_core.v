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
 * CPU Core module
 *
 * Designer : Magomedov R. M. (https://github.com/nothingIIersonal)
 * Designer : Glazunov  N. M. (https://github.com/nikikust        )
 *
 */



`define PC_REG_WIDTH          9                    // program counter                            // in bits
`define FLAGS_REG_WIDTH       4                    // flags register (LE, TQ, UR, UT)            // in bits
`define DATA_WIDTH            8                    // all data width (data memory, gp registers) // in bits
`define STACK_DATA_WIDTH      `PC_REG_WIDTH        // 9 bit for store return address and data    // in bits
`define COMMAND_WIDTH        32                    // command (instruction)                      // in bits
`define UART_UDRIO_WIDTH      `DATA_WIDTH          // UART data in and data out width            // in bits

`define PROGRAM_MEM_SIZE      2 ** `PC_REG_WIDTH   // 32x512, program mem                        // in instrucions
`define GP_REG_FILE_SIZE      8                    // count of general purpose registers (8x8)   // in quantity
`define DATA_MEM_SIZE         2 ** `DATA_WIDTH     // 8x256, data mem                            // in cells
`define STACK_MEM_SIZE       64                    // 9x64, stack mem                            // in cells
`define OPCODE_WIDTH          5                    // operation width                            // in bits 



`define NOP_cmd               0                    // nop                                 : NOP
`define MOV_cmd               1                    // mov REG, $op                        : REG                  <- $op
`define READL_cmd             2                    // readl REG, [$BASE + $OFFSET]        : REG                  <- [$BASE + OFFSET]
`define READR_cmd             3                    // readr REG, [$BASE + REG_OFFSET]     : REG                  <- [$BASE + REG_OFFSET]
`define LOADR_cmd             4                    // loadr [$BASE + REG_OFFSET], REG     : [$BASE + REG_OFFSET] <- REG
`define LOADL_cmd             5                    // loadl [$BASE + $OFFSET], $LIT       : [$BASE + $OFFSET]    <- $LIT
`define MOD_cmd               6                    // mod REG_RES, REG_OP_1, $LIT_OP_2    : REG_RES              <- REG_OP_1 % $LIT_OP_2
                                                   //                                     : %le                  <- REG_OP_1 % $LIT_OP_2 == 0 ? 1 : 0
`define DIV_cmd               7                    // div REG_RES, REG_OP_1, $LIT_OP_2    : REG_RES              <- REG_OP_1 // $LIT_OP_2
                                                   //                                     : %le                  <- REG_OP_1 // $LIT_OP_2 == 0 ? 1 : 0
`define ADD_cmd               8                    // add REG_RES, REG_OP_1, REG_OP_2     : REG_RES              <- REG_OP_1 + REG_OP_2
                                                   //                                     : %le                  <- REG_OP_1 + $REG_OP_2 <= 0 ? 1 : 0
`define CMP_cmd               9                    // cmp REG_OP_1, REG_OP_2              : %le                  <- REG_OP_1 <= REG_OP_2 ? 1 : 0
`define INC_cmd              10                    // inc REG                             : REG                  <- REG + 1
                                                   //                                     : %le                  <- REG + 1 <= 0 ? 1 : 0
`define DEC_cmd              11                    // dec REG                             : REG                  <- REG - 1
                                                   //                                     : %le                  <- REG - 1 <= 0 ? 1 : 0
`define TINEQ_cmd            12                    // tineq REG_1, REG_2, REG_3           : %tq                  <- REG_1, REG_2 and REG_3 form triangle ? 1 : 0
`define PUSHR_cmd            13                    // pushr REG                           : [SP]                 <- REG
                                                   //                                     : SP                   <- SP + 1
`define PUSHL_cmd            14                    // pushr $LIT                          : [SP]                 <- $LIT
                                                   //                                     : SP                   <- SP + 1
`define POP_cmd              15                    // pop REG                             : [SP - 1]             <- 0
                                                   //                                     : REG                  <- SP - 1
                                                   //                                     : SP                   <- SP - 1
`define FJMP_cmd             16                    // fjmp .label, %flag                  : PC                   <- %flag ? PC + 1 : .label
`define FNJMP_cmd            17                    // fnjmp .label, %flag                 : PC                   <- %flag ? .label : PC + 1
`define JMP_cmd              18                    // jmp .label                          : PC                   <- .label
`define CALL_cmd             19                    // call .label                         : [SP_END]             <- PC + 1
                                                   //                                     : SP_END               <- SP_END - 1
                                                   //                                     : PC                   <- .label
`define RET_cmd              20                    // ret                                 : PC                   <- [SP_END + 1]
                                                   //                                     : [SP_END + 1]         <- 0
                                                   //                                     : SP_END               <- SP_END + 1
`define UGET_cmd             21                    // uget REG                            : uart_receive_in      <- (UART -> CPU) '1' if UART is ready to give data
                                                   //                                     : uart_data_in         <- (UART -> CPU) UART writes data to this bus
                                                   //                                     : uart_received_out    <- (CPU -> UART) '1' if CPU took data
`define USEND_cmd            22                    // usend REG                           : uart_transmitted_in  <- (UART -> CPU) '1' if UART sent data
                                                   //                                     : uart_data_out        <- (CPU -> UART) CPU writes data to this bus
                                                   //                                     : uart_transmit_out    <- (CPU -> UART) '1' if CPU want to send data
`define HALT_cmd             23                    // halt



`define LE_FLAGS_REG_CODE     0
`define TQ_FLAGS_REG_CODE     1
`define UR_FLAGS_REG_CODE     2
`define UT_FLAGS_REG_CODE     3



`define r1_REG_CODE           0
`define r2_REG_CODE           1
`define r3_REG_CODE           2
`define r4_REG_CODE           3
`define r5_REG_CODE           4
`define r6_REG_CODE           5
`define r7_REG_CODE           6
`define r8_REG_CODE           7




/*
    +----------------------------------------------------------------------------------------------------------------------------+
    |                                                  Command system                                                            |
    +----+----------------------------------------------------------------------------------------------------------------+------+
    |    |                                      C O M M A N D     F I E L D S                                             |      |
    |    +--------+--------------------------------------+------------------------------------+---------------------------+ Zero |
    | №  |        |                ARG_1                 |                ARG_2               |          ARG_3            |      |
    |    |   OP   +-------------------------+------------+-----------------------+------------+--------------+------------+ bits |
    |    | 5 bits |   NAME                  | BIT DEPTH  |  NAME                 | BIT DEPTH  | NAME         | BIT DEPTH  |      |
    +----+--------+-------------------------+------------+-----------------------+------------+--------------+------------+------+
    |  0 | nop    |                         |            |                       |            |              |            |  27  |
    |  1 | mov    |   REG                   |  3         |  $LIT                 |  8         |              |            |  16  |
    |  2 | readl  |   REG                   |  3         |  [$BASE + $OFFSET]    |  8 + 8     |              |            |   8  |
    |  3 | readr  |   REG                   |  3         |  [$BASE + REG_OFFSET] |  8 + 3     |              |            |  13  |
    |  4 | loadr  |   [$BASE + REG_OFFSET]  |  8 + 3     |  REG                  |  3         |              |            |  13  |
    |  5 | loadl  |   [$BASE + $OFFSET]     |  8 + 8     |  $LIT                 |  8         |              |            |   3  |
    |  6 | mod    |   REG_RES               |  3         |  REG_OP_1             |  3         |  $LIT_OP_2   |  8         |  13  |
    |  7 | div    |   REG_RES               |  3         |  REG_OP_1             |  3         |  $LIT_OP_2   |  8         |  13  |
    |  8 | add    |   REG_RES               |  3         |  REG_OP_1             |  3         |  REG_OP_2    |  3         |  18  |
    |  9 | cmp    |   REG_OP_1              |  3         |  REG_OP_2             |  3         |              |            |  21  |
    | 10 | inc    |   REG                   |  3         |                       |            |              |            |  24  |
    | 11 | dec    |   REG                   |  3         |                       |            |              |            |  24  |
    | 12 | tineq  |   REG_OP_1              |  3         |  REG_OP_2             |  3         |  REG_OP_3    |  3         |  18  |
    | 13 | pushr  |   REG                   |  3         |                       |            |              |            |  24  |
    | 14 | pushl  |   $LIT                  |  8         |                       |            |              |            |  19  |
    | 15 | pop    |   REG                   |  3         |                       |            |              |            |  24  |
    | 16 | fjmp   |   .LABEL                |  9         |  %FLAG_NAME           |  2         |              |            |  16  |
    | 17 | fnjmp  |   .LABEL                |  9         |  %FLAG_NAME           |  2         |              |            |  16  |
    | 18 | jmp    |   .LABEL                |  9         |                       |            |              |            |  18  |
    | 19 | call   |   .LABEL                |  9         |                       |            |              |            |  18  |
    | 20 | ret    |                         |            |                       |            |              |            |  27  |
    | 21 | uget   |   REG                   |  3         |                       |            |              |            |  24  |
    | 22 | usend  |   REG                   |  3         |                       |            |              |            |  24  |
    | 23 | halt   |                         |            |                       |            |              |            |  27  |
    +----+--------+-------------------------+------------+-----------------------+------------+--------------+------------+------+

    All unused bits (inluding common ones) can be initialized to 0 (see 'Zero bits' column).

    +------------------------------------------------------------------------------------------------+--------------------+
    |                                     common instruction                                         | common unused bits |
    +----------------------------+-------------------------------------------------------------------+--------------------+
    |       OPCODE               |                                   payload                         |         0          |
    |     5 (in bits)            |                                 24 (in bits)                      |     3 (in bits)    |
    +----------------------------+-------------------------------------------------------------------+--------------------+
*/




module cpu_core
(
    input  wire                                    CLK_100MHz_in,
    input  wire                                    cpu_reset_in,

    /*
        UART Programmer -> CPU
    */
    input  wire                                    flash_clk_in,
    input  wire [`COMMAND_WIDTH - 1: 0]            flash_command_in,
    input  wire                                    flash_signal_in,
    input  wire [$clog2(`PROGRAM_MEM_SIZE) - 1: 0] flash_mem_addr_in,

    /*
        UART -> CPU
    */
    input  wire                                    uart_transmitted_in,
    input  wire                                    uart_receive_in,
    input  wire [`UART_UDRIO_WIDTH - 1: 0]         uart_data_in,

    /*
        CPU -> UART
    */
    output wire                                    uart_transmit_out,
    output wire                                    uart_received_out,
    output wire [`UART_UDRIO_WIDTH - 1: 0]         uart_data_out
);

    (* DONT_TOUCH = "yes" *) reg  [`PC_REG_WIDTH             - 1: 0]      pc_reg;
                             reg  [`PC_REG_WIDTH             - 1: 0]      new_pc_reg;

                             reg  [`COMMAND_WIDTH            - 1: 0]      program_mem [0: `PROGRAM_MEM_SIZE - 1];
    (* DONT_TOUCH = "yes" *) reg  [`DATA_WIDTH               - 1: 0]      data_mem    [0: `DATA_MEM_SIZE    - 1];
    (* DONT_TOUCH = "yes" *) reg  [`STACK_DATA_WIDTH         - 1: 0]      stack_mem   [0: `STACK_MEM_SIZE   - 1];
    (* DONT_TOUCH = "yes" *) reg  [`DATA_WIDTH               - 1: 0]      gp_reg_file [0: `GP_REG_FILE_SIZE - 1]; // general purpose register file. 0 -> r1, 1 -> r2, ...

    (* DONT_TOUCH = "yes" *) reg  [`FLAGS_REG_WIDTH          - 1: 0]      flags_reg;
    (* DONT_TOUCH = "yes" *) reg  [$clog2(`STACK_MEM_SIZE)   - 1: 0]      sp_reg;
    (* DONT_TOUCH = "yes" *) reg  [$clog2(`STACK_MEM_SIZE)   - 1: 0]      sp_end_reg;

    (* DONT_TOUCH = "yes" *) reg  [$clog2(`GP_REG_FILE_SIZE) - 1: 0]      uart_data_out_adr_reg;
    (* DONT_TOUCH = "yes" *) reg                                          uart_received_reg;
    (* DONT_TOUCH = "yes" *) reg                                          uart_transmit_reg;

                             reg  [`PC_REG_WIDTH             - 1: 0]      old_pc_value_for_ret;

                             reg  [`DATA_WIDTH               - 1: 0]      new_data_reg;
                             reg  [`FLAGS_REG_WIDTH          - 1: 0]      new_flags_reg;

                             reg  [$clog2(`GP_REG_FILE_SIZE) - 1: 0]      reg_file_adr_to_write_reg;
                             reg  [$clog2(`DATA_MEM_SIZE)    - 1: 0]      data_mem_adr_to_write_reg;

                             reg                                          gp_reg_file_we;
                             reg                                          data_mem_we;
                             reg                                          stack_mem_we;

    (* DONT_TOUCH = "yes" *) reg  [`COMMAND_WIDTH            - 1: 0]      cmd_1_reg, cmd_2_reg;


    (* DONT_TOUCH = "yes" *) wire [`OPCODE_WIDTH - 1: 0]
        op_cmd_1 = cmd_1_reg[`COMMAND_WIDTH - 1 -: `OPCODE_WIDTH],
        op_cmd_2 = cmd_2_reg[`COMMAND_WIDTH - 1 -: `OPCODE_WIDTH];


    ////
    // select register from general purpose register file for UART data out
    assign uart_data_out = gp_reg_file[uart_data_out_adr_reg];
    ////


    ////
    // assign UART RX/TX enable
    assign uart_received_out = uart_received_reg;
    assign uart_transmit_out = uart_transmit_reg;
    ////


    ////
    // command connects
    //
    // NOP_cmd wires
    // there is not a single wire here
    //
    // MOV_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mov_reg_to_write_adr                  = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_mov_literal_to_read                   = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    //
    // READL_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readl_reg_to_write_adr                = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_readl_base_literal_to_read            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_readl_offset_literal_to_read          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - `DATA_WIDTH               - 1 -:        `DATA_WIDTH       ];
    //
    // READR_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readr_reg_to_write_adr                = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_readr_base_literal_to_read            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -:        `DATA_WIDTH       ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_readr_reg_offset_to_read_adr          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - `DATA_WIDTH               - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // LOADR_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadr_base_literal_to_write           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_loadr_reg_offset_to_write_adr         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH                                           - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_loadr_reg_to_read_adr                 = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH - $clog2(`GP_REG_FILE_SIZE)               - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // LOADL_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_base_literal_to_write           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_offset_literal_to_write         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH                                           - 1 -:        `DATA_WIDTH       ];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_loadl_literal_to_read                 = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `DATA_WIDTH - `DATA_WIDTH                             - 1 -:        `DATA_WIDTH       ];
    //
    // MOD_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mod_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_mod_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_mod_literal_op_2                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -:        `DATA_WIDTH       ];
    //
    // DIV_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_div_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_div_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_div_literal_op_2                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -:        `DATA_WIDTH       ];
    //
    // ADD_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_res_adr                       = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_add_reg_op_2_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // CMP_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_cmp_reg_op_1_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_cmp_reg_op_2_adr                      = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // INC_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_inc_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // DEC_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_dec_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // TINEQ_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_1_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_2_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE)                             - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_tineq_reg_op_3_adr                    = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - $clog2(`GP_REG_FILE_SIZE) - $clog2(`GP_REG_FILE_SIZE) - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // PUSHR_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_pushr_reg_adr                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // PUSHL_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`DATA_WIDTH               - 1: 0]       cmd_2_pushl_literal                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `DATA_WIDTH       ];
    //
    // POP_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_pop_reg_adr                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // FJMP_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_fjmp_label                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_2_fjmp_flag                             = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_fjmp_label                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_1_fjmp_flag                             = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    //
    // FNJMP_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_fnjmp_label                           = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_2_fnjmp_flag                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_fnjmp_label                           = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [$clog2(`FLAGS_REG_WIDTH)  - 1: 0]       cmd_1_fnjmp_flag                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH - `PC_REG_WIDTH                                         - 1 -: $clog2(`FLAGS_REG_WIDTH) ];
    //
    // JMP_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_jmp_label                             = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_jmp_label                             = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    //
    // CALL_cmd wires
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_2_call_label                            = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    (* DONT_TOUCH = "yes" *) wire [`PC_REG_WIDTH             - 1: 0]       cmd_1_call_label                            = cmd_1_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -:        `PC_REG_WIDTH     ];
    //
    // RET_cmd wires
    // there is not a single wire here
    //
    // UGET_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_uget_reg_adr                          = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
    //
    // USEND_cmd wires
    (* DONT_TOUCH = "yes" *) wire [$clog2(`GP_REG_FILE_SIZE) - 1: 0]       cmd_2_usend_reg_adr                         = cmd_2_reg[`COMMAND_WIDTH - `OPCODE_WIDTH                                                         - 1 -: $clog2(`GP_REG_FILE_SIZE)];
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

        old_pc_value_for_ret = {`PC_REG_WIDTH{1'b0}};
        new_data_reg         = {`DATA_WIDTH{1'b0}};
        new_flags_reg        = {`FLAGS_REG_WIDTH{1'b0}};
        flags_reg            = {`FLAGS_REG_WIDTH{1'b0}};
        sp_reg               = {$clog2(`STACK_MEM_SIZE){1'b0}};
        sp_end_reg           = {$clog2(`STACK_MEM_SIZE){1'b1}};

        uart_data_out_adr_reg = {$clog2(`GP_REG_FILE_SIZE){1'b0}};
        uart_received_reg     = 1'b0;
        uart_transmit_reg     = 1'b0;

        data_mem_we    = 1'b0;
        stack_mem_we   = 1'b0;
        gp_reg_file_we = 1'b0;

        reg_file_adr_to_write_reg  = {$clog2(`GP_REG_FILE_SIZE){1'b0}};
        data_mem_adr_to_write_reg  = {$clog2(`DATA_MEM_SIZE){1'b0}};

        $readmemb("D:\\Other\\Vivado_projects\\mirea\\schemotech_5sem\\lab6\\compiler\\base_firmware.mem", program_mem);
    end


    ////
    // UART Programmer processing
    always @(posedge flash_clk_in)
    begin
        if (flash_signal_in) begin
            program_mem[flash_mem_addr_in] <= flash_command_in;
        end
    end
    // end of UART Programmer processing
    ////


    ////
    // PC processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            pc_reg <= {`PC_REG_WIDTH{1'b0}};
        end else begin
            pc_reg <= new_pc_reg;
        end
    end
    // end of PC processing
    ////


    ////
    // new PC processing
    always @(*)
    begin
        if (cpu_reset_in) begin
            new_pc_reg <= {`PC_REG_WIDTH{1'b0}};
        end else begin
            if (op_cmd_2 == `JMP_cmd) begin
                new_pc_reg <= cmd_2_jmp_label;
            end else if ((op_cmd_2 == `FJMP_cmd) && (flags_reg[cmd_2_fjmp_flag])) begin
                new_pc_reg <= cmd_2_fjmp_label;
            end else if ((op_cmd_2 == `FNJMP_cmd) && (~flags_reg[cmd_2_fnjmp_flag])) begin
                new_pc_reg <= cmd_2_fnjmp_label;
            end else if (op_cmd_2 == `CALL_cmd) begin
                new_pc_reg           <= cmd_2_call_label;
                old_pc_value_for_ret <= pc_reg;
            end else if (op_cmd_2 == `RET_cmd) begin
                new_pc_reg <= stack_mem[sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}];
            end else if (!(op_cmd_1 == `FJMP_cmd  || op_cmd_1 == `FNJMP_cmd || op_cmd_1 == `JMP_cmd   ||
                           op_cmd_1 == `CALL_cmd  || op_cmd_1 == `RET_cmd   || op_cmd_1 == `UGET_cmd  || 
                           op_cmd_1 == `USEND_cmd ||
                           op_cmd_2 == `FJMP_cmd  || op_cmd_2 == `FNJMP_cmd || op_cmd_2 == `JMP_cmd   ||
                           op_cmd_2 == `CALL_cmd  || op_cmd_2 == `RET_cmd))
            begin
                new_pc_reg <= pc_reg + {{`PC_REG_WIDTH - 1{1'b0}}, 1'b1};
            end
        end
    end
    // end of new PC processing
    ////


    ////
    // CMD pipeline
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            cmd_1_reg <= cmd_1_reg ^ cmd_1_reg;
            cmd_2_reg <= cmd_2_reg ^ cmd_2_reg;
        end else begin
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
        if (cpu_reset_in) begin
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
                    new_data_reg              <= stack_mem[sp_reg - 1][`STACK_DATA_WIDTH - 2: 0];
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
                    new_data_reg              <= uart_data_in;
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
            new_flags_reg[`UR_FLAGS_REG_CODE] <= uart_receive_in;
            new_flags_reg[`UT_FLAGS_REG_CODE] <= uart_transmitted_in;
        end
    end
    //
    always @(*)
    begin
        if (cpu_reset_in) begin
            gp_reg_file_we <= 1'b0;
            data_mem_we    <= 1'b0;
            stack_mem_we   <= 1'b0;
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
                    gp_reg_file_we <= 1'b1;
                end
                default   : begin
                    gp_reg_file_we <= 1'b0;
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
                    data_mem_we <= 1'b1;
                end
                default     : begin
                    data_mem_we <= 1'b0;
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
                    stack_mem_we <= 1'b1;
                end
                default     : begin
                    stack_mem_we <= 1'b0;
                end
            endcase
            //
        end
    end
    //
    // save new data
    //
    // general purpose registers processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            for (i = 0; i < `DATA_WIDTH; i = i + 1) begin
                gp_reg_file[i] <= {`DATA_WIDTH{1'b0}};
            end
        end else begin
            gp_reg_file[reg_file_adr_to_write_reg] <= gp_reg_file_we ? new_data_reg : gp_reg_file[reg_file_adr_to_write_reg];
        end
    end
    // end of general purpose registers processing
    //
    // flags register processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            flags_reg <= {`FLAGS_REG_WIDTH{1'b0}};
        end else begin
            flags_reg <= new_flags_reg;
        end
    end
    // end of flags register processing
    //
    // data memory processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            for (i = 0; i < `DATA_MEM_SIZE; i = i + 1) begin
                data_mem[i] <= {`DATA_WIDTH{1'b0}};
            end
        end else begin
            data_mem[data_mem_adr_to_write_reg] <= data_mem_we ? new_data_reg : data_mem[data_mem_adr_to_write_reg];
        end
    end
    // end of data memory processing
    //
    // stack memory processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            for (i = 0; i < `STACK_MEM_SIZE; i = i + 1) begin
                stack_mem[i] <= {`STACK_DATA_WIDTH{1'b0}};
            end

            sp_reg           <= {$clog2(`STACK_MEM_SIZE){1'b0}};
            sp_end_reg       <= {$clog2(`STACK_MEM_SIZE){1'b1}};
        end else begin
            if ((op_cmd_2 == `PUSHR_cmd) || (op_cmd_2 == `PUSHL_cmd)) begin
                stack_mem[sp_reg] <= stack_mem_we ? {1'b0, new_data_reg} : stack_mem[sp_reg];
                sp_reg            <= sp_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `POP_cmd) begin
                stack_mem[sp_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}] <= stack_mem_we ? {`STACK_DATA_WIDTH{1'b0}} : stack_mem[sp_end_reg];
                sp_reg                                                          <= sp_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `CALL_cmd) begin
                stack_mem[sp_end_reg] <= stack_mem_we ? old_pc_value_for_ret : stack_mem[sp_end_reg];
                sp_end_reg            <= sp_end_reg - {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end else if (op_cmd_2 == `RET_cmd) begin
                stack_mem[sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1}] <= stack_mem_we ? {`STACK_DATA_WIDTH{1'b0}} : stack_mem[sp_end_reg];
                sp_end_reg                                                          <= sp_end_reg + {{$clog2(`STACK_MEM_SIZE) - 1{1'b0}}, 1'b1};
            end
        end
    end
    // end of stack memory processing
    //
    // UART processing
    always @(posedge CLK_100MHz_in)
    begin
        if (cpu_reset_in) begin
            uart_data_out_adr_reg  <= {$clog2(`GP_REG_FILE_SIZE){1'b0}};
            uart_received_reg      <= 1'b0;
            uart_transmit_reg      <= 1'b0;
        end else begin
            if (op_cmd_2 == `UGET_cmd) begin
                uart_received_reg    <= 1'b1;
            end else begin
                uart_received_reg    <= 1'b0;
            end

            if (op_cmd_2 == `USEND_cmd) begin
                uart_data_out_adr_reg <= cmd_2_usend_reg_adr;
                uart_transmit_reg     <= 1'b1;
            end else begin
                uart_transmit_reg     <= 1'b0;
            end
        end
    end
    // end of UART processing
    //
    // end of the second stage of pipeline -> selection + execute + save (generate new data, address to write and 'we' signals)
    ////

endmodule
