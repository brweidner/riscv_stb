module mp3
(
	input clk,
	
	output read,
	output write,
	output [31:0] address,
	output [255:0] wdata,
	
	input [255:0] rdata,
	input resp
);

/* Declare any internal signals here */
logic [31:0] instr_addr;
logic [31:0] data_addr;
logic [31:0] data_wdata;
logic [3:0] data_mem_byte_enable;
logic data_read;
logic data_write;
logic cache_hit;
logic [31:0] instr_out;
logic [31:0] data_out;

logic [31:0] L2_address;
logic [255:0] L2_rdata;
logic [255:0] L2_wdata;
logic L2_read;
logic L2_write;
logic L2_resp;

/* Instantiate MP3 datapath and memory here */
mp3_datapath datapath
(
	.clk(clk),
	.instr_mem_rdata(instr_out),
	.instr_mem_addr(instr_addr),
	.data_mem_rdata(data_out),
	.data_mem_addr(data_addr),
	.data_mem_byte_en(data_mem_byte_enable),
	.data_mem_wdata(data_wdata),
	.data_mem_read(data_read),
	.data_mem_write(data_write),
	.cache_hit(cache_hit)
);

L1_cache L1_cache
(
	.clk(clk),
	.instr_addr(instr_addr),
	.data_addr(data_addr),
	.data_wdata(data_wdata),
	.data_mem_byte_enable(data_mem_byte_enable),
	.data_read(data_read),
	.data_write(data_write),
	.L2_rdata(L2_rdata),
	.L2_resp(L2_resp),
	
	.cache_hit(cache_hit),
	.instr_out(instr_out),
	.data_out(data_out),
	.L2_addr(L2_address),
	.L2_read(L2_read),
	.L2_write(L2_write),
	.L2_wdata(L2_wdata)
);

L2_cache L2_cache
(
	.clk(clk),
	
	.mem_address_in(L2_address),
	.mem_rdata(L2_rdata),
	.mem_wdata(L2_wdata),
	.mem_read(L2_read),
	.mem_write(L2_write),
	.mem_resp(L2_resp),
	
	.pmem_address(address),
	.pmem_rdata(rdata),
	.pmem_wdata(wdata),
	.pmem_read(read),
	.pmem_write(write),
	.pmem_resp(resp)
);

endmodule : mp3