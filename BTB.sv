module BTB
(
	input clk,
	
	input update,
	input [31:0] cmp_addr,
	input [31:0] update_addr,
	input [31:0] target_addr,
	
	output logic match,
	output logic [31:0] target
);

int next_update;
logic [15:0] split_update;
logic [15:0] split_cmp_match;
logic [15:0] split_update_match;
logic [15:0][31:0] split_target;

initial begin
	next_update = 0;
end

/* Update Logic */
always_comb begin
	split_update = 16'b0;
	case(split_update_match)
		16'b0000000000000001: split_update[0] = update;
		16'b0000000000000010: split_update[1] = update;
		16'b0000000000000100: split_update[2] = update;
		16'b0000000000001000: split_update[3] = update;
		16'b0000000000010000: split_update[4] = update;
		16'b0000000000100000: split_update[5] = update;
		16'b0000000001000000: split_update[6] = update;
		16'b0000000010000000: split_update[7] = update;
		16'b0000000100000000: split_update[8] = update;
		16'b0000001000000000: split_update[9] = update;
		16'b0000010000000000: split_update[10] = update;
		16'b0000100000000000: split_update[11] = update;
		16'b0001000000000000: split_update[12] = update;
		16'b0010000000000000: split_update[13] = update;
		16'b0100000000000000: split_update[14] = update;
		16'b1000000000000000: split_update[15] = update;
		default: split_update[next_update] = update;
	endcase
end

always_ff @(posedge clk)
begin
	if(split_update[next_update] == 1'b1) next_update = (next_update + 1) % 16;
end

/* Target Logic */
always_comb begin
	match = 1'b0;
	if(split_cmp_match != 5'b0) match = 1'b1;
	
	target = 32'bX;
	case(split_cmp_match)
		16'b0000000000000001: target = split_target[0][31:0];
		16'b0000000000000010: target = split_target[1][31:0];
		16'b0000000000000100: target = split_target[2][31:0];
		16'b0000000000001000: target = split_target[3][31:0];
		16'b0000000000010000: target = split_target[4][31:0];
		16'b0000000000100000: target = split_target[5][31:0];
		16'b0000000001000000: target = split_target[6][31:0];
		16'b0000000010000000: target = split_target[7][31:0];
		16'b0000000100000000: target = split_target[8][31:0];
		16'b0000001000000000: target = split_target[9][31:0];
		16'b0000010000000000: target = split_target[10][31:0];
		16'b0000100000000000: target = split_target[11][31:0];
		16'b0001000000000000: target = split_target[12][31:0];
		16'b0010000000000000: target = split_target[13][31:0];
		16'b0100000000000000: target = split_target[14][31:0];
		16'b1000000000000000: target = split_target[15][31:0];
		default: ;
	endcase
end

/* Array */
BTB_cell array[16]
(
	clk,
	
	split_update,
	cmp_addr,
	update_addr,
	target_addr,
	
	split_cmp_match,
	split_update_match,
	split_target
);

endmodule: BTB