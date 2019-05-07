import rv32i_types::*;

module mem_byte_enable_block
(
	input rv32i_word mem_alu_out,
	input [1:0] mem_store_op,
	output logic [3:0] mem_byte_enable
);

/* internal wires */
logic [3:0] store_half_out;
logic [3:0] store_byte_out;

mux2 #(4) store_half
(
	.sel(mem_alu_out[1]),
	.a(4'b0011),
	.b(4'b1100),
	.f(store_half_out)
);

mux4 #(4) store_byte
(
	.sel(mem_alu_out[1:0]),
	.a(4'b0001),
	.b(4'b0010),
	.c(4'b0100),
	.d(4'b1000),
	.f(store_byte_out)
);

mux4 #(4) store_op
(
	.sel(mem_store_op),
	.a(4'b0000),
	.b(store_half_out),
	.c(store_byte_out),
	.d(4'b1111),
	.f(mem_byte_enable)
);
endmodule : mem_byte_enable_block