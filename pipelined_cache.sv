module pipelined_cache
(
	input clk,
	input [31:0] index_addr,
	input [31:0] cmp_addr,
	input [3:0] mem_byte_enable,
	input [31:0] wdata,
	input [255:0] rdata256,
	input read,
	input write,
	input resp,
	
	output [31:0] addr_out,
	output [31:0] rdata_out,
	output [255:0] wdata256_out,
	output read_out,
	output write_out,
	output resp_out
);

/* Internal Signals */
logic hit;
logic addr_out_sel;
logic data_in_sel;
logic dirty;

logic [31:0] mem_byte_enable256;
logic [255:0] wdata256;
logic [255:0] rdata256_out;

logic data_read;
logic [1:0] data_load;
logic dirty_read;
logic dirty_load;
logic dirty_in;
logic LRU_read;
logic LRU_load;
logic tag_read;
logic tag_load;
logic valid_read;
logic valid_load;

/* Module Instantiation */
pipelined_cache_control control
(
	.clk(clk),
	.read(read),
	.write(write),
	.hit(hit),
	.dirty(dirty),
	.resp(resp),
	.resp_out(resp_out),
	.read_out(read_out),
	.write_out(write_out),
	.addr_out_sel(addr_out_sel),
	.data_in_sel(data_in_sel),
	.data_read(data_read),
	.data_load(data_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.dirty_in(dirty_in),
	.LRU_read(LRU_read),
	.LRU_load(LRU_load),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load)
);

pipelined_cache_datapath datapath
(
	.clk(clk),
	.index_addr(index_addr),
	.cmp_addr(cmp_addr),
	.mem_byte_enable256(mem_byte_enable256),
	.wdata256(wdata256),
	.rdata256(rdata256),
	.rdata256_out(rdata256_out),
	.wdata256_out(wdata256_out),
	.addr_out(addr_out),
	.data_read(data_read),
	.data_load(data_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.dirty_in(dirty_in),
	.LRU_read(LRU_read),
	.LRU_load(LRU_load),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load),
	.addr_out_sel(addr_out_sel),
	.data_in_sel(data_in_sel),
	.hit(hit),
	.dirty_signal(dirty)
);

line_adapter bus_adapter
(
	.mem_wdata(wdata),
	.mem_rdata256(rdata256_out),
	.mem_byte_enable(mem_byte_enable),
	
	.mem_wdata256(wdata256),
	.mem_rdata(rdata_out),
	.mem_byte_enable256(mem_byte_enable256),
	
	.resp_address(cmp_addr),
	.address(cmp_addr)
);

endmodule: pipelined_cache