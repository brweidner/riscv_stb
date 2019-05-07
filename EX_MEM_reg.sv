import rv32i_types::*;

module EX_MEM_reg
(
	input clk,
	input logic load,

	input rv32i_word ex_pc_out,
	input rv32i_control_word ex_ctrl_word,
	input rv32i_word ex_alu_out,
	input logic ex_br_en,
	input rv32i_word ex_mem_wdata,
	input rv32i_word ex_u_imm,
	
	output rv32i_word mem_pc_out, 
	output rv32i_control_word mem_ctrl_word,
	output rv32i_word mem_alu_out,
	output logic mem_br_en,
	output rv32i_word mem_mem_wdata,
	output rv32i_word mem_u_imm
);

register pc_out_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_pc_out),
	.out(mem_pc_out)
);

register #($bits(rv32i_control_word)) ctrl_word_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_ctrl_word),
	.out(mem_ctrl_word)
);

register alu_out_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_alu_out),
	.out(mem_alu_out)
);

register #(1) br_en_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_br_en),
	.out(mem_br_en)
);

register mem_wdata_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_mem_wdata),
	.out(mem_mem_wdata)
);

register u_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(ex_u_imm),
	.out(mem_u_imm)
);

endmodule : EX_MEM_reg