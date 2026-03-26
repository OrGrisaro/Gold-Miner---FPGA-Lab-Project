

module random ( 
	input	logic  clk,
	input	logic  resetN, 
	input	logic  rise,
	output logic unsigned [SIZE_BITS-1:0] dout 
);

	parameter SIZE_BITS = 2;
	parameter unsigned MIN_VAL = 0;  
	parameter unsigned MAX_VAL = 2;

	logic unsigned [SIZE_BITS-1:0] counter;

	always_ff @(posedge clk or negedge resetN) begin
		if (!resetN) begin
			counter <= MIN_VAL;
			dout <= MIN_VAL;
		end
		
		else begin
			if (counter >= MAX_VAL) 
				counter <= MIN_VAL;
			else 
				counter <= counter + 1;
			dout <= counter ;
		end
	end

endmodule