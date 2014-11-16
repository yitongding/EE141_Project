`include "Opcode.vh"
`include "const.vh"

module MemWHB (
	input [2:0] Funct,
	input [6:0] Opcode,
	input [31:0] MemWHBin,
	output [31:0] MemWHBout
);
	
	always @(*) begin
		if (Opcode == `OPC_STORE || Opcode == `OPC_LOAD) begin
			case (Funct)
				`FNC_LH:  MemWHBout = {{17{MemWHBin[15]}}, MemWHBin[14:0]};
				`FNC_LHU: MemWHBout = {16'd0, MemWHBin[15:0]};
				`FNC_LB:  MemWHBout = {{25{MemWHBin[7]}}, MemWHBin[6:0]};
				`FNC_LBU: MemWHBout = {24'd0, MemWHBin[7:0]};
				`FNC_SB:  MemWHBout = {24'd0, MemWHBin[7:0]};
				`FNC_SH:  MemWHBout = {16'd0, MemWHBin[15:0]};
				default:  MemWHBout = MemWHBin;
			endcase
		end else begin
			MemWHBout = MemWHBout;
		end
	end

endmodule 