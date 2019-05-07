
module L2_cache_control (
	input clk,
	
	input mem_read,
	input mem_write,
	output logic mem_resp,
	output logic pmem_read,
	output logic pmem_write,
	input pmem_resp,

	input hit,
	input dirty,
	
	output logic data_read,
	output logic data_load,
	output logic dirty_read,
	output logic dirty_load,
	output logic LRU_read,
	output logic LRU_load,
	output logic tag_read,
	output logic tag_load,
	output logic valid_read,
	output logic valid_load,
	
	output logic data_in_sel,
	output logic dirty_in,
	output logic paddr_sel,
	output logic prefetch_toggle,
	output logic prefetch_load
);

logic mem_req;
assign mem_req = mem_read | mem_write;

enum int unsigned {
	index,
	way_sel,
	decide,
	write_back,
	read
/*
	prefetch_i,
	prefetch_ws,
	prefetch_d,
	prefetch_wb,
	prefetch_r
*/
} state, next_state;

always_comb begin: state_actions
	prefetch_toggle = 1'b0;
	prefetch_load = 1'b0;

	pmem_read = 1'b0;
	pmem_write = 1'b0;
	mem_resp = 1'b0;

	data_read = 1'b1;
	data_load = 1'b0;
	data_in_sel = 1'b0;
	dirty_read = 1'b1;
	dirty_load = 1'b0;
	LRU_read = 1'b1;
	LRU_load = 1'b0;
	tag_read = 1'b1;
	tag_load = 1'b0;
	valid_read = 1'b1;
	valid_load = 1'b0;
	
	dirty_in = 1'b0;
	paddr_sel = 1'b0;
	
	case(state)
		index: prefetch_load = 1'b1;
		
		way_sel: ;
		
		decide: begin
			if(hit) begin
				LRU_load = 1'b1;
				mem_resp = 1'b1;
				if(mem_write) begin
					data_load = 1'b1;
					dirty_in = 1'b1;
					dirty_load = 1'b1;
				end
			end
		end
		
		write_back: begin
			if(dirty) begin
				pmem_write = 1'b1;
				paddr_sel = 1'b1;
			end
		end
		
		read: begin
			pmem_read = 1'b1;
			data_in_sel = 1'b1;
			data_load = 1'b1;
			tag_load = 1'b1;
			dirty_in = 1'b0;
			dirty_load = 1'b1;
			valid_load = 1'b1;
		end
	
/*	
		prefetch_i: begin
			prefetch_toggle = 1'b1;
		end
		
		prefetch_ws: begin
			prefetch_toggle = 1'b1;
		end
		
		prefetch_d: begin
			prefetch_toggle = 1'b1;
		end
		
		prefetch_wb: begin
			prefetch_toggle = 1'b1;
			if(dirty) begin
				pmem_write = 1'b1;
				paddr_sel = 1'b1;
			end
		end
		
		prefetch_r: begin
			prefetch_toggle = 1'b1;
			pmem_read = 1'b1;
			data_in_sel = 1'b1;
			data_load = 1'b1;
			tag_load = 1'b1;
			dirty_in = 1'b0;
			dirty_load = 1'b1;
			valid_load = 1'b1;
		end
*/
		
		default: ;
	endcase
end

always_comb begin: state_transitions
	next_state = state;
	case(state)
		index: begin
			if(mem_req == 1'b1)
				next_state = way_sel;
		end
		
		way_sel: next_state = decide;
		
		decide: begin
			next_state = write_back;
			if(hit)
				next_state = index;
		end
		
		write_back: begin
			if(dirty == 1'b0)
				next_state = read;
			if(pmem_resp == 1'b1)
				next_state = read;
		end
		
		read: begin
			if(pmem_resp == 1'b1)
				next_state = index;
		end
		
/*
		prefetch_i: begin
			next_state = prefetch_ws;
		end
		
		prefetch_ws: begin
			next_state = prefetch_d;
		end
		
		prefetch_d: begin
			next_state = prefetch_wb;
			if(hit)
				next_state = index;
		end
		
		prefetch_wb: begin
			if(dirty == 1'b0)
				next_state = prefetch_r;
			if(pmem_resp == 1'b1)
				next_state = prefetch_r;
		end
		
		prefetch_r: begin
			if(pmem_resp == 1'b1)
				next_state = index;
		end
*/
		
		default: next_state = index;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
	 state <= next_state;
end

endmodule : L2_cache_control

