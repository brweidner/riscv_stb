import rv32i_types::*;

module cmp
(
	input rv32i_word rs1,
	input rv32i_word cmpmux,
	input branch_funct3_t cmpop,
	
	output logic br_en
);

logic signed [31:0] rs1_signed;
logic signed [31:0] cmpmux_signed;

assign rs1_signed = $signed(rs1);
assign cmpmux_signed = $signed(cmpmux);

always_comb
begin
	br_en = 0;
	case(cmpop)
		beq: begin
			if (rs1 == cmpmux)
				br_en = 1;
		end
		bne: begin
			if (rs1 != cmpmux)
				br_en = 1;
		end
		blt: begin
			if (rs1_signed < cmpmux_signed)
				br_en = 1;
		end
		bge: begin
			if (rs1_signed >= cmpmux_signed)
				br_en = 1;
		end
		bltu: begin
			if (rs1 < cmpmux)
				br_en = 1;
		end
		bgeu: begin
			if (rs1 >= cmpmux)
				br_en = 1;
		end
	endcase
end

endmodule : cmp