// UC Berkeley CS150
// Lab 3, Fall 2014
// Module: ALUdecoder
// Desc:   Sets the ALU operation
// Inputs: opcode: the top 6 bits of the instruction
//         funct: the funct, in the case of r-type instructions
//         add_rshift_type: selects whether an ADD vs SUB, or an SRA vs SRL
// Outputs: ALUop: Selects the ALU's operation
//

`include "Opcode.vh"
`include "ALUop.vh"

module ALUdec(
  input [6:0]       opcode,
  input [2:0]       funct,
  input             add_rshift_type,
  output reg [3:0]  ALUop
);

  // Implement your ALU decoder here, then delete this comment

always @(*) begin
	case (opcode)
	
		`OPC_LUI: ALUop = `ALU_COPY_B;
		`OPC_AUIPC,`OPC_JAL,`OPC_JALR, `OPC_BRANCH, `OPC_LOAD, `OPC_STORE: ALUop = `ALU_ADD; 
		`OPC_ARI_RTYPE, `OPC_ARI_ITYPE:
			case (funct) 
			

				`FNC_AND:  ALUop = `ALU_AND;
				`FNC_OR:   ALUop = `ALU_OR;
				`FNC_XOR:  ALUop = `ALU_XOR;
				`FNC_SLT:  ALUop = `ALU_SLT;
				`FNC_SLL:  ALUop = `ALU_SLL;
				`FNC_SLTU: ALUop = `ALU_SLTU;
					
				`FNC_ADD_SUB:
					if (add_rshift_type) begin
						ALUop = `ALU_SUB;
					end else begin
						ALUop = `ALU_ADD;
					end
					
				`FNC_SRL_SRA:
					if (add_rshift_type) begin
						ALUop = `ALU_SRA;
					end else begin
						ALUop = `ALU_SRL;
					end	
			endcase
			
		default: ALUop = `ALU_XXX;
		
	endcase	
end
  
  
endmodule
