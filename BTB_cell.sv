module BTB_cell
(
	input clk,
	
	input update,
	input [31:0] cmp_addr,
	input [31:0] update_addr,
	input [31:0] update_target,
	
	output cmp_match,
	output update_match,
	output [31:0] target
);

logic [31:0] internal_addr;
logic [31:0] internal_target;
assign cmp_match = (cmp_addr == internal_addr);
assign update_match = (update_addr == internal_addr);
assign target = internal_target;

register #(32) addr_reg
(
	.clk(clk),
	.load(update),
	.in(update_addr),
	.out(internal_addr)
);

register #(32) target_reg
(
	.clk(clk),
	.load(update),
	.in(update_target),
	.out(internal_target)
);

endmodule: BTB_cell