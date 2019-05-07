module PHT 
(
	input clk,
	input logic outcome,
	input logic load,
	
	output logic prediction
);

enum int unsigned {
	snt,
	wnt,
	wt,
	st
} state, next_state;

initial begin
	state = wnt;
end

always_comb begin: state_actions
	prediction = 1'b0;
	if( (state == wt) || (state == st) )
		prediction = 1'b1;
end

always_comb begin: state_transitions
	next_state = state;
 
	if(load) begin
		case(state)
			snt: begin
				next_state = snt;
				if(outcome)
					next_state = wnt;
			end
			
			wnt: begin
				next_state = snt;
				if(outcome)
					next_state = wt;
			end
			
			wt: begin
				next_state = wnt;
				if(outcome)
					next_state = st;
			end
			
			st: begin
				next_state = wt;
				if(outcome)
					next_state = st;
			end
		endcase
	end
end

always_ff @(posedge clk) begin:next_state_assignment
	state <= next_state;
end

endmodule: PHT