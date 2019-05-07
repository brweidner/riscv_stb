module BHR#(parameter size = 4)
(
	input clk,
	input load,
	input outcome,
	
	output logic [size-1:0] out
);

logic [size-1:0] data;

assign out = data;

initial begin
	data = 1'b0;
end

always_ff @(posedge clk) begin
	if(load) begin
		data = data << 1;
		data[0] = outcome;
	end
end

endmodule: BHR