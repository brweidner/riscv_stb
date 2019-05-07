module mux18 #(parameter width = 32)
(
	input logic [4:0] sel,
	input [width-1:0] a, b, c, d, e, g, aa, bb, cc, dd, ee, ff, gg, hh, ii, jj, kk, ll,
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
			f = e;
		else if (sel == 5)
			f = g;
		else if (sel == 6)
			f = aa;
		else if (sel == 7)
			f = bb;
		else if (sel == 8)
			f = cc;
		else if (sel == 9)
			f = dd;
		else if (sel == 10)
			f = ee;
		else if (sel == 11)
			f = ff;
		else if (sel == 12)
			f = gg;
		else if (sel == 13)
			f = hh;
		else if (sel == 14)
			f = ii;
		else if (sel == 15)
			f = jj;
		else if (sel == 16)
			f = kk;
		else 
			f = ll;
	end
endmodule : mux18