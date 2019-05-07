module pipelined_cache_control
(
	input clk,
	input read,
	input write,
	input hit,
	input dirty,
	input resp,
	
	output logic write_out,
	output logic read_out,
	
	/* Control Signals */
	output logic resp_out,
	output logic addr_out_sel,
	output logic data_in_sel,
	
	/* Array Control Signals */
	output logic data_read,
	output logic [1:0] data_load,
	output logic dirty_read,
	output logic dirty_load,
	output logic LRU_read,
	output logic LRU_load,
	output logic tag_read,
	output logic tag_load,
	output logic valid_read,
	output logic valid_load,
	
	output logic dirty_in
);

enum int unsigned {
	load,
	miss_w,
	miss_r
} state, next_state;

always_comb begin: state_transitions
	next_state = state;
	case(state)
		load: begin
			if(read == 1 | write == 1) begin
				if(hit == 0) begin
					next_state = miss_w;
				end
			end
		end
		miss_w: begin
			if(dirty == 0) next_state = miss_r;
			if(resp == 1) next_state = miss_r;
		end
		miss_r: if(resp == 1) next_state = load;
		default: ;
	endcase
end

always_comb begin: state_actions
	/* Default assignments */
	read_out = 1'b0;
	write_out = 1'b0;
	
	resp_out = 1'b1;
	addr_out_sel = 1'b0;
	data_in_sel = 1'b0;
	
	data_read = 1'b1;
	data_load = 2'b00;
	dirty_read = 1'b1;
	dirty_load = 1'b0;
	dirty_in = 1'b0;
	LRU_read = 1'b1;
	LRU_load = 1'b0;
	tag_read = 1'b1;
	tag_load = 1'b0;
	valid_read = 1'b1;
	valid_load = 1'b0;
	
	/* State specific assignments */
	case(state)
		load: begin
			if(hit) begin
				LRU_load = 1'b1;
				if(write) data_load = 2'b01;
			end
			if(read == 1 | write == 1) begin
				if(hit == 0) begin
					resp_out = 1'b0;
				end
			end
			if(write) begin
				data_in_sel = 1'b0;
				dirty_in = 1'b1;
				dirty_load = 1'b1;
			end
		end
		miss_w: begin
			resp_out = 1'b0;
			write_out = 1'b1;
			addr_out_sel = 1'b1;
		end
		miss_r: begin
			resp_out = 1'b0;
			read_out = 1'b1;
			data_in_sel = 1'b1;
			data_load = 2'b10;
			tag_load = 1'b1;
			dirty_in = 1'b0;
			dirty_load = 1'b1;
			valid_load = 1'b1;
		end
		default: ;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule: pipelined_cache_control