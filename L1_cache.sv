module L1_cache
(
	input clk,
	input [31:0] instr_addr,
	input [31:0] data_addr,
	input [31:0] data_wdata,
	input [3:0] data_mem_byte_enable,
	input data_read,
	input data_write,
	input [255:0] L2_rdata,
	input L2_resp,
	
	output cache_hit,
	output [31:0] instr_out,
	output [31:0] data_out,
	output [31:0] L2_addr,
	output L2_read,
	output L2_write,
	output [255:0] L2_wdata
);

/* Internal Signals */
logic [31:0] instr_index_addr;
logic [31:0] instr_cmp_addr;
logic [31:0] data_index_addr;
logic [31:0] data_cmp_addr;
logic [31:0] data_wdata_out;
logic data_read_out;
logic data_write_out;
logic [3:0] data_mem_byte_enable_out;
logic instr_resp;
logic data_resp;
logic [255:0] i_rdata;
logic [255:0] i_wdata;
logic i_write;
logic i_read;
logic [31:0] i_addr;
logic [31:0] d_addr;
logic d_read;
logic d_write;
logic [255:0] d_wdata;
logic [255:0] d_rdata;
logic arb_instr_resp;
logic arb_data_resp;
logic instr_read;
logic instr_read_out;

/* Logic */
assign cache_hit = instr_resp & data_resp;
assign instr_read = 1'b1;

/* Module Instatiatino */
pipelined_cache instruction_cache
(
	.clk(clk),
	.index_addr(instr_index_addr),
	.cmp_addr(instr_cmp_addr),
	.mem_byte_enable(4'b0),
	.wdata(32'b0),
	.rdata256(i_rdata),
	.read(instr_read_out),
	.write(1'b0),
	.resp(arb_instr_resp),
	
	.addr_out(i_addr),
	.rdata_out(instr_out),
	.wdata256_out(i_wdata),
	.read_out(i_read),
	.write_out(i_write),
	.resp_out(instr_resp)
);

pipelined_cache data_cache
(
	.clk(clk),
	.index_addr(data_index_addr),
	.cmp_addr(data_cmp_addr),
	.mem_byte_enable(data_mem_byte_enable_out),
	.wdata(data_wdata_out),
	.rdata256(d_rdata),
	.read(data_read_out),
	.write(data_write_out),
	.resp(arb_data_resp),
	
	.addr_out(d_addr),
	.rdata_out(data_out),
	.wdata256_out(d_wdata),
	.read_out(d_read),
	.write_out(d_write),
	.resp_out(data_resp)
);

arbiter2 arbiter
(
	.clk(clk),
	
	.data_read(d_read),
	.data_write(d_write),
	.data_addr(d_addr),
	.data_wdata(d_wdata),
	
	.instr_read(i_read),
	.instr_write(i_write),
	.instr_addr(i_addr),
	.instr_wdata(i_wdata),
	
	.L2_resp(L2_resp),
	.L2_rdata(L2_rdata),
	
	.data_resp(arb_data_resp),
	.data_rdata(d_rdata),
	
	.instr_resp(arb_instr_resp),
	.instr_rdata(i_rdata),
	
	.L2_read(L2_read),
	.L2_write(L2_write),
	.L2_addr(L2_addr),
	.L2_wdata(L2_wdata)
);

register #(32) instr_addr_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(instr_addr),
	.out(instr_cmp_addr)
);

register #(1) instr_read_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(instr_read),
	.out(instr_read_out)
);

register #(32) data_addr_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(data_addr),
	.out(data_cmp_addr)
);

register #(32) data_wdata_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(data_wdata),
	.out(data_wdata_out)
);

register #(1) data_read_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(data_read),
	.out(data_read_out)
);

register #(1) data_write_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(data_write),
	.out(data_write_out)
);

register #(4) data_mem_byte_enable_reg
(
	.clk(clk),
	.load(cache_hit),
	.in(data_mem_byte_enable),
	.out(data_mem_byte_enable_out)
);

mux2 #(32) instr_addr_mux
(
	.sel(cache_hit),
	.a(instr_cmp_addr),
	.b(instr_addr),
	.f(instr_index_addr)
);

mux2 #(32) data_addr_mux
(
	.sel(cache_hit),
	.a(data_cmp_addr),
	.b(data_addr),
	.f(data_index_addr)
);

endmodule: L1_cache