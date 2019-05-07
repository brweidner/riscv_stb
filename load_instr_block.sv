import rv32i_types::*;

module load_instr_block
(
	input rv32i_word wb_mem_rdata,
	input rv32i_word wb_alu_out,
	input logic wb_sign_sel,
	input logic wb_load_op,
	output rv32i_word load_data_out
);
/* create internal signals here */
rv32i_word lh_upper, lh_lower, lhu_upper, lhu_lower, lb_0, lb_1, lb_2, lb_3, lbu_0, lbu_1, lbu_2, lbu_3;
rv32i_word load_half_signed_out, load_byte_signed_out, load_half_unsigned_out, load_byte_unsigned_out, load_signed_out, load_unsigned_out;

assign lh_upper = $signed(wb_mem_rdata[31:16]);
assign lh_lower = $signed(wb_mem_rdata[15:0]);
assign lhu_upper = {16'h0, wb_mem_rdata[31:16]};
assign lhu_lower = {16'h0, wb_mem_rdata[15:0]};	
assign lb_0 = $signed(wb_mem_rdata[7:0]);
assign lb_1 = $signed(wb_mem_rdata[15:8]);
assign lb_2 = $signed(wb_mem_rdata[23:16]);
assign lb_3 = $signed(wb_mem_rdata[31:24]);
assign lbu_0 = {24'h0, wb_mem_rdata[7:0]};
assign lbu_1 = {24'h0, wb_mem_rdata[15:8]};
assign lbu_2 = {24'h0, wb_mem_rdata[23:16]};
assign lbu_3 = {24'h0, wb_mem_rdata[31:24]};

mux2 load_half_signed
(
	.sel(wb_alu_out[1]),
	.a(lh_lower),
	.b(lh_upper),
	.f(load_half_signed_out)
);

mux4 load_byte_signed
(
	.sel(wb_alu_out[1:0]),
	.a(lb_0),
	.b(lb_1),
	.c(lb_2),
	.d(lb_3),
	.f(load_byte_signed_out)
);

mux2 load_half_unsigned
(
	.sel(wb_alu_out[1]),
	.a(lhu_lower),
	.b(lhu_upper),
	.f(load_half_unsigned_out)
);

mux4 load_byte_unsigned
(
	.sel(wb_alu_out[1:0]),
	.a(lbu_0),
	.b(lbu_1),
	.c(lbu_2),
	.d(lbu_3),
	.f(load_byte_unsigned_out)
);

mux2 load_signed
(
	.sel(wb_load_op),
	.a(load_half_signed_out),
	.b(load_byte_signed_out),
	.f(load_signed_out)
);

mux2 load_unsigned
(
	.sel(wb_load_op),
	.a(load_half_unsigned_out),
	.b(load_byte_unsigned_out),
	.f(load_unsigned_out)
);

mux2 load_instr_final
(
	.sel(wb_sign_sel),
	.a(load_signed_out),
	.b(load_unsigned_out),
	.f(load_data_out)
);
endmodule : load_instr_block