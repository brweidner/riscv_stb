import rv32i_types::*;

module mp3_datapath

(
	input clk,
	// other inputs? (i.e., from instr/data memory)
	input rv32i_word data_mem_rdata,
	input rv32i_word instr_mem_rdata,
	input cache_hit,
	
	// outputs? (i.e., to memory)
	output rv32i_word instr_mem_addr,
	output rv32i_word data_mem_addr,
	output logic [3:0] data_mem_byte_en,
	output rv32i_word data_mem_wdata,
	output logic data_mem_read,
	output logic data_mem_write
);

/* IF internal signals */
logic pipeline_continue;
rv32i_word if_pcmux_out;
rv32i_word if_pc_plus4_out;
logic pcmux_sel;
rv32i_word if_pc_out;
rv32i_word jalr_addr_mux_out;
rv32i_word jalr_target;

/* ID internal signals */
rv32i_control_word id_ctrl_word;
rv32i_word id_pc_out;
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_reg rs1, rs2, rd;
rv32i_word id_rs1_out, id_rs2_out;
rv32i_word id_i_imm,id_u_imm, id_b_imm, id_s_imm, id_j_imm;
rv32i_word decode_forwardA_out, decode_forwardB_out;
logic decode_forwardA_sel, decode_forwardB_sel;
logic load_use_hazard;
logic branch_hazard;
logic hazard_reg_out;
logic [31:0] instr_reg_out, instr_mux_out;
logic old_branch_hazard;

/* EX internal signals */
rv32i_control_word ex_ctrl_word;
rv32i_word ex_pc_out;
rv32i_word ex_rs1_out, ex_rs2_out;
rv32i_word ex_i_imm,ex_u_imm, ex_b_imm, ex_s_imm, ex_j_imm;
rv32i_word ex_rs2_half, ex_rs2_byte;
rv32i_word ex_alumux1_out, ex_alumux2_out;
rv32i_word ex_forwardA, ex_forwardB;
rv32i_word ex_cmpmux_out;
rv32i_word ex_alu_out;
logic ex_br_en;
rv32i_word ex_mem_wdata;
rv32i_word wb_forward_out;

/* MEM internal signals */
rv32i_control_word mem_ctrl_word;
rv32i_word mem_pc_out;
rv32i_word mem_alu_out;
rv32i_word mem_mem_wdata;
logic mem_br_en;
rv32i_word mem_u_imm;
rv32i_word mem_pc_plus_four;

/* WB internal signals */
rv32i_control_word wb_ctrl_word;
rv32i_word wb_pc_out;
rv32i_word wb_alu_out;
logic wb_br_en;
rv32i_word wb_u_imm;
rv32i_word wb_mem_rdata;
rv32i_word wb_pc_plus_four;
rv32i_word wb_load_data_out;
rv32i_word wb_regfilemux_out;

/* Forwarding Signals */
logic [1:0] forwardA_sel;
logic [1:0] forwardB_sel;
logic [31:0] mem_forward_out;

/* Branch Prediction Signals */
logic [7:0] bp_read_index;
logic bp_prediction;
logic BTB_match;
logic [31:0] BTB_target;
logic [31:0] BTB_mux_out;
logic pc_correction_sel;
logic [31:0] pc_correction_mux_out;
logic prediction_sel;

/* Counter Signals */
logic data_mem_read_temp;
logic data_mem_write_temp;
logic [31:0] data_mem_rdata_temp;

