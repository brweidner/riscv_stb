module mp3_tb;

timeunit 1ns;
timeprecision 1ns;

logic clk;

/*
logic mem_resp;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
logic [31:0] mem_address;
logic [31:0] mem_rdata;
logic [31:0] mem_wdata;
*/

/* testbench signals */
logic write;
logic [15:0] errcode;
logic [31:0] registers [32];
logic halt;
logic [63:0] order;

logic [31:0] write_address;
logic [31:0] write_data;

/* connection signals */
logic read;
logic mem_write;
logic [31:0] address;
logic [255:0] wdata;
logic resp;
logic [255:0] rdata;

initial
begin
    clk = 0;
    order = 0;
end

/* Clock generator */
always #5 clk = ~clk;

assign registers = dut.datapath.regfile.data;
assign halt = dut.datapath.pcmux_sel & (dut.datapath.ex_pc_out == dut.datapath.if_pcmux_out);

always @(posedge clk)
begin
    if (mem_write & resp) begin
        write_address = address;
        write_data = wdata;
        write = 1;
    end else begin
        write_address = 32'hx;
        write_data = 32'hx;
        write = 0;
    end
    if (halt) $finish;
    if (dut.datapath.pipeline_continue) order = order + 1;
end

mp3 dut
(
	.clk(clk),
	.read(read),
	.write(mem_write),
	.address(address),
	.wdata(wdata),
	.resp(resp),
	.rdata(rdata)
);

physical_memory memory
(
	.clk(clk),
	.read(read),
	.write(mem_write),
	.address(address),
	.wdata(wdata),
	.resp(resp),
	.rdata(rdata),
	.error()
);

/*
riscv_formal_monitor_rv32i monitor
(
  .clock(clk),
  .reset(1'b0),
  .rvfi_valid(dut.load_pc),
  .rvfi_order(order),
  .rvfi_insn(dut.datapath.IR.data),
  .rvfi_trap(dut.control.trap),
  .rvfi_halt(halt),
  .rvfi_intr(1'b0),
  .rvfi_rs1_addr(dut.control.rs1_addr),
  .rvfi_rs2_addr(dut.control.rs2_addr),
  .rvfi_rs1_rdata(monitor.rvfi_rs1_addr ? dut.datapath.rs1_out : 0),
  .rvfi_rs2_rdata(monitor.rvfi_rs2_addr ? dut.datapath.rs2_out : 0),
  .rvfi_rd_addr(dut.load_regfile ? dut.datapath.rd : 5'h0),
  .rvfi_rd_wdata(monitor.rvfi_rd_addr ? dut.datapath.regfilemux_out : 0),
  .rvfi_pc_rdata(dut.datapath.pc_out),
  .rvfi_pc_wdata(dut.datapath.pcmux_out),
  .rvfi_mem_addr(mem_address),
  .rvfi_mem_rmask(dut.control.rmask),
  .rvfi_mem_wmask(dut.control.wmask),
  .rvfi_mem_rdata(dut.datapath.mdrreg_out),
  .rvfi_mem_wdata(dut.datapath.mem_wdata),
  .errcode(errcode)
);
*/

endmodule : mp3_tb
