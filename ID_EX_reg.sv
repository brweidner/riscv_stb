import rv32i_types::*;

module ID_EX_reg
(
	input clk,
	input logic load,
	input logic hazard,
	input logic branch,

	input rv32i_word id_pc_out,
	input rv32i_control_word id_ctrl_word,
	input rv32i_word id_rs1_out,
	input rv32i_word id_rs2_out,
	input rv32i_word id_i_imm,
	input rv32i_word id_u_imm,
	input rv32i_word id_b_imm,
	input rv32i_word id_s_imm,
	input rv32i_word id_j_imm,
	
	
	output rv32i_word ex_pc_out, 
	output rv32i_control_word ex_ctrl_word,
	output rv32i_word ex_rs1_out,
	output rv32i_word ex_rs2_out,
	output rv32i_word ex_i_imm,
	output rv32i_word ex_u_imm,
	output rv32i_word ex_b_imm,
	output rv32i_word ex_s_imm,
	output rv32i_word ex_j_imm
);

logic [31:0] i_imm_out;
logic [31:0] pc_mux_out;

register pc_out_reg
(	
	.clk(clk),
	.load(load),
	.in(pc_mux_out),
	.out(ex_pc_out)
);

register #($bits(rv32i_control_word)) ctrl_word_reg
(	
	.clk(clk),
	.load(load),
	.in(id_ctrl_word),
	.out(ex_ctrl_word)
);

register rs1_out_reg
(	
	.clk(clk),
	.load(load),
	.in(id_rs1_out),
	.out(ex_rs1_out)
);

register rs2_out_reg
(	
	.clk(clk),
	.load(load),
	.in(id_rs2_out),
	.out(ex_rs2_out)
);

register i_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(i_imm_out),
	.out(ex_i_imm)
);

register u_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(id_u_imm),
	.out(ex_u_imm)
);

register b_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(id_b_imm),
	.out(ex_b_imm)
);

register s_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(id_s_imm),
	.out(ex_s_imm)
);

register j_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(id_j_imm),
	.out(ex_j_imm)
);

mux2 i_imm_mux
(
	.sel(hazard),
	.a(32'b0),
	.b(id_i_imm),
	.f(i_imm_out)
);

mux2 pc_mux
(
	.sel(~hazard | branch),
	.a(id_pc_out),
	.b(32'b0),
	.f(pc_mux_out)
);

endmodule : ID_EX_reg