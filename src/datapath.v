`include "Opcode.vh"
`include "const.vh"

module datapath(
    input           clk, reset, stall,
    input   [10:0]  dpath_controls_i,
    input   [3:0]  exec_controls_x,
    input   [1:0]   hazard_controls,
    output  [31:0] datapath_contents,

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

//Control signal define
	wire BranchE, ALUSrcE, RegDstE, RegWriteE, MemWriteSrcE;
	wire [1:0] RegWriteSrcE;
	wire [3:0] ALUop, MemWriteE;
	
	assign BranchE = dpath_controls_i[8];
	assign ALUSrcE = dpath_controls_i[7];
	assign RegDstE = dpath_controls_i[1];
	assign RegWriteE = dpath_controls_i[6];
	assign RegWriteSrcE = dpath_controls_i[10:9];
	assign MemWriteE = dpath_controls_i[5:2];
	assign ALUop = exec_controls_x;
	


	
//------------------------------------------------------------------
//Instruction Stage
//------------------------------------------------------------------
	wire   [31:0]  PCF, InstrF, PCPlus4F;
	reg    [31:0]  PCReg, PC, PCBranchM;
	reg           PCSrcM;
	reg	   [31:0]  RegFile [31:0];			// RegFile define
	integer i;
	
	always @(posedge clk) begin
		if (reset) begin
			PC = `PC_RESET;
			PCBranchM = 0;
		end else if (stall) begin
			PC = PC;
		end else if (PCSrcM) begin
			PC = PCBranchM;
		end else begin
			PC = PCPlus4F;
		end
	end
	
	always @(posedge clk) begin
		if (reset) begin
			PCReg <= 0;
		end else begin
			PCReg <= PC;
		end
	end
	
	assign PCF = PCReg;
	assign PCPlus4F = 4 + PCF;
//icache	
	assign icache_addr = PC;
	assign icache_re = ~stall;
	assign InstrF = (stall)? `INSTR_NOP : icache_dout;
	
//-------------------------------------------------------------------
//Inst to Exe
//-------------------------------------------------------------------
	reg    [31:0]  InstrE, PCE;
	
	always @(posedge clk) begin
		if (reset) begin
			PCE <= 0;
			InstrE <= 0;
		end else begin
			PCE <= PCF;
			InstrE <= InstrF;
		end
	end
	
//-------------------------------------------------------------------
// Execute stage
//-------------------------------------------------------------------

	reg    [31:0]  SrcB;
	reg    [4:0]   WriteRegE;
	wire   [4:0]   A1, A2, Rs1, Rs2, Rd;
	wire   [31:0]  Imm;
	wire   [31:0]  SrcA, ALUOutE, WriteDataE;
	wire   [31:0]  ImmPro, PCBranchE;
	wire   [6:0]   Opcode;
	wire   [2:0]   Funct;
	wire           Add_rshift_type, Branchout;
	wire 		   PCSrcE;
	
	assign Rs1 = InstrE[19:15];
	assign Rs2 = InstrE[24:20];
	assign Rd  = InstrE[11:7];
	assign Imm = InstrE[31:0];
	assign A1 = Rs1;
	assign A2 = Rs2;
	assign SrcA = RegFile [A1];
	assign WriteDataE = RegFile [A2];
	assign PCBranchE = (Opcode == `OPC_JALR)? ALUOutE : (ImmPro + PCE);
	assign Opcode = InstrE[6:0];
	assign Funct = InstrE[14:12];
	assign Add_rshift_type = InstrE[30];
	assign PCSrcE = Branchout & BranchE;
	assign datapath_contents = InstrE;
	
	always @(*) begin
		if (reset) begin
			SrcB = 0;
			WriteRegE = 0;
		end else begin
		
			if (ALUSrcE) begin
				SrcB = ImmPro;
			end else begin
				SrcB = WriteDataE;
			end
			
			if (RegDstE) begin
				WriteRegE = Rd;
			end else begin
				WriteRegE = Rs2;
			end
		end
	end
	
	ImmProcess Dut2(
	.Imm(Imm),
	.opcode(Opcode),
	.ImmPro(ImmPro)
	);
	
	ALU Dut1(
	.ALUop(ALUop),
	.A(SrcA),
	.B(SrcB),
	.Out(ALUOutE)
	);
	
	BranchPro Dut5(
	.Opcode(Opcode),
	.Funct(Funct),
	.A(SrcA),
	.B(WriteDataE),
	.Branchout(Branchout)
	);
	

	
//-------------------------------------------------------------------
// Exe to Mem
//-------------------------------------------------------------------
	reg [4:0]  WriteRegM;
	reg [31:0] WriteDataM, ALUOutM;
	reg [1:0] RegWriteSrcM;
	reg RegWriteM;
	reg [3:0] MemWriteM;
	reg  [31:0] WD3;
	wire [4:0]  A3;
	
	always @(posedge clk) begin
		if (reset) begin
			WriteRegM <= 0;
			WriteDataM <= 0;
			ALUOutM <= 0;
			RegWriteSrcM <= 0;
			RegWriteM <= 0;
			MemWriteM  <= 0;
			csr_tohost = 0;
			
		end else begin
			WriteRegM <= WriteRegE;
			PCBranchM <= PCBranchE;
			WriteDataM <= WriteDataE;
			ALUOutM <= ALUOutE;
			RegWriteSrcM <= RegWriteSrcE;
			MemWriteM <= MemWriteE;
			PCSrcM <= PCSrcE;
			RegWriteM <= RegWriteE;
			if (Opcode == `OPC_CSR) begin
				case (Funct)
					`FNC_CSRRW: begin 
						csr_tohost <= RegFile[Rs1];
						RegFile[Rd] <= csr_tohost;
					end
					`FNC_CSRRWI: begin
						csr_tohost <= ImmPro;
					end
					`FNC_CSRRC: begin
						RegFile[Rd] <= csr_tohost;
						csr_tohost <= csr_tohost & (32'hffffffff-RegFile[Rs1]);
					end
				endcase
			end
			if (RegWriteM) begin
				RegFile[A3] = WD3;
			end
		end
		
	end
	
//-------------------------------------------------------------------
// Memory stage
//-------------------------------------------------------------------

	wire [31:0] ReadDataM;


	assign dcache_addr = ALUOutM;
	assign A3          = WriteRegM;
	assign dcache_we[3:0] = MemWriteM;
	assign dcache_re = (RegWriteSrcM == 2'b01);
	
	MemWHB Dut3 (
		.Funct(Funct),
		.Opcode(Opcode),
		.MemWHBin(WriteDataM),
		.MemWHBout(dcache_din)
	);
	
	MemWHB Dut4 (
		.Funct(Funct),
		.Opcode(Opcode),
		.MemWHBin(dcache_dout),
		.MemWHBout(ReadDataM)
	);
	
	
	always @(*) begin
		case (RegWriteSrcM)
			2'b00: WD3 = ALUOutM;
			2'b01: WD3 = ReadDataM;
			2'b10: WD3 = PCBranchM;
			2'b11: WD3 = PCBranchM + 4;
		endcase
	end
	
	
	


endmodule

