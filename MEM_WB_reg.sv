import rv32i_types::*;

module MEM_WB_reg
(
	input clk,
	input logic load,

	input rv32i_word mem_pc_out,
	input rv32i_control_word mem_ctrl_word,
	input rv32i_word mem_alu_out,
	input logic mem_br_en,
	input rv32i_word mem_u_imm,
	
	output rv32i_word wb_pc_out, 
	output rv32i_control_word wb_ctrl_word,
	output rv32i_word wb_alu_out,
	output logic wb_br_en,
	output rv32i_word wb_u_imm
);

register pc_out_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_pc_out),
	.out(wb_pc_out)
);

register #($bits(rv32i_control_word)) ctrl_word_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_ctrl_word),
	.out(wb_ctrl_word)
);

register alu_out_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_alu_out),
	.out(wb_alu_out)
);

register #(1) br_en_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_br_en),
	.out(wb_br_en)
);
/*
register memr_data_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_memr_data),
	.out(wb_memr_data)
);
*/
register u_imm_reg
(	
	.clk(clk),
	.load(load),
	.in(mem_u_imm),
	.out(wb_u_imm)
);

endmodule : MEM_WB_reg