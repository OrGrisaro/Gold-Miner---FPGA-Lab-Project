// the module is the timer of the game getting an initail value and counting down 
module game_timer      	
	(
	input logic clk, 
	input logic resetN,
	input logic enable,
	input logic turbo,
	input logic start,
	input logic [6:0] start_value,
	
	output logic [6:0] current_time,
	output logic times_up
   );
	
	logic one_sec;
	
// instance of one_sec that will give us the signal that a second a passed	
	one_sec_counter one_sec_inst (
        .clk(clk), .resetN(resetN),
        .turbo(turbo),.one_sec(one_sec)
    );
	 
	 
	always_ff @( posedge clk or negedge resetN )
   begin
		// asynchronous reset
		if ( !resetN ) begin
			current_time <= 7'd0;
			times_up <= 1'b0;
		end
		
		else begin
			if(start) begin
				current_time <= start_value;
				times_up <= 0;
			end
			else if(enable) begin
				if(current_time > 0) begin
					if(one_sec) 
						current_time <= current_time-1;
				end
				else begin
					times_up <= 1'b1;
				end
			end
		end	
	end
endmodule	