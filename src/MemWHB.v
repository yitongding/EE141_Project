`include "Opcode.vh"
`include "const.vh"

module MemWHB (
	input [2:0] Funct,
	input [6:0] Opcode,
	input [31:0] Adr,
	input [31:0] MemWHBin,
	output reg [31:0] MemWHBout
);
	wire [1:0] Address;
	assign Address = Adr [1:0];

	always @(*) begin
		if (Opcode == `OPC_STORE) begin
			case (Funct)
				`FNC_SH:
					case(Address)
						2'b00: MemWHBout = MemWHBin;
						2'b01: MemWHBout = {8'b0,MemWHBin[15:0],8'b0};
						2'b10: MemWHBout = {MemWHBin[15:0],16'b0};
					endcase
				`FNC_SB:
					case(Address)
						2'b00: MemWHBout = MemWHBin;
						2'b01: MemWHBout = {16'b0,MemWHBin[7:0],8'b0};
						2'b10: MemWHBout = {8'b0,MemWHBin[7:0],16'b0};
						2'b11: MemWHBout = {MemWHBin[7:0],24'b0};
					endcase
				`FNC_SW: MemWHBout = MemWHBin;
			endcase
		end else if (Opcode == `OPC_LOAD) begin
			case (Funct)
				`FNC_LH:  
					case (Address)
						2'b00: MemWHBout = {{17{MemWHBin[15]}}, MemWHBin[14:0]};
						2'b01: MemWHBout = {{17{MemWHBin[23]}}, MemWHBin[22:8]};
						2'b10: MemWHBout = {{17{MemWHBin[31]}}, MemWHBin[30:16]};
					endcase 
				`FNC_LHU: 
					case (Address)
						2'b00: MemWHBout = {16'b0, MemWHBin[15:0]};
						2'b01: MemWHBout = {16'b0, MemWHBin[23:8]};
						2'b10: MemWHBout = {16'b0, MemWHBin[31:16]};
					endcase 
				`FNC_LB:
					case (Address)
						2'b00: MemWHBout = {{25{MemWHBin[7]}}, MemWHBin[6:0]};
						2'b01: MemWHBout = {{25{MemWHBin[15]}}, MemWHBin[14:8]};
						2'b10: MemWHBout = {{25{MemWHBin[23]}}, MemWHBin[22:16]};
						2'b11: MemWHBout = {{25{MemWHBin[31]}}, MemWHBin[30:24]};
					endcase 
				`FNC_LBU:
					case (Address)
						2'b00: MemWHBout = {24'b0, MemWHBin[7:0]};
						2'b01: MemWHBout = {24'b0, MemWHBin[15:8]};
						2'b10: MemWHBout = {24'b0, MemWHBin[23:16]};
						2'b11: MemWHBout = {24'b0, MemWHBin[31:24]};
					endcase 
				default:  MemWHBout = MemWHBin;
			endcase
		end else begin
			MemWHBout = MemWHBin;
		end
	end

endmodule 