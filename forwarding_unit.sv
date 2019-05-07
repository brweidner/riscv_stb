import rv32i_types::*;

module forwarding_unit
(
	input rv32i_reg rs1,
	input rv32i_reg rs2,
	input rv32i_reg mem_rd,
	input rv32i_reg wb_rd,
	
	input rv32i_reg decode_rs1,
	input rv32i_reg decode_rs2,
	
	input rv32i_opcode mem_opcode,
	input rv32i_opcode wb_opcode,
	
	output logic [1:0] forwardA_sel,
	output logic [1:0] forwardB_sel,
	
	output logic decode_forwardA_sel,
	output logic decode_forwardB_sel
);

always_comb begin
	forwardA_sel = 2'b00;
	forwardB_sel = 2'b00;
	decode_forwardA_sel = 1'b0;
	decode_forwardB_sel = 1'b0;
	if( (wb_rd != 5'b0) && ((wb_opcode != op_store) && (wb_opcode != op_br)) ) begin
		forwardA_sel[1] = (rs1 == wb_rd);
		forwardB_sel[1] = (rs2 == wb_rd);
		decode_forwardA_sel = (decode_rs1 == wb_rd);
		decode_forwardB_sel = (decode_rs2 == wb_rd);
	end
	if( (mem_rd != 5'b0) && ((mem_opcode != op_store) && (mem_opcode != op_br)) ) begin
		forwardA_sel[0] = (rs1 == mem_rd);
		forwardB_sel[0] = (rs2 == mem_rd);
	end
end

endmodule: forwarding_unit