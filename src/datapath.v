`include "Opcode.vh"
`include "const.vh"

module datapath(
    input           clk, reset, stall,
    input   [7:0]  dpath_controls_i,
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
    //reg    [31:0]  csr_tohost;

/*
 Your implementation goes here:
*/

//Control signal define
	wire BranchE, ALUSrcE, RegDstE, RegWriteE, MemWriteSrcE, MemWriteE;
	wire [1:0] RegWriteSrcE;
	wire [3:0] ALUop;
	
	assign BranchE = dpath_controls_i[5];
	assign ALUSrcE = dpath_controls_i[4];
	assign RegDstE = dpath_controls_i[1];
	assign RegWriteE = dpath_controls_i[3];
	assign RegWriteSrcE = dpath_controls_i[7:6];
	assign MemWriteE = dpath_controls_i[2];
	assign ALUop = exec_controls_x;
	


	
//------------------------------------------------------------------
//Instruction Stage
//------------------------------------------------------------------
	wire   [31:0]  PC, PCF, InstrF, PCPlus4F;
	reg    [31:0]  PCReg;
	wire           PCSrc;
	
	always @(*) begin
		if (reset) begin
			PC = `PC_RESET;
		end else if (stall) begin
			PC = PC;
		end else if (PCSrcM) begin
			PC = PCBranchM;
		end else begin
			PC = PCPlus4F;
		end
	end
	
	always @(posedge clk) begin
		PCReg <= PC;
	end
	
	assign PCF = PCReg;
	assign PCPlus4F = 4 + PCF;
//icache	
	assign icache_addr = PC;
	assign icache_re = ~stall;
	always @(*) begin
		if (stall) begin
			InstrF = `INSTR_NOP;
		end else begin
			InstrF = icache_dout;
		end
	end
	
//-------------------------------------------------------------------
//Inst to Exe
//-------------------------------------------------------------------
	reg    [31:0]  InstrE, PCE;
	
	always @(posedge clk) begin
		PCE <= PCF;
		InstrE <= InstrF;
	end
	
//-------------------------------------------------------------------
// Execute stage
//-------------------------------------------------------------------

	reg	   [31:0]  RegFile [31:0];			// RegFile define
	wire   [4:0]   A1, A2, Rs1, Rs2, Rd;
	wire   [31:0]  Imm;
	wire   [31:0]  SrcA, SrcB, ALUOutE, WriteDataE;
	wire   [31:0]  WriteRegE, ImmPro, PCBranchE;
	wire   [6:0]   Opcode;
	wire   [2:0]   Funct;
	wire           Add_rshift_type, Branchout;
	
	assign Rs1 = InstrE[19:15];
	assign Rs2 = InstrE[14:20];
	assign Rd  = InstrE[11:7];
	assign Imm = InstrE[31:0];
	assign A1 = Rs1;
	assign A2 = Rs2;
	assign SrcA = RegFile [A1];
	assign WriteDataE = RegFile [A2];
	assign PCBranchE = (PCJALRE)? ALUoutE : (ImmPro + PCE);
	assign Opcode = InstrE[6:0];
	assign Funct = InstrE[14:12];
	assign Add_rshift_type = InstrE[30];
	assign PCSrcE = Branchout & Branch;
	assign datapath_contents = InstrE;
	
	always @(*) begin
		
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
	
	ImmProcess Dut2(
	.Imm(Imm),
	.opcode(Opcode),
	.ImmPro(ImmPro)
	);
	
	ALUop Dut1(
	.ALUop(ALUop),
	.A(SrcA),
	.B(SrcB),
	.Out(ALUOutE)
	);
	
	BranchPro Dut5(
	.Opcode(Opcode),
	.Funct(Funct),
	.A(SrcA),
	.B(WriteDataE)
	.Branchout(Branchout)
	);
	

	
//-------------------------------------------------------------------
// Exe to Mem
//-------------------------------------------------------------------
	reg [4:0]  WriteRegM;
	reg [31:0] PCBranchM, WriteDataM, ALUOutM;
	reg [1:0] RegWriteSrcM;
	reg MemWriteM, PCSrcM, RegWriteM;
	always @(posedge) begin
		WriteRegM <= WriteRegE;
		PCBranchM <= PCBranchE;
		WriteDataM <= WriteDataE;
		ALUOutM <= ALUOutE;
		RegWriteSrcM = RegWriteSrcE;
		MemWriteM = MemWriteE;
		PCSrcM = PCSrcE;
		RegWriteM = RegWriteE;
	end
	
//-------------------------------------------------------------------
// Memory stage
//-------------------------------------------------------------------

	wire [31:0] A3, WD3;

	assign dcache_addr = ALUOutM;
	assign A3          = WriteRegM;
	assign dcache_we[3:0] = {4{MemWriteM}};
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
	
	always @(posedge clk) begin
		if (RegWriteM) begin
			RegFile[A3] = WD3;
		end
	end
	
	


endmodule

