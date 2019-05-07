import rv32i_types::*;
module control_rom
(
	input rv32i_opcode opcode,
	input logic [2:0] funct3,
	input logic [6:0] funct7,
	input rv32i_reg rd,
	input rv32i_reg rs1,
	input rv32i_reg rs2,
	input cache_hit,
	
	input rv32i_opcode ex_opcode,
	input rv32i_opcode mem_opcode,
	input rv32i_reg prev_rd,
	
	input ex_br_en,
	input old_branch_hazard,
	
	input [7:0] bp_update_index,
	input [31:0] branch_target,
	input [31:0] id_pc,
	input [31:0] ex_pc,
	
	output rv32i_control_word ctrl,
	output logic pipeline_continue ,
	output logic load_use_hazard,
	output logic branch_hazard,
	output logic pc_correction_sel
);

logic output_bubble;
logic [31:0] next_addr;
assign next_addr = ex_pc + 4;

/* Branch Prediction and Branch Hazard Logic */
always_comb begin
	output_bubble = 1'b0;
	branch_hazard = 1'b0;
	pc_correction_sel = 1'b0;
	if( ((ex_opcode == op_br) && (ex_br_en == 1'b1)) || (ex_opcode == op_jal) || (ex_opcode == op_jalr) ) begin
		if(id_pc != branch_target) begin
			output_bubble = 1'b1;
			branch_hazard = 1'b1;
		end
	end
	if( (ex_opcode == op_br) && (ex_br_en == 1'b0) ) begin
		if(id_pc != next_addr) begin
			output_bubble = 1'b1;
			branch_hazard = 1'b1;
			pc_correction_sel = 1'b1;
		end	
	end
	if(old_branch_hazard) begin
		output_bubble = 1'b1;
	end
end

always_comb
begin 
/* Default Assignments */
	pipeline_continue = cache_hit;
	load_use_hazard = 1'b1;
	
	ctrl.opcode = opcode;
	ctrl.load_regfile = 1'b0;
	ctrl.aluop = alu_ops'(funct3);
	ctrl.cmpop = branch_funct3_t'(funct3);
	ctrl.regfilemux_sel = 3'b0;
	ctrl.rd = rd;
	ctrl.rs1 = rs1;
	ctrl.rs2 = rs2;
	ctrl.alumux1_sel = 1'b0;
	ctrl.alumux2_sel = 3'b0;
	ctrl.cmpmux_sel = 1'b0;
	ctrl.memdatamux_sel = 2'b0;
	ctrl.store_op = 2'b0;
	ctrl.load_op = 1'b0;
	ctrl.sign_sel = 1'b0;
	ctrl.is_jump = 1'b0;
	ctrl.is_branch = 1'b0;
	ctrl.jalr_addr_sel = 1'b0;
	ctrl.data_mem_read = 1'b0;
	ctrl.data_mem_write = 1'b0;
	ctrl.bp_update_index = bp_update_index;
	
	case(opcode)
		op_lui: begin
			ctrl.regfilemux_sel = 3'b010; // select rd<-u_imm
			ctrl.load_regfile = 1'b1;
		end 
		
		op_auipc: begin
			ctrl.aluop = alu_add;
			ctrl.alumux1_sel = 1'b1;
			ctrl.alumux2_sel = 3'b1;
			ctrl.load_regfile = 1'b1; // by default regfilemux selects alu_out
		end
		
		op_jal: begin
			ctrl.aluop = alu_add;
			ctrl.is_jump = 1'b1;
			ctrl.alumux1_sel = 1'b1;
			ctrl.alumux2_sel = 3'b100;
			ctrl.regfilemux_sel = 3'b100;
			ctrl.load_regfile = 1'b1;
		end
		
		op_jalr: begin
			ctrl.aluop = alu_add;
			ctrl.is_jump = 1'b1;
			ctrl.regfilemux_sel = 3'b100;
			ctrl.load_regfile = 1'b1;
			ctrl.jalr_addr_sel = 1'b1;
		end
		
		op_br: begin
			ctrl.is_branch = 1'b1;
			ctrl.alumux1_sel = 1'b1;
			ctrl.alumux2_sel = 3'b010;
			ctrl.aluop = alu_add;
		end
		
		op_load: begin
			ctrl.data_mem_read = 1'b1;
			ctrl.aluop = alu_add;
			case(funct3)
				/* LB */
				3'b000: begin
					ctrl.load_op = 1'b1; 
					ctrl.sign_sel = 1'b0;
					ctrl.regfilemux_sel = 3'b101;
				end 
				/* LH */
				3'b001: begin
					ctrl.load_op = 1'b0;
					ctrl.sign_sel = 1'b0;
					ctrl.regfilemux_sel = 3'b101;
				end
				/* LW */
				3'b010: begin
					ctrl.regfilemux_sel = 3'b011;
				end
				/* LBU */
				3'b100: begin
					ctrl.load_op = 1'b1;
					ctrl.sign_sel = 1'b1;
					ctrl.regfilemux_sel = 3'b101;
				end
				/* LHU */
				3'b101: begin
					ctrl.load_op = 1'b0;
					ctrl.sign_sel = 1'b1;
					ctrl.regfilemux_sel = 3'b101;
				end
				default: ; /* do nothing */
			endcase
			ctrl.load_regfile = 1'b1;
		end
		
		op_store: begin
			ctrl.data_mem_write = 1'b1;
			ctrl.aluop = alu_add;
			ctrl.alumux2_sel = 3'b011;
			case(funct3)
				/* SB */
				3'b000: begin
					ctrl.memdatamux_sel = 2'b10;
					ctrl.store_op = 2'b10;
				end
				/* SH */
				3'b001: begin
					ctrl.memdatamux_sel = 2'b01;
					ctrl.store_op = 2'b01;
				end
				/* SW */
				3'b010: begin
					ctrl.store_op = 2'b11;
				end
				default: ; /* do nothing */
			endcase
		end
		
		op_imm: begin
			ctrl.load_regfile = 1'b1;
			case(funct3)
				// SLTI 
				3'b010: begin 
					ctrl.cmpop = blt;
					ctrl.cmpmux_sel = 1'b1;
					ctrl.regfilemux_sel = 3'b1;
				end
				// SLTIU
				3'b011: begin
					ctrl.cmpop = bltu;
					ctrl.cmpmux_sel = 1'b1;
					ctrl.regfilemux_sel = 3'b1;
				end
				// SRAI or SRLI - arithmetic or logical shift right
				3'b101: begin 
					case(funct7)
						7'b0000000: begin 
						// SRLI 
							ctrl.aluop = alu_srl;
						end
						7'b0100000: begin 
						// SRAI 
							ctrl.aluop = alu_sra;
						end 
						default: /* do nothing */ ;
					endcase
				end
				// the rest of the immediate instructions - ADDI, XORI, ORI, ANDI, SLLI
				default: ; /* do nothing */ 
			endcase
		end
		
		op_reg: begin
			ctrl.load_regfile = 1'b1;
			ctrl.alumux2_sel = 3'b101;
			case(funct3)
				// ADD OR SUB
				3'b000: begin
					case(funct7)
						// ADD
						7'b0000000: begin 
							ctrl.aluop = alu_add;
						end 
						// SUB 
						7'b0100000: begin 
							ctrl.aluop = alu_sub;
						end
						default: /* do nothing */ ;
					endcase
				end 
				// SLT 
				3'b010: begin 
					ctrl.cmpop = blt;
					ctrl.regfilemux_sel = 3'b1;
				end 
				
				// SLTU 
				3'b011: begin 	
					ctrl.cmpop = bltu;
					ctrl.regfilemux_sel = 3'b1;
				end 
				
				// SRL OR SRA 
				3'b101: begin 
					case(funct7) 
						// SRL 
						7'b0000000: begin 
							ctrl.aluop = alu_srl;
						end 
						// SRA 
						7'b0100000: begin
							ctrl.aluop = alu_sra;
						end 
						default: /* do nothing */ ;
					endcase 
				end
				
				// for SLL, XOR, OR, AND 			
				default: begin 
					ctrl.aluop = alu_ops'(funct3);
				end 
			endcase
		end
		
		op_csr: ; /* NOT REQUIRED IN MP3 */
		
		default: begin
			ctrl = 0;
		end 
	endcase
	
	
	/* Assign control signals based on opcode */
	if( (ex_opcode == op_load) && ((rs1 == prev_rd) || (rs2 == prev_rd)) ) begin
		load_use_hazard = 1'b0;
	
		ctrl.opcode = op_imm;
		ctrl.load_regfile = 1'b1;
		ctrl.aluop = alu_add;
		ctrl.cmpop = branch_funct3_t'(3'b011);
		ctrl.regfilemux_sel = 3'b0;
		ctrl.rd = 5'b0;
		ctrl.rs1 = 5'b0;
		ctrl.rs2 = 5'b0;
		ctrl.alumux1_sel = 1'b0;
		ctrl.alumux2_sel = 3'b0;
		ctrl.cmpmux_sel = 1'b0;
		ctrl.memdatamux_sel = 2'b0;
		ctrl.store_op = 2'b0;
		ctrl.load_op = 1'b0;
		ctrl.sign_sel = 1'b0;
		ctrl.is_branch = 1'b0;
		ctrl.is_jump = 1'b0;
		ctrl.jalr_addr_sel = 1'b0;
		ctrl.data_mem_read = 1'b0;
		ctrl.data_mem_write = 1'b0;
	end
	if(output_bubble) begin
		ctrl.opcode = op_imm;
		ctrl.load_regfile = 1'b1;
		ctrl.aluop = alu_add;
		ctrl.cmpop = branch_funct3_t'(3'b011);
		ctrl.regfilemux_sel = 3'b0;
		ctrl.rd = 5'b0;
		ctrl.rs1 = 5'b0;
		ctrl.rs2 = 5'b0;
		ctrl.alumux1_sel = 1'b0;
		ctrl.alumux2_sel = 3'b0;
		ctrl.cmpmux_sel = 1'b0;
		ctrl.memdatamux_sel = 2'b0;
		ctrl.store_op = 2'b0;
		ctrl.load_op = 1'b0;
		ctrl.sign_sel = 1'b0;
		ctrl.is_branch = 1'b0;
		ctrl.is_jump = 1'b0;
		ctrl.jalr_addr_sel = 1'b0;
		ctrl.data_mem_read = 1'b0;
		ctrl.data_mem_write = 1'b0;
	end
	
end

endmodule : control_rom