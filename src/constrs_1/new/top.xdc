set_property PACKAGE_PIN E3 [get_ports {CLK_100MHz_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {CLK_100MHz_in}]

set_property PACKAGE_PIN C12 [get_ports {RST_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {RST_in}]

set_property PACKAGE_PIN P17 [get_ports {FLASH_ENABLE_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_ENABLE_in}]

set_property PACKAGE_PIN C4 [get_ports {UART_TXD_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {UART_TXD_in}]

set_property PACKAGE_PIN D4 [get_ports {UART_RXD_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {UART_RXD_out}]

set_property PACKAGE_PIN M16 [get_ports {cpu_working_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_working_out}]

set_property PACKAGE_PIN N15 [get_ports {cpu_flashing_out}]
set_property IOSTANDARD LVCMOS33 [get_ports {cpu_flashing_out}]

set_property PACKAGE_PIN T10 [get_ports {SEG[0]}]
set_property PACKAGE_PIN R10 [get_ports {SEG[1]}]
set_property PACKAGE_PIN K16 [get_ports {SEG[2]}]
set_property PACKAGE_PIN K13 [get_ports {SEG[3]}]
set_property PACKAGE_PIN P15 [get_ports {SEG[4]}]
set_property PACKAGE_PIN T11 [get_ports {SEG[5]}]
set_property PACKAGE_PIN L18 [get_ports {SEG[6]}]
set_property PACKAGE_PIN H15 [get_ports {SEG[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {SEG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG[7]}]

set_property PACKAGE_PIN J17 [get_ports {AN[0]}]
set_property PACKAGE_PIN J18 [get_ports {AN[1]}]
set_property PACKAGE_PIN T9  [get_ports {AN[2]}]
set_property PACKAGE_PIN J14 [get_ports {AN[3]}]
set_property PACKAGE_PIN P14 [get_ports {AN[4]}]
set_property PACKAGE_PIN T14 [get_ports {AN[5]}]
set_property PACKAGE_PIN K2  [get_ports {AN[6]}]
set_property PACKAGE_PIN U13 [get_ports {AN[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {AN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {AN[7]}]

create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports {CLK_100MHz_in}]