`include "Opcode.vh"
`include "const.vh"

module controller(
    input wire  [63:0] datapath_contents,
    output wire [10:0] dpath_controls_i,
    output wire [3:0] exec_controls_x,
    output wire [4:0] hazard_controls
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
	reg 	  Branch, ALUsrc, RegWrite;
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
				PCJALR = 1'b1;
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
				RegWriteSrc = 2'b00;
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
//--------------------
//Data Hazard
//--------------------
	wire [4:0] Old_Rd, New_Rs1, New_Rs2;
	wire [6:0] Old_Opcode;
	assign New_Rs1 = datapath_contents[19:15];
	assign New_Rs2 = datapath_contents[24:20];
	assign Old_Rd = datapath_contents[43:39];
	assign Old_Opcode = datapath_contents[38:32];
	reg  DhazardRs1, DhazardRs2;
	
	always @(*) begin
		if(Old_Opcode != `OPC_BRANCH && Old_Opcode != `OPC_STORE && Old_Opcode !=`OPC_JAL) begin
			case (Opcode)
				`OPC_ARI_RTYPE, `OPC_BRANCH: begin 
					DhazardRs1 = (New_Rs1 == Old_Rd) && (Old_Rd != 0);
					DhazardRs2 = (New_Rs2 == Old_Rd) && (Old_Rd != 0);
				end
				`OPC_ARI_ITYPE, `OPC_LOAD, `OPC_STORE, `OPC_JALR: begin
					DhazardRs1 = (New_Rs1 == Old_Rd) && (Old_Rd != 0);
					DhazardRs2 = 1'b0;
				end
				`OPC_JAL, `OPC_AUIPC, `OPC_LUI: begin 
					DhazardRs1 = 1'b0;
					DhazardRs2 = 1'b0;
				end
				default: begin 
					DhazardRs1 = 1'b0;
					DhazardRs2 = 1'b0;
				end
			endcase
		end else begin
			DhazardRs1 = 1'b0;
			DhazardRs2 = 1'b0;
		end
	end
	
//------------------
//Load Hazard
//------------------
	reg LHazardRs1, LHazardRs2, LHazardEn;
	
	always @(*) begin
		if (Old_Opcode == `OPC_LOAD) begin
			case (Opcode)
				`OPC_ARI_RTYPE, `OPC_BRANCH: begin 
					LHazardRs1 = New_Rs1 == Old_Rd;
					LHazardRs2 = New_Rs2 == Old_Rd;
					LHazardEn  = New_Rs1 == Old_Rd || New_Rs2 == Old_Rd;
				end
				`OPC_ARI_ITYPE, `OPC_LOAD, `OPC_STORE, `OPC_JALR: begin
					LHazardRs1 = New_Rs1 == Old_Rd;
					LHazardRs2 = 1'b0;
					LHazardEn  = New_Rs1 == Old_Rd;
				end
				`OPC_JAL, `OPC_AUIPC, `OPC_LUI: begin 
					LHazardRs1 = 1'b0;
					LHazardRs2 = 1'b0;
					LHazardEn  = 1'b0;
				end
				default: begin 
					LHazardRs1 = 1'b0;
					LHazardRs2 = 1'b0;
					LHazardEn  = 1'b0;
				end
			endcase
		end else begin
			LHazardRs1 = 1'b0;
			LHazardRs2 = 1'b0;
			LHazardEn  = 1'b0;
		end	
	end
	
	assign hazard_controls = {DhazardRs1, DhazardRs2, LHazardRs1, LHazardRs2, LHazardEn};
	
endmodule
