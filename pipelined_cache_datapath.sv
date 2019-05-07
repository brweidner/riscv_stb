module pipelined_cache_datapath
(
	input clk,
	
	/* Memory/CPU signals */
	input [31:0] index_addr,
	input [31:0] cmp_addr,
	input [31:0] mem_byte_enable256,
	input [255:0] wdata256,
	input [255:0] rdata256,
	
	output [255:0] rdata256_out,
	output [255:0] wdata256_out,
	output [31:0] addr_out,
	
	/* Control Signals */
	input data_read,
	input [1:0] data_load,
	input dirty_read,
	input dirty_load,
	input LRU_read,
	input LRU_load,
	input tag_read,
	input tag_load,
	input valid_read,
	input valid_load,
	
	input addr_out_sel,
	input data_in_sel,
	input dirty_in,
	
	output logic hit,
	output logic dirty_signal
);

assign rdata256_out = wdata256_out;

/* Internal Signals */
logic cur_way;
logic hit1;

/* Data Array Control Signals */
logic [31:0] data0_load;
logic [31:0] data1_load;
logic [255:0] data_in;
logic [255:0] data0_out;
logic [255:0] data1_out;

/* Dirty Array Control Signals */
logic dirty0_load;
logic dirty1_load;
logic dirty0_out;
logic dirty1_out;

/* Valid Array Control Signals */
logic valid0_load;
logic valid1_load;
logic valid0_out;
logic valid1_out;

/* LRU Array Control Signals */
logic LRU_out;

/* Tag Array Control Signals */
logic tag0_load;
logic tag1_load;
logic [23:0] tag0_out;
logic [23:0] tag1_out;
logic [23:0] tag_mux_out;

/* Data Control Logic */
always_comb begin
	data0_load = 32'b0;
	data1_load = 32'b0;
	case(cur_way)
		1'b0:begin
			case(data_load)
				2'b00: ;
				2'b01: data0_load = mem_byte_enable256;
				2'b10: data0_load = {32{1'b1}};
				2'b11: ;
				default: ;
			endcase
		end
		
		1'b1: begin
			case(data_load)
				2'b00: ;
				2'b01: data1_load = mem_byte_enable256;
				2'b10: data1_load = {32{1'b1}};
				2'b11: ;
				default: ;
			endcase
		end
		
		default: ;
	endcase
end

/* Dirty Control Logic */
always_comb begin
	dirty_signal = valid0_out & dirty0_out;
	dirty0_load = dirty_load;
	dirty1_load = 1'b0;
	if(cur_way) begin
		dirty_signal = valid1_out & dirty1_out;
		dirty0_load = 1'b0;
		dirty1_load = dirty_load;
	end
end

/* Tag Control Logic */
always_comb begin
	tag0_load = tag_load;
	tag1_load = 1'b0;
	if(cur_way == 1) begin
		tag0_load = 1'b0;
		tag1_load = tag_load;
	end
end

/* Valid Control Logic */
always_comb begin
	valid0_load = valid_load;
	valid1_load = 1'b0;
	if(cur_way) begin
		valid0_load = 1'b0;
		valid1_load = valid_load;
	end
end

/* Hit Control Logic */
always_comb begin
	hit = ((tag0_out == cmp_addr[31:8]) & valid0_out) | ((tag1_out == cmp_addr[31:8]) & valid1_out);
	hit1 = (tag1_out == cmp_addr[31:8]) & valid1_out;
end

/* Module Instantiation */
data_array line[2]
(
	clk,
	data_read,
	{data0_load, data1_load},
	index_addr[7:5],
	cmp_addr[7:5],
	data_in,
	{data0_out, data1_out}
);

array dirty[2]
(
	clk,
	dirty_read,
	{dirty0_load, dirty1_load},
	index_addr[7:5],
	cmp_addr[7:5],
	dirty_in,
	{dirty0_out, dirty1_out}
);

array lru
(
	clk,
	LRU_read,
	LRU_load,
	index_addr[7:5],
	cmp_addr[7:5],
	~cur_way,
	LRU_out
);

array #(3, 24) tag[2]
(
	clk,
	tag_read,
	{tag0_load, tag1_load},
	index_addr[7:5],
	cmp_addr[7:5],
	cmp_addr[31:8],
	{tag0_out, tag1_out}
);

array valid[2]
(
	clk,
	valid_read,
	{valid0_load, valid1_load},
	index_addr[7:5],
	cmp_addr[7:5],
	1'b1,
	{valid0_out, valid1_out}
);

mux2 #(256) data_in_mux
(
	.sel(data_in_sel),
	.a(wdata256),
	.b(rdata256),
	.f(data_in)
);

mux2 #(256) data_out_mux
(
	.sel(cur_way),
	.a(data0_out),
	.b(data1_out),
	.f(wdata256_out)
);

mux2 #(1) cur_way_mux
(
	.sel(hit),
	.a(LRU_out),
	.b(hit1),
	.f(cur_way)
);

mux2 #(24) tag_mux
(
	.sel(cur_way),
	.a(tag0_out),
	.b(tag1_out),
	.f(tag_mux_out)
);

mux2 #(32) addr_out_mux
(
	.sel(addr_out_sel),
	.a({cmp_addr[31:5], 5'b0}),
	.b({tag_mux_out, cmp_addr[7:5], 5'b0}),
	.f(addr_out)
);

endmodule: pipelined_cache_datapath