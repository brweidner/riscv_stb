module arbiter
(
	input clk,

	input data_resp,
	input [31:0] data_addr,
	input [31:0] instr_addr,
	input [255:0] data_wdata,
	input [255:0] instr_wdata,
	input data_read,
	input instr_read,
	input data_write,
	input instr_write,
	input [255:0] L2_rdata,
	input L2_resp,
	
	output logic [31:0] L2_addr,
	output logic [255:0] L2_wdata,
	output logic L2_read,
	output logic L2_write,
	output logic arb_instr_resp,
	output logic arb_data_resp,
	output logic [255:0] arb_instr_rdata,
	output logic [255:0] arb_data_rdata
);

assign arb_instr_rdata = L2_rdata;
assign arb_data_rdata = L2_rdata;

logic data_sel;
assign data_sel = data_read | data_write;

logic data_resp_reg_out;
logic [31:0] data_addr_reg_out;
logic [31:0] instr_addr_reg_out;
logic [255:0] data_wdata_reg_out;
logic [255:0] instr_wdata_reg_out;
logic data_read_reg_out;
logic instr_read_reg_out;
logic data_write_reg_out;
logic instr_write_reg_out;

mux2 #(32) addr_mux
(
	.sel(data_resp_reg_out),
	.a(data_addr_reg_out),
	.b(instr_addr_reg_out),
	.f(L2_addr)
);

mux2 #(256) wdata_mux
(
	.sel(data_sel),
	.a(data_wdata_reg_out),
	.b(instr_wdata_reg_out),
	.f(L2_wdata)
);

mux2 #(1) read_mux
(
	.sel(data_resp_reg_out),
	.a(data_read_reg_out),
	.b(instr_read_reg_out),
	.f(L2_read)
);

mux2 #(1) write_mux
(
	.sel(data_resp_reg_out),
	.a(data_write_reg_out),
	.b(instr_write_reg_out),
	.f(L2_write)
);

mux2 #(1) instr_resp_mux
(
	.sel(data_resp_reg_out),
	.a(1'b0),
	.b(L2_resp),
	.f(arb_instr_resp)
);

mux2 #(1) data_resp_mux
(
	.sel(data_resp_reg_out),
	.a(L2_resp),
	.b(1'b0),
	.f(arb_data_resp)
);

register #(32) instr_addr_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_addr),
	.out(instr_addr_reg_out)
);

register #(32) data_addr_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_addr),
	.out(data_addr_reg_out)
);

register #(1) instr_read_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_read),
	.out(instr_read_reg_out)
);

register #(1) data_read_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_read),
	.out(data_read_reg_out)
);

register #(1) instr_write_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_write),
	.out(instr_write_reg_out)
);

register #(1) data_write_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_write),
	.out(data_write_reg_out)
);

register #(256) instr_wdata_reg
(
	.clk(clk),
	.load(1'b1),
	.in(instr_wdata),
	.out(instr_wdata_reg_out)
);

register #(256) data_wdata_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_wdata),
	.out(data_wdata_reg_out)
);

register #(1) data_resp_reg
(
	.clk(clk),
	.load(1'b1),
	.in(data_resp),
	.out(data_resp_reg_out)
);

endmodule: arbiter