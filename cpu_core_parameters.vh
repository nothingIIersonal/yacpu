`ifndef CPU_CORE_PARAMETERS_VH
`define CPU_CORE_PARAMETERS_VH


`define PC_REG_WIDTH          9                    // program counter                            // in bits
`define FLAGS_REG_WIDTH       4                    // flags register (LE, TQ, UR, UT)            // in bits
`define DATA_WIDTH            8                    // all data width (data memory, gp registers) // in bits
`define STACK_DATA_WIDTH      `PC_REG_WIDTH        // 9 bit for store return address and data    // in bits
`define COMMAND_WIDTH        32                    // command (instruction)                      // in bits
`define UART_RXTX_WIDTH       `DATA_WIDTH          // UART data in and data out width            // in bits

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
`define FJMP_cmd             16                    // fjmp .label, %flag                  : PC                   <- %flag ? .label : PC + 1
`define FNJMP_cmd            17                    // fnjmp .label, %flag                 : PC                   <- %flag ? PC + 1 : .label
`define JMP_cmd              18                    // jmp .label                          : PC                   <- .label
`define CALL_cmd             19                    // call .label                         : [SP_END]             <- PC + 1
                                                   //                                     : SP_END               <- SP_END - 1
                                                   //                                     : PC                   <- .label
`define RET_cmd              20                    // ret                                 : PC                   <- [SP_END + 1]
                                                   //                                     : [SP_END + 1]         <- 0
                                                   //                                     : SP_END               <- SP_END + 1
`define UGET_cmd             21                    // uget REG                            : in_uart_receive      <- (UART -> CPU) '1' if UART is ready to give data
                                                   //                                     : in_uart_data         <- (UART -> CPU) UART writes data to this bus
                                                   //                                     : out_uart_received    <- (CPU -> UART) '1' if CPU took data
`define USEND_cmd            22                    // usend REG                           : in_uart_transmitted  <- (UART -> CPU) '1' if UART sent data
                                                   //                                     : out_uart_tx_data        <- (CPU -> UART) CPU writes data to this bus
                                                   //                                     : out_uart_transmit    <- (CPU -> UART) '1' if CPU want to send data
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

    All unused bits (inluding common ones) can be initialized to 0 (see 'common unused bits' column).

    +------------------------------------------------------------------------------------------------+--------------------+
    |                                     common instruction                                         | common unused bits |
    +----------------------------+-------------------------------------------------------------------+--------------------+
    |       OPCODE               |                                   payload                         |         0          |
    |     5 (in bits)            |                                 24 (in bits)                      |     3 (in bits)    |
    +----------------------------+-------------------------------------------------------------------+--------------------+
*/


`endif