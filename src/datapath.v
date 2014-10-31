`include "Opcode.vh"
`include "const.vh"

module datapath(
    input           clk, reset, stall,
    input   [:0]  dpath_controls_i,
    input   [:0]  exec_controls_x,
    input   [:0]   hazard_controls,
    output  [:0] datapath_contents,

    // Memory system connections
    output [31:0]   dcache_addr,
    output [31:0]   icache_addr,
    output [3:0]    dcache_we,
    output          dcache_re,
    output          icache_re,
    output [31:0]   dcache_din,
    input [31:0]    dcache_dout,
    input [31:0]    icache_dout

);

//-------------------------------------------------------------------
// Control status registers (CSR)
//-------------------------------------------------------------------
    reg    [31:0]  csr_tohost;

/*
 Your implementation goes here:
*/

endmodule

