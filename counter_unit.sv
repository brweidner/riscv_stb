module counter_unit
(
	input clk,
	input pipeline_continue,
	
	input branch_instruction,
	input branch_hazard,
	
	input [31:0] mem_address,
	input [31:0] data,
	input read,
	input write,
	
	output logic read_out,
	output logic write_out,
	output logic [31:0] data_out
);

/* logic signals */
logic swap;
logic swap_held;
logic [31:0] data_temp;
logic [31:0] data_temp_held;
logic stopped;

/* Counts */
int branch_count;
int branch_hazard_count;
int cache_miss_count;
int cycles_stalled_count;

/* initialization */
initial begin
	branch_count = 0;
	branch_hazard_count = 0;
	cache_miss_count = 0;
	cycles_stalled_count = 0;
end

always_comb begin
	data_out = data;
	if(swap_held) data_out = data_temp_held;
end

always_comb begin
	read_out = read;
	write_out = write;
	swap = 1'b0;
	data_temp = 32'b0;
	
	case(mem_address)
		32'h50: begin
			read_out = 1'b0;
			write_out = 1'b0;
			if(read) begin
				swap = 1'b1;
				data_temp = branch_count;
			end
		end
		
		32'h51: begin
			read_out = 1'b0;
			write_out = 1'b0;
			if(read) begin
				swap = 1'b1;
				data_temp = branch_hazard_count;
			end
		end
		
		32'h52: begin
			read_out = 1'b0;
			write_out = 1'b0;
			if(read) begin
				swap = 1'b1;
				data_temp = cache_miss_count;
			end
		end
		
		32'h53: begin
			read_out = 1'b0;
			write_out = 1'b0;
			if(read) begin
				swap = 1'b1;
				data_temp = cycles_stalled_count;
			end
		end
		
		default: ;
	endcase
end

always_ff @(posedge clk) begin
	if(branch_instruction) branch_count <= branch_count + 1;
	if(write && (mem_address == 32'h50)) branch_count <= 0;


	if(branch_hazard) branch_hazard_count <= branch_hazard_count + 1;
	if(write && (mem_address == 32'h51)) branch_hazard_count <= 0;

	
	if( (pipeline_continue == 1'b0) && (stopped == 1'b1) ) cache_miss_count <= cache_miss_count + 1;
	if(write && (mem_address == 32'h52)) cache_miss_count <= 0;
	
	if(pipeline_continue == 1'b0) cycles_stalled_count <= cycles_stalled_count + 1;
	if(write && (mem_address == 32'h53)) cycles_stalled_count <= 0;
end

register #(32) data_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.in(data_temp),
	.out(data_temp_held)
);

register #(1) stopped_reg
(
	.clk(clk),
	.load(1'b1),
	.in(pipeline_continue),
	.out(stopped)
);

register #(1) swap_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.in(swap),
	.out(swap_held)
);

endmodule: counter_unit