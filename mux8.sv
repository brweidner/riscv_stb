module mux8 #(parameter width = 32)
(
	input logic [2:0] sel,
	input [width-1:0] a, b, c, d, aa, bb, cc, dd,
	output logic [width-1:0] f
);
	always_comb
	begin
		if (sel == 0)
			f = a;
		else if (sel == 1)
			f = b;
		else if (sel == 2)
			f = c;
		else if (sel == 3)
			f = d;
		else if (sel == 4)
			f = aa;
		else if (sel == 5)
			f = bb;
		else if (sel == 6)
			f = cc;
		else 
			f = dd;
		
	end
endmodule : mux8