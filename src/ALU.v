// UC Berkeley CS150
// Lab 3, Fall 2014
// Module: ALU.v
// Desc:   32-bit ALU for the MIPS150 Processor
// Inputs: 
//    A: 32-bit value
//    B: 32-bit value
//    ALUop: Selects the ALU's operation 
// 						
// Outputs:
//    Out: The chosen function mapped to A and B.

`include "Opcode.vh"
`include "ALUop.vh"

module ALU(
    input [31:0] A,B,
    input [3:0] ALUop,
    output reg [31:0] Out
);

    // Implement your ALU here, then delete this comment
always @(*) begin
	case (ALUop)
		`ALU_ADD:  Out = A + B;
		`ALU_SUB:  Out = A - B;
		`ALU_AND:  Out = A & B;
		`ALU_OR:   Out = A | B;
		`ALU_XOR:  Out = A ^ B;
		`ALU_SLT:  Out = $signed(A) < $signed(B);
		`ALU_SLTU: Out = $unsigned(A) < $unsigned(B);
		`ALU_SLL:  Out = A <<< B[4:0];
		`ALU_SRA:  Out = $signed(A) >>> B[4:0];
		`ALU_SRL:  Out = A >> B[4:0];
		`ALU_COPY_B: Out = B;
		`ALU_XXX:  Out = 32'h00000000;
		default:   Out = 32'h00000000;
	endcase
end
endmodule
