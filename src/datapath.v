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

//Control signal define
	PCSrc;
	ALUSrcE;
	RegDstE;


	
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
		end else if (PCSrc) begin
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
	assign icache_re = 1;
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
	wire   [3:0]   ALUop;
	wire           Add_rshift_type;
	
	assign Rs1 = InstrE[19:15];
	assign Rs2 = InstrE[14:20];
	assign Rd  = InstrE[11:7];
	assign Imm = InstrE[31:0];
	assign A1 = Rs1;
	assign A2 = Rs2;
	assign SrcA = RegFile [A1];
	assign WriteDataE = RegFile [A2];
	assign PCBranchE = ImmPro + PCE;
	assign Opcode = InstrE[6:0];
	assign Funct = InstrE[14:12];
	assign Add_rshift_type = InstrE[30];
	
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
		
		ImmProcess(Imm, Opcode, ImmPro);
		
	end
	
	ALUdec Dut1(
	.opcode(Opcode),
	.funct(Funct),
	.add_rshift_type(Add_rshift_type),
	.ALUop(ALUop)
	);
	
	ALUop Dut2(
	.ALUop(ALUop),
	.A(SrcA),
	.B(SrcB),
	.Out(ALUOutE)
	);
	
	task ImmProcess;
		input  [31:0] Imm;
		input  [6:0]  opcode;
		output [31:0] ImmPro;
		
		case (opcode)
			`OPC_LUI:       ImmPro = {Imm[31:12], 12d'0};
			`OPC_AUIPC:     ImmPro = {Imm[31:12], 12d'0};
			`OPC_JAL:       ImmPro = {{12{Imm[31]}}, Imm[19:12], Imm[20], Imm[30:25], Imm[24:21], 1'd0};
			`OPC_JALR:      ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			`OPC_BRANCH:    ImmPro = {{20{Imm[31]}}, Imm[7], Imm[30:25], Imm[11:8], 1'd0};
			`OPC_STORE:     ImmPro = {{21{Imm[31]}}, Imm[30:25], Imm[11:7]};
			`OPC_LOAD:      ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			`OPC_ARI_RTYPE: ImmPro = 32'd0;
			`OPC_ARI_ITYPE: ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			default:        ImmPro = 32'd0;
		endcase
	endtask
	
//-------------------------------------------------------------------
// Exe to Mem
//-------------------------------------------------------------------
	reg [4:0]  WriteRegM;
	reg [31:0] PCBranchM, WriteDataM, ALUOutM;
	
	always @(posedge) begin
		WriteRegM <= WriteRegE;
		PCBranchM <= PCBranchE;
		WriteDataM <= WriteDataE;
		ALUOutM <= ALUOutE;
	end
	
//-------------------------------------------------------------------
// Memory stage
//-------------------------------------------------------------------

	
	


	
	
	
	
	
endmodule

