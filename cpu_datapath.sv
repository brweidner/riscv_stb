import rv32i_types::*;

module datapath
(
    input clk,

    /* control signals */
    input logic [1:0] pcmux_sel,
    input load_pc,
	 /* declare more ports here */
	 /* below are control signals added by me */
	input cmpmux_sel, // must come from the control unit, so we add it to the existing port declaration for the datapath
	input load_ir,
	input load_regfile,
	input load_mar,
	input load_mdr,
	input load_data_out,
	input alumux1_sel,
	input logic [2:0] alumux2_sel,
	input logic [4:0] regfilemux_sel,
	input marmux_sel,
	input alu_ops aluop,
	input branch_funct3_t cmpop,
	input logic [1:0] mem_data_mux_sel,
	// input logic [1:0] lhlogic_sel,
	// input logic [2:0] lblogic_sel,
	// below are datapath signal(s) that are input(s) from the memory/input port 
	input rv32i_word mem_rdata,
   
	// below are datapath signals that output to the control unit (and some to internal components as well) 
	output rv32i_reg rs1, 			// to regfile as well
	output rv32i_reg rs2,			// to regfile as well
	output rv32i_opcode opcode,
	output logic [2:0] funct3,
	output logic [6:0] funct7,
	output logic br_en,						// to regfilemux as well
	
	// below are datapath signals that output to memory/output port 
	output rv32i_word mem_address,
	output rv32i_word mem_wdata
);

/* declare internal signals */
rv32i_word pcmux_out;
rv32i_word pc_out;
rv32i_word alu_out;
rv32i_word pc_plus4_out;
/* from here and below is all MP0 added by me*/
// internal signals for cmpmux - Listing 4
rv32i_word rs2_out, i_imm, cmpmux_out;
rv32i_word rs1_out;
//rv32i_word rs2_out;
rv32i_word j_imm;
rv32i_word u_imm;
rv32i_word b_imm;
rv32i_word s_imm;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word regfilemux_out;
rv32i_word marmux_out;
rv32i_word mdrreg_out;
rv32i_word mem_data_mux_out;
// rv32i_word lhlogic_out;
// rv32i_word lblogic_out;
rv32i_reg rd;
rv32i_word target; 			// added for JALR
rv32i_word lh_upper, lh_lower, lhu_upper, lhu_lower, lb_lowest, lb_2ndlowest, lb_3rdlowest, lb_highest, lbu_lowest, lbu_2ndlowest, lbu_3rdlowest, lbu_highest;
rv32i_word rs2_half, rs2_byte;

assign pc_plus4_out = pc_out + 4;
assign target = (alu_out & 32'hfffffffe);

/* FOR LOADS --> regfile mux inputs */ 
assign lh_upper = $signed(mdrreg_out[31:16]);
assign lh_lower = $signed(mdrreg_out[15:0]);
assign lhu_upper = {16'h0, mdrreg_out[31:16]};
assign lhu_lower = {16'h0, mdrreg_out[15:0]};	
assign lb_lowest = $signed(mdrreg_out[7:0]);
assign lb_2ndlowest = $signed(mdrreg_out[15:8]);
assign lb_3rdlowest = $signed(mdrreg_out[23:16]);
assign lb_highest = $signed(mdrreg_out[31:24]);
assign lbu_lowest = {24'h0, mdrreg_out[7:0]};
assign lbu_2ndlowest = {24'h0, mdrreg_out[15:8]};
assign lbu_3rdlowest = {24'h0, mdrreg_out[23:16]};
assign lbu_highest = {24'h0, mdrreg_out[31:24]};

/* FOR STORES --> mem_data_mux inputs */
assign rs2_half = {rs2_out[15:0], rs2_out[15:0]};
assign rs2_byte = {rs2_out[7:0],rs2_out[7:0],rs2_out[7:0],rs2_out[7:0]};

/*
 * PC
 */
mux4 pcmux
(
    .sel(pcmux_sel),
    .a(pc_plus4_out),
    .b(alu_out),
	 .c(target),		// for the JALR instruction
	 .d(),
    .f(pcmux_out)
);

pc_register pc
(
    .clk,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);
/* everything below here is added by me */
/*
 * CMPmux
 */
mux2 cmpmux
(
	.sel(cmpmux_sel),
	.a(rs2_out),
	.b(i_imm),
	.f(cmpmux_out)
);
/*
 * marmux
 */
mux2 marmux
(
	.sel(marmux_sel),
	.a(pc_out),
	.b(alu_out),
	.f(marmux_out)
);

/*
 * regfilemux
 */
mux18 regfilemux
(
	.sel(regfilemux_sel),
	.a(alu_out),
	.b({31'h0, br_en}),
	.c(u_imm),
	.d(mdrreg_out),
	.e(pc_plus4_out),
	.g(lh_upper),
	.aa(lh_lower),
	.bb(lhu_upper),
	.cc(lhu_lower),
	.dd(lb_lowest),
	.ee(lb_2ndlowest),
	.ff(lb_3rdlowest),
	.gg(lb_highest),
	.hh(lbu_lowest),
	.ii(lbu_2ndlowest),
	.jj(lbu_3rdlowest),
	.kk(lbu_highest),
	.ll(),
	.f(regfilemux_out)
);
/*
 * alumux1
 */
mux2 alumux1
(
	.sel(alumux1_sel),
	.a(rs1_out),
	.b(pc_out),
	.f(alumux1_out)
);
/*
 * alumux2
 */
mux8 alumux2
(
	.sel(alumux2_sel),
	.a(i_imm),
	.b(u_imm),
	.c(b_imm),
	.d(s_imm),
	.aa($signed(j_imm)),		// for JAL 
	.bb(rs2_out),				// for reg-reg operations 
	.cc($signed(i_imm)),		// for JALR
	.dd(),
	.f(alumux2_out)
);
/*
 * MDR
 */
register mdr
(
	.clk(clk),
	.load(load_mdr),
	.in(mem_rdata),
	.out(mdrreg_out)
);
/*
 * MAR
 */
register mar
(
	.clk(clk),
	.load(load_mar),
	.in(marmux_out),
	.out(mem_address)
);
/*
 * mem_data_out
 */ 
register mem_data_out
(
	.clk(clk),
	.load(load_data_out),
	.in(mem_data_mux_out),
	.out(mem_wdata)
);
/*
 * mem_data_mux
 */ 
mux4 mem_data_mux
(
	.sel(mem_data_mux_sel),
	.a(rs2_out),
	.b(rs2_half),
	.c(rs2_byte),
	.d(),
	.f(mem_data_mux_out)
);
/*
 * ALU
 */
alu alu 
(
	.aluop(aluop),
	.a(alumux1_out),
	.b(alumux2_out),
	.f(alu_out)
); 
/*
 * regfile
 */
regfile regfile
(
	.clk(clk),
	.load(load_regfile),
	.in(regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(rd),
	.reg_a(rs1_out),
	.reg_b(rs2_out)
);
 /*
 * CMP
 */
cmp cmp 
(
	.cmpop(cmpop),
	.a(rs1_out),
	.b(cmpmux_out),
	.br_en(br_en)
);

 /*
 * IR
 */
ir IR
(
	.clk(clk),
	.load(load_ir),
	.in(mdrreg_out),
	.funct3(funct3),
	.funct7(funct7),
	.opcode(opcode),
	.i_imm(i_imm),
	.s_imm(s_imm),
	.b_imm(b_imm),
	.u_imm(u_imm),
	.j_imm(j_imm),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd)
);
endmodule : datapath
