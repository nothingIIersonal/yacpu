`ifndef MEMORY_MAPPING_VH
`define MEMORY_MAPPING_VH


`include "parameters.vh"


// UART
parameter MMIO_UART_BEGIN_ADDRESS_MASK  =                10'h0000_000x;
parameter MMIO_UART_END_ADDRESS_MASK    = MMIO_UART_BEGIN_ADDRESS_MASK;
parameter MMIO_UART_STATUS_ADDRESS_MASK =                10'h0000_0000; // [ 8b | xxxx_xxxY -> TXE ]
                                                                        // [ 8b | xxxx_xxYx -> RXE ]
                                                                        // [ 8b | xxxx_xYxx -> RXR ]
                                                                        // [ 8b | xxxx_Yxxx -> TXR ]
parameter MMIO_UART_RXD_ADDRESS_MASK    =                10'h0000_0001;
parameter MMIO_UART_TXD_ADDRESS_MASK    =                10'h0000_0002;
parameter MMIO_UART_BRR0_ADDRESS_MASK   =                10'h0000_0003; // [ 8b | -> 1st byte ]
parameter MMIO_UART_BRR1_ADDRESS_MASK   =                10'h0000_0004; // [ 8b | -> 2nd byte ]
//// UART


// I2C
parameter MMIO_I2C_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_I2C_END_ADDRESS_MASK   = 10'h0000_0000;
//// I2C


// I2S
parameter MMIO_I2S_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_I2S_END_ADDRESS_MASK   = 10'h0000_0000;
//// I2S


// SPI
parameter MMIO_SPI_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_SPI_END_ADDRESS_MASK   = 10'h0000_0000;
//// SPI


// PWM
parameter MMIO_PWM_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_PWM_END_ADDRESS_MASK   = 10'h0000_0000;
//// PWM


// GPIO
parameter MMIO_GPIO_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_GPIO_END_ADDRESS_MASK   = 10'h0000_0000;
//// GPIO


// HDMI
parameter MMIO_HDMI_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_HDMI_END_ADDRESS_MASK   = 10'h0000_0000;
//// HDMI


// TIM
parameter MMIO_TIM_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_TIM_END_ADDRESS_MASK   = 10'h0000_0000;
//// TIM


// WDT
parameter MMIO_WDT_BEGIN_ADDRESS_MASK = 10'h0000_0000;
parameter MMIO_WDT_END_ADDRESS_MASK   = 10'h0000_0000;
//// WDT


// STACK
parameter MMIO_STACK_BEGIN_ADDRESS_MASK =                 10'hFFFF_FDxx;
parameter MMIO_STACK_END_ADDRESS_MASK   = MMIO_STACK_BEGIN_ADDRESS_MASK;
//// STACK


// DATA
parameter MMIO_DATA_BEGIN_ADDRESS_MASK =                10'hFFFF_FExx;
parameter MMIO_DATA_END_ADDRESS_MASK   = MMIO_DATA_BEGIN_ADDRESS_MASK;
//// DATA


// PROGRAM
parameter MMIO_PROGRAM_BEGIN_ADDRESS_MASK =                   10'hFFFF_FFxx;
parameter MMIO_PROGRAM_END_ADDRESS_MASK   = MMIO_PROGRAM_BEGIN_ADDRESS_MASK;
//// PROGRAM


`endif