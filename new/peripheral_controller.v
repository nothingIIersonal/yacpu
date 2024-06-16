`timescale 1ns / 1ps


module peripheral_controller
(
    input  wire in_clk,
    output reg  out_en
);


// SCnP
    scnp
    scnp_inst
    (
        .in_clk ( system_clk ),
        .in_rst ( system_rst )
    );
//// SCnP


endmodule
