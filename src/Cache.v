`define ceilLog2(x) ( \
(x) > 2**30 ? 31 : \
(x) > 2**29 ? 30 : \
(x) > 2**28 ? 29 : \
(x) > 2**27 ? 28 : \
(x) > 2**26 ? 27 : \
(x) > 2**25 ? 26 : \
(x) > 2**24 ? 25 : \
(x) > 2**23 ? 24 : \
(x) > 2**22 ? 23 : \
(x) > 2**21 ? 22 : \
(x) > 2**20 ? 21 : \
(x) > 2**19 ? 20 : \
(x) > 2**18 ? 19 : \
(x) > 2**17 ? 18 : \
(x) > 2**16 ? 17 : \
(x) > 2**15 ? 16 : \
(x) > 2**14 ? 15 : \
(x) > 2**13 ? 14 : \
(x) > 2**12 ? 13 : \
(x) > 2**11 ? 12 : \
(x) > 2**10 ? 11 : \
(x) > 2**9 ? 10 : \
(x) > 2**8 ? 9 : \
(x) > 2**7 ? 8 : \
(x) > 2**6 ? 7 : \
(x) > 2**5 ? 6 : \
(x) > 2**4 ? 5 : \
(x) > 2**3 ? 4 : \
(x) > 2**2 ? 3 : \
(x) > 2**1 ? 2 : \
(x) > 2**0 ? 1 : 0)

module cache #
(
  parameter LINES = 64,
  parameter CPU_WIDTH = `CPU_INST_BITS,
  parameter WORD_ADDR_BITS = `CPU_ADDR_BITS-`ceilLog2(`CPU_INST_BITS/8)
)
(
  input clk,
  input reset,

  input                       cpu_req_val,
  output                      cpu_req_rdy,
  input [WORD_ADDR_BITS-1:0]  cpu_req_addr,
  input [CPU_WIDTH-1:0]       cpu_req_data,
  input [3:0]                 cpu_req_write,

  output                      cpu_resp_val,
  output [CPU_WIDTH-1:0]      cpu_resp_data,

  output                      mem_req_val,
  input                       mem_req_rdy,
  output [WORD_ADDR_BITS-1:`ceilLog2(`MEM_DATA_BITS/CPU_WIDTH)] mem_req_addr,
  output                           mem_req_rw,
  output                           mem_req_data_valid,
  input                           mem_req_data_ready,
  output [`MEM_DATA_BITS-1:0]      mem_req_data_bits,
  // byte level masking
  output [(`MEM_DATA_BITS/8)-1:0]  mem_req_data_mask,
  // avoid sending 512 bits, only send 128, but need
  // to say which 128
  output  [1:0]                    mem_req_data_offset,

  input                       mem_resp_val,
  input                       mem_resp_nack,
  input [`MEM_DATA_BITS-1:0]  mem_resp_data
);

  localparam CL_SIZE = `MEM_DATA_BITS*`MEM_DATA_CYCLES/8;
  localparam LG_LINES = `ceilLog2(LINES);
  localparam LG_REFILL_CYCLES = `ceilLog2(`MEM_DATA_CYCLES);

  localparam STATE_READY = 0;
  localparam STATE_REQUEST_WAIT = 1;
  localparam STATE_REFILL_WAIT = 2;
  localparam STATE_REFILL = 3;
  localparam STATE_RESET = 4;
  localparam STATE_RESOLVE_MISS = 5;
  localparam STATE_NACKED = 6;
  localparam STATE_WRITE = 7;

  localparam OFFLSB = 0;
  localparam OFFMSB = OFFLSB-1+`ceilLog2(CL_SIZE*8/CPU_WIDTH);
  localparam IDXLSB = OFFMSB+1;
  localparam IDXMSB = IDXLSB-1+`ceilLog2(LINES);
  localparam TAGLSB = IDXMSB+1;
  localparam TAGMSB = `CPU_ADDR_BITS-1-`ceilLog2(CPU_WIDTH/8);
  localparam TAGBITS = TAGMSB-TAGLSB+1;
  localparam DATAIDXLSB = `ceilLog2(`MEM_DATA_BITS/CPU_WIDTH);
  localparam MEM_REQ_LSB = `ceilLog2(CL_SIZE*8/CPU_WIDTH);

  reg [TAGMSB:0] r_cpu_req_addr;
  reg r_cpu_req_val;
  reg [3:0] r_cpu_req_write;
  reg [`MEM_DATA_BITS-1:0] r_cpu_req_data;

  reg [2:0] state, next_state;
  reg [LG_REFILL_CYCLES-1:0] refill_count;
  reg [LG_LINES-1:0] reset_count;

  always @(*) begin
    case(state)
      STATE_READY: next_state = mem_req_data_valid ? STATE_WRITE : ~mem_req_val ? STATE_READY : mem_req_rdy ? STATE_REFILL_WAIT : STATE_REQUEST_WAIT;
      STATE_REQUEST_WAIT: next_state = ~mem_req_rdy ? STATE_REQUEST_WAIT : STATE_REFILL_WAIT;
      STATE_RESOLVE_MISS: next_state = STATE_READY;
      STATE_REFILL_WAIT: next_state = mem_resp_val ? STATE_REFILL : mem_resp_nack ? STATE_NACKED : STATE_REFILL_WAIT;
      STATE_NACKED: next_state = mem_req_rdy ? STATE_REFILL_WAIT : STATE_NACKED;
      STATE_REFILL: next_state = refill_count == {LG_REFILL_CYCLES{1'b1}} ? STATE_RESOLVE_MISS : STATE_REFILL;
      STATE_RESET: next_state = reset_count == {LG_LINES{1'b1}} ? STATE_READY : STATE_RESET;
      // wait until see not ready anymore
      STATE_WRITE: next_state = ~mem_req_data_ready ? STATE_WRITE :STATE_READY;
      default: next_state = 3'bx;
    endcase
  end

  always @(posedge clk) begin
    if(reset)
      state <= STATE_RESET;
    else
      state <= next_state;

    if(reset)
      reset_count <= {LG_LINES{1'b0}};
    else if(state == STATE_RESET)
      reset_count <= reset_count + 1'b1;

    if(reset)
      refill_count <= {LG_REFILL_CYCLES{1'b0}};
    else if(mem_resp_val)
      refill_count <= refill_count + 1'b1;

    if(cpu_req_val && (next_state == STATE_READY))
      r_cpu_req_addr <= cpu_req_addr;

    if(reset) begin
      r_cpu_req_val <= 1'b0;
      r_cpu_req_write <= 4'b0;
      r_cpu_req_data <= 1'b0;
    end else if(cpu_req_rdy) begin
      r_cpu_req_val <= cpu_req_val;
      r_cpu_req_write <= cpu_req_write;
      r_cpu_req_data <= cpu_req_data;
    end

  end

  wire tag_we = state == STATE_RESET || state == STATE_REFILL_WAIT && mem_resp_val;
  wire [TAGBITS:0] tag_wdata = state == STATE_RESET ? {TAGBITS+1{1'b0}} : {1'b1,r_cpu_req_addr[TAGMSB:TAGLSB]};
  wire [TAGBITS:0] tag_out;
  wire tag_match = tag_out[TAGBITS-1:0] == r_cpu_req_addr[TAGMSB:TAGLSB] && tag_out[TAGBITS];
  wire [IDXMSB:IDXLSB] tag_idx = state == STATE_RESET ? reset_count :
                                 next_state == STATE_READY ? cpu_req_addr[IDXMSB:IDXLSB] :
                                 r_cpu_req_addr[IDXMSB:IDXLSB];

  wire [10:0] dummy;
  SRAM1RW64x32 tags
  (
    .A(tag_idx),
    .CE(clk),
    .WEB(~tag_we),
    .OEB(1'b0),
    .CSB(1'b0),
    .I({11'd0,tag_wdata}),
    .O({dummy,tag_out})
  );

  wire [IDXMSB:DATAIDXLSB] data_idx =
          next_state == STATE_WRITE || state == STATE_RESOLVE_MISS || (state == STATE_READY && ~cpu_req_val) ? r_cpu_req_addr[IDXMSB:DATAIDXLSB] : (next_state == STATE_READY ? cpu_req_addr[IDXMSB:DATAIDXLSB] :
          {r_cpu_req_addr[IDXMSB:IDXLSB],refill_count});
  wire [`MEM_DATA_BITS-1:0] data_out;

  wire data_hit;
  // Write if hit, or if refill
  assign data_hit = (mem_req_data_valid & mem_req_rw & tag_match);
  wire [`MEM_DATA_BITS-1:0]  data_din;
  assign data_din = data_hit ? mem_req_data_bits : mem_resp_data;
  wire [15:0] data_mask;
  assign data_mask = data_hit ? mem_req_data_mask : 16'hFFFF;

  SRAM1RW256x128 data (
    .A(data_idx),
    .CE(clk),
    .WEB(~(mem_resp_val | data_hit)),
    .BYTEMASK(data_mask),
    .OEB(1'b0),
    .CSB(1'b0),
    .I(data_din),
    .O(data_out)
  );

  assign cpu_resp_val = r_cpu_req_val & tag_match & (state == STATE_READY);
  assign mem_req_val = r_cpu_req_val & ~tag_match & (state == STATE_READY | state == STATE_REQUEST_WAIT) |
                       (state == STATE_NACKED) | (state == STATE_WRITE);
  assign mem_req_data_valid = r_cpu_req_val & ((state == STATE_READY) & |r_cpu_req_write) | state == STATE_WRITE;
  // For reads, always start at the beginning of a 512 bit chunk
  // but for writes, keep the lower 2 bits around to only address the
  // correct 128 bit chunk
  // TODO: need to hold for 2 cycles now, but should only be 1
  assign mem_req_addr = (state == STATE_WRITE | next_state == STATE_WRITE) ? {r_cpu_req_addr[TAGMSB:2]} : {r_cpu_req_addr[TAGMSB:MEM_REQ_LSB], {MEM_REQ_LSB-DATAIDXLSB{1'b0}}};
  assign cpu_req_rdy = (state == STATE_WRITE || state == STATE_READY) && next_state == STATE_READY;
  wire [31:0] debug_msb;
  assign debug_msb =  r_cpu_req_addr[DATAIDXLSB-1:0]*CPU_WIDTH;
  // TODO
  assign mem_req_rw = next_state == STATE_WRITE;
  assign mem_req_data_offset = r_cpu_req_addr[3:2];

  generate
    genvar i;
    for(i = 0; i < CPU_WIDTH; i=i+1) begin : foo
      assign cpu_resp_data[i] = data_out[r_cpu_req_addr[DATAIDXLSB-1:0]*CPU_WIDTH+i];
    end
  endgenerate

  generate
    for(i = 0; i < `MEM_DATA_BITS; i=i+1) begin : foo2
      assign mem_req_data_bits[i] = (i < (debug_msb+CPU_WIDTH+1)) & (i >= (debug_msb)) ? r_cpu_req_data[i-debug_msb] : 1'b0;
    end
  endgenerate

  generate
    for(i = 0; i < 16; i=i+1) begin : foo3
      assign mem_req_data_bits[i] = (i < (debug_msb+CPU_WIDTH+1)) & (i >= (debug_msb)) ? r_cpu_req_data[i-debug_msb] : 1'b0;
      assign mem_req_data_mask[i] = (i*8 < (debug_msb+CPU_WIDTH)) & (i*8 >= (debug_msb)) & r_cpu_req_write[i%4] ? 1'b1 : 1'b0;

    end
  endgenerate

endmodule