/* input/output assignments */
assign instr_mem_addr = BTB_mux_out;
assign opcode = rv32i_opcode'(instr_mux_out[6:0]);
assign funct3 = instr_mux_out[14:12];
assign funct7 = instr_mux_out[31:25];
assign rs1 = instr_mux_out[19:15];
assign rs2 = instr_mux_out[24:20];
assign rd = instr_mux_out[11:7];
assign id_i_imm = {{21{instr_mux_out[31]}}, instr_mux_out[30:20]};
assign id_s_imm = {{21{instr_mux_out[31]}}, instr_mux_out[30:25], instr_mux_out[11:7]};
assign id_b_imm = {{20{instr_mux_out[31]}}, instr_mux_out[7], instr_mux_out[30:25], instr_mux_out[11:8], 1'b0};
assign id_u_imm = {instr_mux_out[31:12], 12'h000};
assign id_j_imm = {{12{instr_mux_out[31]}}, instr_mux_out[19:12], instr_mux_out[20], instr_mux_out[30:21], 1'b0};

assign wb_mem_rdata = data_mem_rdata_temp;
assign data_mem_read_temp = mem_ctrl_word.data_mem_read;
assign data_mem_write_temp = mem_ctrl_word.data_mem_write;
assign data_mem_addr= mem_alu_out;
assign data_mem_wdata = mem_mem_wdata;


/* internal assignments */
assign if_pc_plus4_out = BTB_mux_out + 4;
assign pcmux_sel = branch_hazard;
assign jalr_target = (ex_alu_out & 32'hfffffffe);
assign ex_rs2_half = {ex_forwardB[15:0], ex_forwardB[15:0]};
assign ex_rs2_byte = {ex_forwardB[7:0], ex_forwardB[7:0], ex_forwardB[7:0], ex_forwardB[7:0]};
assign wb_pc_plus_four = wb_pc_out + 4;
assign mem_pc_plus_four = mem_pc_out + 4;
assign prediction_sel = BTB_match && bp_prediction && (id_ctrl_word.is_branch || id_ctrl_word.is_jump);


/* instantiate components here - stage by stage */
/*
 * PC
 */
pc_register pc
(
	.clk(clk),
	.load(pipeline_continue & load_use_hazard),
	.in(pc_correction_mux_out),
	.out(if_pc_out)
);

/*
 * pcmux
 */
mux2 pcmux
(
	.sel(pcmux_sel),
	.a(if_pc_plus4_out),
	.b(jalr_addr_mux_out),
	.f(if_pcmux_out)
);

/*
 * jalr_addr_mux
 */
mux2 jalr_addr_mux 
(
	.sel(ex_ctrl_word.jalr_addr_sel),
	.a(ex_alu_out),
	.b(jalr_target),
	.f(jalr_addr_mux_out)
);

mux2 pc_correction_mux
(
	.sel(pc_correction_sel),
	.a(if_pcmux_out),
	.b(ex_pc_out + 4),
	.f(pc_correction_mux_out)
);

/*
 * IF/ID Stage Register File
 */
IF_ID_reg IF_ID_reg
(
	.clk(clk),
	.load(pipeline_continue & load_use_hazard),
	.if_pc_out(BTB_mux_out),
	.id_pc_out(id_pc_out)
);
//////////////////////////////////////////////// END IF STAGE ////////////////////////////////////////////////////////////////////
/*
 * Control ROM --> can be moved outside of datapath if we'd like, but leaving here for now 
 */
control_rom control_rom
(
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.rd(rd),
	.rs1(rs1),
	.rs2(rs2),
	.cache_hit(cache_hit),
	
	.ex_opcode(ex_ctrl_word.opcode),
	.mem_opcode(mem_ctrl_word.opcode),
	.prev_rd(ex_ctrl_word.rd),
	
	.ex_br_en(ex_br_en),
	.old_branch_hazard(old_branch_hazard),
	
	.bp_update_index(bp_read_index),
	.branch_target(jalr_addr_mux_out),
	.id_pc(id_pc_out),
	.ex_pc(ex_pc_out),
	
	.ctrl(id_ctrl_word),
	.pipeline_continue(pipeline_continue),
	.load_use_hazard(load_use_hazard),
	.branch_hazard(branch_hazard),
	.pc_correction_sel(pc_correction_sel)
);
/*
 * regfile
 */
regfile regfile
(
	.clk(clk),
	.load(wb_ctrl_word.load_regfile),
	.in(wb_regfilemux_out),
	.src_a(rs1),
	.src_b(rs2),
	.dest(wb_ctrl_word.rd),
	.reg_a(id_rs1_out), 
	.reg_b(id_rs2_out)
);

mux2 decode_forwardA_mux
(
	.sel(decode_forwardA_sel),
	.a(id_rs1_out),
	.b(wb_regfilemux_out),
	.f(decode_forwardA_out)
);

mux2 decode_forwardB_mux
(
	.sel(decode_forwardB_sel),
	.a(id_rs2_out),
	.b(wb_regfilemux_out),
	.f(decode_forwardB_out)
);

register instr_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.in(instr_mem_rdata),
	.out(instr_reg_out)
);

register #(1) hazard_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.in(load_use_hazard),
	.out(hazard_reg_out)
);

mux2 instr_mux
(
	.sel(hazard_reg_out),
	.a(instr_reg_out),
	.b(instr_mem_rdata),
	.f(instr_mux_out)
);

register #(1) br_en_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.in(branch_hazard),
	.out(old_branch_hazard)
);

/*
 * ID/EX Stage Register File
 */
ID_EX_reg ID_EX_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.hazard(load_use_hazard),
	.branch(branch_hazard),
	.id_pc_out(id_pc_out),
	.id_ctrl_word(id_ctrl_word),
	.id_rs1_out(decode_forwardA_out),
	.id_rs2_out(decode_forwardB_out),
	.id_i_imm(id_i_imm),
	.id_u_imm(id_u_imm),
	.id_b_imm(id_b_imm),
	.id_s_imm(id_s_imm),
	.id_j_imm(id_j_imm),
	.ex_pc_out(ex_pc_out),
	.ex_ctrl_word(ex_ctrl_word),
	.ex_rs1_out(ex_rs1_out),
	.ex_rs2_out(ex_rs2_out),
	.ex_i_imm(ex_i_imm),
	.ex_u_imm(ex_u_imm),
	.ex_b_imm(ex_b_imm),
	.ex_s_imm(ex_s_imm),
	.ex_j_imm(ex_j_imm)
);
//////////////////////////////////////////////// END ID STAGE ////////////////////////////////////////////////////////////////////
/*
 * alumux1
 */
