
module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,
	
	input [31:0] mem_address,
	input [255:0] mem_wdata256,
	output [255:0] mem_rdata256,
	input [31:0] mem_byte_enable256,
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	output [31:0] pmem_address,
	
	output logic hit,
	output logic dirty_sig,
	
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

	input data_in_sel,
	input dirty_in,
	input paddr_sel
);

/* data control signals */
logic [31:0] data0_load;
logic [31:0] data1_load;
logic [255:0] data_in;
logic [255:0] data_out_0;
logic [255:0] data_out_1;

/* dirty control signals */
logic dirty0_load;
logic dirty1_load;
logic dirty_out_0;
logic dirty_out_1;

/* valid control signals */
logic valid0_load;
logic valid1_load;
logic valid_out_0;
logic valid_out_1;

/* LRU control signals */
logic LRU_out;

/* tag control signals */
logic tag0_load;
logic tag1_load;
logic [23:0] tag_out_0;
logic [23:0] tag_out_1;
logic [23:0] tag_mux_out;

/* hit control signals */
logic hit0;
logic hit1;

/* other signals */ 
logic cur_way;

/* memory assignments */
assign mem_rdata256 = pmem_wdata;

/* data control logic */
always_comb begin
	data0_load = 32'b0;
	data1_load = 32'b0;
	
	case(cur_way)
		1'b0: begin
			case(data_load)
				2'b01: data0_load = mem_byte_enable256;
				2'b10: data0_load = {32{1'b1}};
				default: ;
			endcase
		end
		1'b1: begin
			case(data_load)
				2'b01: data1_load = mem_byte_enable256;
				2'b10: data1_load = {32{1'b1}};
				default: ;
			endcase
		end
		default: begin
		end
	endcase
end

/* dirty control signals */
always_comb begin
	dirty_sig = 1'b0;
	dirty0_load = 1'b0;
	dirty1_load = 1'b0;
	case(cur_way)
		1'b0: begin
			dirty0_load = dirty_load;
			if(dirty_out_0)
				if(valid_out_0)
					dirty_sig = 1'b1;
		end
		1'b1: begin
			dirty1_load = dirty_load;
			if(dirty_out_1)
				if(valid_out_1)
					dirty_sig = 1'b1;
		end
	endcase
end

/* tag control logic */
assign tag0_load = cur_way ? 1'b0 : tag_load;
assign tag1_load = cur_way ? tag_load : 1'b0;	

/* valid control logic */
always_comb begin
	valid0_load = 1'b0;
	valid1_load = 1'b0;
	case(cur_way)
		1'b0: begin
			valid0_load = valid_load;
		end
		1'b1: begin
			valid1_load = valid_load;
		end
	endcase
end

/* hit control logic */
always_comb begin
	hit = 1'b0;
	hit0 = 1'b0;
	hit1 = 1'b0;
	if(tag_out_0 == mem_address[31:8])
		if(valid_out_0 == 1'b1)
			hit0 = 1'b1;
	if(tag_out_1 == mem_address[31:8])
		if(valid_out_1 == 1'b1)
			hit1 = 1'b1;
	if(hit1 | hit0)
		hit = 1'b1;
end

/* submodule instantiation */
data_array line[2]
(
	clk,
	
	data_read,
	{data0_load, data1_load},
	mem_address[7:5],
	data_in,
	{data_out_0, data_out_1}
);

array dirty[2]
(
	clk,
	
	dirty_read,
	{dirty0_load, dirty1_load},
	mem_address[7:5],
	dirty_in,
	{dirty_out_0, dirty_out_1}
);

array lru
(
	.clk(clk),
	
	.read(LRU_read),
	.load(LRU_load),
	.index(mem_address[7:5]),
	.datain(~cur_way),
	.dataout(LRU_out)
);

array #(3, 24) tag[2]
(
	clk,
	
	tag_read,
	{tag0_load, tag1_load},
	mem_address[7:5],
	mem_address[31:8],
	{tag_out_0, tag_out_1}
);

array valid[2]
(
	clk,
	
	valid_read,
	{valid0_load, valid1_load},
	mem_address[7:5],
	1'b1,
	{valid_out_0, valid_out_1}
);

mux2 #(256) data_in_mux
(
	.sel(data_in_sel),
	.a(mem_wdata256),
	.b(pmem_rdata),
	.f(data_in)
);

mux2 #(256) data_out_mux
(
	.sel(cur_way),
	.a(data_out_0),
	.b(data_out_1),
	.f(pmem_wdata)
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
	.a(tag_out_0),
	.b(tag_out_1),
	.f(tag_mux_out)
);

mux2 #(32) pmem_address_mux
(
	.sel(paddr_sel),
	.a({mem_address[31:5], 5'b0}),
	.b({tag_mux_out, mem_address[7:5], 5'b0}),
	.f(pmem_address)
);

endmodule : cache_datapath

