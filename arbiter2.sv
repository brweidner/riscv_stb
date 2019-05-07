module arbiter2
(
	input clk,
	
	/* data -> arbiter */
	input data_read,
	input data_write,
	input [31:0] data_addr,
	input [255:0] data_wdata,
	
	/* instr -> arbiter */
	input instr_read,
	input instr_write,
	input [31:0] instr_addr,
	input [255:0] instr_wdata,
	
	/* L2 -> arbiter */
	input L2_resp,
	input [255:0] L2_rdata,
	
	/* arbiter -> data */
	output logic data_resp,
	output logic [255:0] data_rdata,
	
	/* arbiter -> instr */
	output logic instr_resp,
	output logic [255:0] instr_rdata,
	
	/* arbiter -> L2  */
	output logic L2_read,
	output logic L2_write,
	output logic [31:0] L2_addr,
	output logic [255:0] L2_wdata
);

/* internal signals */
logic data_req;
logic instr_req;
logic data_read_reg_out;
logic data_write_reg_out;
logic [31:0]data_addr_reg_out;
logic [255:0]data_wdata_reg_out;
logic instr_read_reg_out;
logic instr_write_reg_out;
logic [31:0]instr_addr_reg_out;
logic [255:0]instr_wdata_reg_out;


/* assignments */
assign data_req = data_read_reg_out || data_write_reg_out;
assign instr_req = instr_read_reg_out || instr_write_reg_out;


/* state vars */
enum int unsigned {
	waiting,
	ready,
	servicing_data,
	servicing_instr
} state, next_state;


/* State Transitions */
always_comb begin: state_transitions
	next_state = state;
	
	case(state)
		waiting: next_state = ready;
		
		ready: begin
			if(data_req) next_state = servicing_data;
			if(instr_req) next_state = servicing_instr;
		end
		
		servicing_data: begin
			if(L2_resp) begin
				next_state = waiting;
				if(instr_req) next_state = servicing_instr;
			end
		end
		
		servicing_instr: begin
			if(L2_resp) begin
				next_state = waiting;
				if(data_req) next_state = servicing_data;
			end
		end
		
		default: ;
	endcase
	
end


/* State Actions */
always_comb begin: state_actions
	data_resp = 1'b0;
	data_rdata = 256'bX;
	instr_resp = 1'b0;
	instr_rdata = 256'bX;
	L2_read = 1'b0;
	L2_write = 1'b0;
	L2_addr = 32'bX;
	L2_wdata = 256'bX;
	
	case(state)
		waiting: ;
		
		ready: ;
		
		servicing_data: begin
			L2_read = data_read_reg_out;
			L2_write = data_write_reg_out;
			L2_addr = data_addr_reg_out;
			L2_wdata = data_wdata_reg_out;
			if(L2_resp) begin
				data_resp = L2_resp;
				data_rdata = L2_rdata;
			end
		end
		
		servicing_instr: begin
			L2_read = instr_read_reg_out;
			L2_write = instr_write_reg_out;
			L2_addr = instr_addr_reg_out;
			L2_wdata = instr_wdata_reg_out;
			if(L2_resp) begin
				instr_resp = L2_resp;
				instr_rdata = L2_rdata;
			end
		end
		
		default: ;
	endcase
	
end


/* Update State */
always_ff @(posedge clk)
begin: next_state_assignment
	 state <= next_state;
end

/* pipeline registers */
register #(1) data_read_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_read),
	.out(data_read_reg_out)
);

register #(1) data_write_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_write),
	.out(data_write_reg_out)
);

register #(32) data_addr_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_addr),
	.out(data_addr_reg_out)
);

register #(256) data_wdata_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_wdata),
	.out(data_wdata_reg_out)
);

register #(1) instr_read_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_read),
	.out(instr_read_reg_out)
);

register #(1) instr_write_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_write),
	.out(instr_write_reg_out)
);

register #(32) instr_addr_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_addr),
	.out(instr_addr_reg_out)
);

register #(256) instr_wdata_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_wdata),
	.out(instr_wdata_reg_out)
);

endmodule: arbiter2