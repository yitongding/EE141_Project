`include "Opcode.vh"
`include "const.vh"

module ImmProcess(
	input  [31:0] Imm,
	input  [6:0]  opcode,
	output [31:0] ImmPro
);

	always @(*) begin
		case (opcode)
			`OPC_LUI:       ImmPro = {Imm[31:12], 12'd0};
			`OPC_AUIPC:     ImmPro = {Imm[31:12], 12'd0};
			`OPC_JAL:       ImmPro = {{12{Imm[31]}}, Imm[19:12], Imm[20], Imm[30:25], Imm[24:21], 1'd0};
			`OPC_JALR:      ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			`OPC_BRANCH:    ImmPro = {{20{Imm[31]}}, Imm[7], Imm[30:25], Imm[11:8], 1'd0};
			`OPC_STORE:     ImmPro = {{21{Imm[31]}}, Imm[30:25], Imm[11:7]};
			`OPC_LOAD:      ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			`OPC_ARI_RTYPE: ImmPro = 32'd0;
			`OPC_ARI_ITYPE: ImmPro = {{21{Imm[31]}}, Imm[30:20]};
			default:        ImmPro = 32'd0;
		endcase
	end
	
	
endmodule 