mux2 alumux1
(
	.sel(ex_ctrl_word.alumux1_sel),
	.a(ex_forwardA),
	.b(ex_pc_out),
	.f(ex_alumux1_out)
);
/*
 * alumux2
 */
mux8 alumux2
(
	.sel(ex_ctrl_word.alumux2_sel),
	.a(ex_i_imm),
	.b(ex_u_imm),
	.c(ex_b_imm),
	.d(ex_s_imm),
	.aa(ex_j_imm),	
	.bb(ex_forwardB),				 
	.cc(),	// un-used
	.dd(),	// un-used
	.f(ex_alumux2_out)
);
/*
 * cmpmux
 */
mux2 cmpmux
(
	.sel(ex_ctrl_word.cmpmux_sel),
	.a(ex_forwardB),
	.b(ex_i_imm),
	.f(ex_cmpmux_out)
);
/*
 * memdatamux
 */
mux4 memdatamux
(
	.sel(ex_ctrl_word.memdatamux_sel),
	.a(ex_forwardB),
	.b(ex_rs2_half),
	.c(ex_rs2_byte),
	.d(),		// un-used
	.f(ex_mem_wdata)
);
/*
 * ALU
 */
alu alu 
(
	.aluop(ex_ctrl_word.aluop),
	.a(ex_alumux1_out),
	.b(ex_alumux2_out),
	.f(ex_alu_out)
);
/*
 * CMP
 */
cmp cmp 
(
	.cmpop(ex_ctrl_word.cmpop),
	.rs1(ex_forwardA),
	.cmpmux(ex_cmpmux_out),
	.br_en(ex_br_en)
);

mux4 forwardA_mux
(
	.sel(forwardA_sel),
	.a(ex_rs1_out),
	.b(mem_forward_out),
	.c(wb_regfilemux_out),
	.d(mem_forward_out),
	.f(ex_forwardA)
);

mux4 forwardB_mux
(
	.sel(forwardB_sel),
	.a(ex_rs2_out),
	.b(mem_forward_out),
	.c(wb_regfilemux_out),
	.d(mem_forward_out),
	.f(ex_forwardB)
);

/*
 * EX/MEM Stage Register File
 */
EX_MEM_reg EX_MEM_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.ex_pc_out(ex_pc_out),
	.ex_ctrl_word(ex_ctrl_word),
	.ex_alu_out(jalr_addr_mux_out),
	.ex_br_en(ex_br_en),
	.ex_mem_wdata(ex_mem_wdata),
	.ex_u_imm(ex_u_imm),
	.mem_pc_out(mem_pc_out),
	.mem_ctrl_word(mem_ctrl_word),
	.mem_alu_out(mem_alu_out),
	.mem_br_en(mem_br_en),
	.mem_mem_wdata(mem_mem_wdata),
	.mem_u_imm(mem_u_imm)
);
//////////////////////////////////////////////// END EX STAGE ////////////////////////////////////////////////////////////////////
/*
 * Mem Byte Enable Block --> See mem_byte_enable_block.sv for mux implementation
 */
