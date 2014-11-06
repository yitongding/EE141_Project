`include "Opcode.vh"
`include "const.vh"

module controller(
    input wire  [31:0] datapath_contents,
    output wire [10:0] dpath_controls_i,
    output wire [3:0] exec_controls_x,
    output wire [1:0] hazard_controls
);
	//input signal
	wire [6:0] Opcode;
	wire [2:0] Funct;
	wire       Add_rshift_type;
	
	assign Opcode = datapath_contents[6:0];
	assign Funct = datapath_contents[14:12];
	assign Add_rshift_type = datapath_contents[30];
	
	//output signal
	wire [3:0] ALUop;
	reg [3:0] MemWrite;
	reg [1:0] RegWriteSrc;
	reg 	   Branch, ALUsrc, RegWrite;
	reg       RegDst;
	reg       PCJALR;
	
	ALUdec Dut1(
	.opcode(Opcode),
	.funct(Funct),
	.add_rshift_type(Add_rshift_type),
	.ALUop(ALUop)
	);
	
	always @(*) begin
		case (Opcode)
			`OPC_ARI_RTYPE: begin 
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b0;
				Branch = 1'b0;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b00;
				PCJALR = 1'b0;
			end
			`OPC_ARI_ITYPE: begin
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b0;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b00;
				PCJALR = 1'b0;
			end
			`OPC_LOAD: begin
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b0;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b01;
				PCJALR = 1'b0;
			end
			`OPC_STORE: begin
				RegWrite = 1'b0;
				RegDst = 1'bx;
				ALUsrc = 1'b1;
				Branch = 1'b0;
				case (Funct)
					`FNC_SB: MemWrite = 4'b0001;
					`FNC_SH: MemWrite = 4'b0011;
					`FNC_SW: MemWrite = 4'b1111;
					default: MemWrite = 4'b0000;
				endcase
				RegWriteSrc = 2'b00;
				PCJALR = 1'b0;
			end
			`OPC_BRANCH: begin
				RegWrite = 1'b0;
				RegDst = 1'bx;
				ALUsrc = 1'b0;
				Branch = 1'b1;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b00;
				PCJALR = 1'b0;
			end
			`OPC_JAL: begin 
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b1;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b11;
				PCJALR = 1'b0;
			end
			`OPC_JALR: begin 
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b1;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b11;
				PCJALR = 1'b1;
			end
			`OPC_LUI: begin
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b0;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b00;
				PCJALR = 1'b0;
			end
			`OPC_AUIPC: begin 
				RegWrite = 1'b1;
				RegDst = 1'b1;
				ALUsrc = 1'b1;
				Branch = 1'b0;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b10;
				PCJALR = 1'b0;
			end
			default: begin 
				RegWrite = 1'b0;
				RegDst = 1'bx;
				ALUsrc = 1'bx;
				Branch = 1'bx;
				MemWrite = 4'b0000;
				RegWriteSrc = 2'b00;
				PCJALR = 1'bx;
			end
		endcase
	end
	
	assign dpath_controls_i = {RegWriteSrc, Branch, ALUsrc, RegWrite, MemWrite, RegDst, PCJALR};
	assign exec_controls_x = ALUop;
	assign hazard_controls = 2'b00;
	
	
endmodule
