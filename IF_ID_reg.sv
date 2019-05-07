module IF_ID_reg
(
	input clk,
	input logic load,

	input [31:0] if_pc_out,
	
	output logic [31:0] id_pc_out
);

register pc_out_reg
(	
	.clk(clk),
	.load(load),
	.in(if_pc_out),
	.out(id_pc_out)
);

endmodule : IF_ID_reg