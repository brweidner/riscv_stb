module branch_prediction_unit
(
	input clk,
	input [3:0] PC,
	
	input [7:0] update_index,
	input update_enable,
	input outcome,
	
	output logic prediction,
	output logic [7:0] read_index
);

logic [255:0] split_load;
logic [255:0] split_predictions;
logic [3:0] BHR_out;

assign read_index = {PC, BHR_out};

always_comb begin
	split_load = 256'b0;
	split_load[update_index] = update_enable;
	
	prediction = split_predictions[read_index];
end

PHT PHT[256]
(
	clk,
	outcome,
	split_load,
	
	split_predictions
);

BHR BHR
(
	.clk(clk),
	.load(update_enable),
	.outcome(outcome),
	
	.out(BHR_out)
);



endmodule: branch_prediction_unit