mem_byte_enable_block mbe_block 
(
	.mem_alu_out(mem_alu_out),
	.mem_store_op(mem_ctrl_word.store_op),
	.mem_byte_enable(data_mem_byte_en)
);

/*
 * MEM/WB Stage Register File
 */
MEM_WB_reg MEM_WB_reg
(
	.clk(clk),
	.load(pipeline_continue),
	.mem_pc_out(mem_pc_out),
	.mem_ctrl_word(mem_ctrl_word),
	.mem_alu_out(mem_alu_out),
	.mem_br_en(mem_br_en),
	.mem_u_imm(mem_u_imm),
	.wb_pc_out(wb_pc_out),
	.wb_ctrl_word(wb_ctrl_word),
	.wb_alu_out(wb_alu_out),
	.wb_br_en(wb_br_en),
	.wb_u_imm(wb_u_imm)
);

mux8 mem_forward_mux
(
	.sel(mem_ctrl_word.regfilemux_sel),
	.a(mem_alu_out),
	.b({31'h0, mem_br_en}),
	.c(mem_u_imm),
	.d(),
	.aa(mem_pc_plus_four),	
	.bb(),				 
	.cc(),	// un-used
	.dd(),	// un-used
	.f(mem_forward_out)
);
//////////////////////////////////////////////// END MEM STAGE ////////////////////////////////////////////////////////////////////
/*
 * regfilemux
 */
mux8 regfilemux
(
	.sel(wb_ctrl_word.regfilemux_sel),
	.a(wb_alu_out),
	.b({31'h0, wb_br_en}),
	.c(wb_u_imm),
	.d(wb_mem_rdata),
	.aa(wb_pc_plus_four),	
	.bb(wb_load_data_out),				 
	.cc(),	// un-used
	.dd(),	// un-used
	.f(wb_regfilemux_out)
);
/*
 * load_instr_block
 */
load_instr_block load_instr_block
(
	.wb_mem_rdata(wb_mem_rdata),
	.wb_alu_out(wb_alu_out),
	.wb_sign_sel(wb_ctrl_word.sign_sel),
	.wb_load_op(wb_ctrl_word.load_op),
	.load_data_out(wb_load_data_out)
);

//////////////////////////////////////////////// END WB STAGE ////////////////////////////////////////////////////////////////////

forwarding_unit forwarding_unit
(
	.rs1(ex_ctrl_word.rs1),
	.rs2(ex_ctrl_word.rs2),
	.mem_rd(mem_ctrl_word.rd),
	.wb_rd(wb_ctrl_word.rd),
	
	.decode_rs1(rs1),
	.decode_rs2(rs2),
	
	.mem_opcode(mem_ctrl_word.opcode),
	.wb_opcode(wb_ctrl_word.opcode),
	
	.forwardA_sel(forwardA_sel),
	.forwardB_sel(forwardB_sel),
	
	.decode_forwardA_sel(decode_forwardA_sel),
	.decode_forwardB_sel(decode_forwardB_sel)
);

branch_prediction_unit branch_prediction_unit
(
	.clk(clk),
	.PC(id_pc_out[5:2]),
	
	.update_index(ex_ctrl_word.bp_update_index),
	.update_enable(ex_ctrl_word.is_branch || ex_ctrl_word.is_jump),
	.outcome(ex_br_en || ex_ctrl_word.is_jump),
	
	.prediction(bp_prediction),
	.read_index(bp_read_index)
);

BTB BTB
(
	.clk(clk),
	
	.update(ex_ctrl_word.is_branch || ex_ctrl_word.is_jump),
	.cmp_addr(id_pc_out),
	.update_addr(ex_pc_out),
	.target_addr(jalr_addr_mux_out),
	
	.match(BTB_match),
	.target(BTB_target)
);

mux2 #(32) BTB_mux
(
	.sel(prediction_sel),
	.a(if_pc_out),
	.b(BTB_target),
	.f(BTB_mux_out)
);

counter_unit counter
(
	.clk(clk),
	.pipeline_continue(pipeline_continue),
	
	.branch_instruction(ex_ctrl_word.is_branch || ex_ctrl_word.is_jump),
	.branch_hazard(branch_hazard),
	
	.mem_address(data_mem_addr),
	.data(data_mem_rdata),
	.read(data_mem_read_temp),
	.write(data_mem_write_temp),
	
	.read_out(data_mem_read),
	.write_out(data_mem_write),
	.data_out(data_mem_rdata_temp)
);

endmodule : mp3_datapath
