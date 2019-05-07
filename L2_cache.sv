module L2_cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
	input clk,

	input [31:0] mem_address_in,
	output [255:0] mem_rdata,
	input [255:0] mem_wdata,
	input mem_read,
	input mem_write,
	output mem_resp,
	
	output [31:0] pmem_address,
	input [255:0] pmem_rdata,
	output [255:0] pmem_wdata,
	output pmem_read,
	output pmem_write,
	input pmem_resp
);

logic [31:0] mem_address;
logic [31:0] prefetch_address;
logic prefetch_toggle;
logic prefetch_load;

logic hit;
logic dirty;

logic data_read;
logic data_load;
logic dirty_read;
logic dirty_load;
logic LRU_read;
logic LRU_load;
logic tag_read;
logic tag_load;
logic valid_read;
logic valid_load;

logic data_in_sel;
logic dirty_in;
logic paddr_sel;

always_comb begin
	mem_address = mem_address_in;
	if(prefetch_toggle)
		mem_address = prefetch_address;
end

L2_cache_control control 
(
	.clk(clk),
	
	.mem_read(mem_read),
	.mem_write(mem_write),
	.mem_resp(mem_resp),
	.pmem_read(pmem_read),
	.pmem_write(pmem_write),
	.pmem_resp(pmem_resp),
	
	.hit(hit),
	.dirty(dirty),
	
	.data_read(data_read),
	.data_load(data_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.LRU_read(LRU_read),
	.LRU_load(LRU_load),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load),
	
	.data_in_sel(data_in_sel),
	.dirty_in(dirty_in),
	.paddr_sel(paddr_sel),
	.prefetch_toggle(prefetch_toggle),
	.prefetch_load(prefetch_load)
);

L2_cache_datapath datapath
(
	.clk(clk),
	
	.mem_address(mem_address),
	.mem_wdata(mem_wdata),
	.mem_rdata(mem_rdata),
	.pmem_rdata(pmem_rdata),
	.pmem_wdata(pmem_wdata),
	.pmem_address(pmem_address),
	
	.hit(hit),
	.dirty_sig(dirty),
	
	.data_read(data_read),
	.data_load(data_load),
	.dirty_read(dirty_read),
	.dirty_load(dirty_load),
	.LRU_read(LRU_read),
	.LRU_load(LRU_load),
	.tag_read(tag_read),
	.tag_load(tag_load),
	.valid_read(valid_read),
	.valid_load(valid_load),
	
	.data_in_sel(data_in_sel),
	.dirty_in(dirty_in),
	.paddr_sel(paddr_sel)
);

register #(32) prefetch_address_reg
(
	.clk(clk),
	.load(prefetch_load),
	.in(mem_address_in + 32),
	.out(prefetch_address)
);

endmodule : L2_cache
