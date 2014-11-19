
module Riscv141(
    input clk,
    input reset,

    // Memory system ports
    output [31:0] dcache_addr,
    output [31:0] icache_addr,
    output [3:0] dcache_we,
    output dcache_re,
    output icache_re,
    output [31:0] dcache_din,
    input [31:0] dcache_dout,
    input [31:0] icache_dout,
    input stall

);

/*
    This is an example of the connections between the controller and datapath, 
    feel free to modify anything internal to this module, 
    including the inputs and outputs of the controller and datapath
*/
    wire [63:0] datapath_contents;
    wire [10:0]   dpath_controls_i;
    wire [3:0]  exec_controls_x;
    wire [4:0]   hazard_controls;

    controller ctrl(
        .datapath_contents(datapath_contents),
        .dpath_controls_i(dpath_controls_i),
        .exec_controls_x(exec_controls_x),
        .hazard_controls(hazard_controls)
    );

    datapath dpath(
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .dpath_controls_i(dpath_controls_i),
        .exec_controls_x(exec_controls_x),
        .hazard_controls(hazard_controls),
        .datapath_contents(datapath_contents),
        .dcache_addr(dcache_addr),
        .icache_addr(icache_addr),
        .dcache_we(dcache_we),
        .dcache_re(dcache_re),
        .icache_re(icache_re),
        .dcache_din(dcache_din),
        .dcache_dout(dcache_dout),
        .icache_dout(icache_dout)
    );

endmodule
