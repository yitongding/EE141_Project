`include "Opcode.vh"

module BranchPro(
input [6:0] Opcode,
input [2:0] Funct,
input [31:0] A,
input [31:0] B,
output reg Branchout
);

	always @(*) begin
		if(Opcode == `OPC_BRANCH) begin
			case (Funct)
				`FNC_BEQ:  Branchout = (A == B)? 1:0;
				`FNC_BNE:  Branchout = (A == B)? 0:1;
				`FNC_BLT:  Branchout = ($signed(A) < $signed(B))? 1:0;
				`FNC_BLTU: Branchout = ($unsigned(A) < $unsigned(B))? 1:0;
				`FNC_BGE:  Branchout = ($signed(A) < $signed(B))? 0:1;
				`FNC_BGEU: Branchout = ($unsigned(A) < $unsigned(B))? 0:1;
				default:   Branchout = 0;
			endcase
		end else if(Opcode == `OPC_JAL || Opcode ==`OPC_JALR) begin
			Branchout = 1;
		end else begin
			Branchout = 0;
		end
	end

endmodule
