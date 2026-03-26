

module	objects_mux	(	
//		--------	Clock Input	 	
					input		logic	clk,
					input		logic	resetN,
					
					// control signals
					input		logic menu_mode,
					input		logic final_screen_mode,
					
					// menu
					input		logic menuDrawRequest,
					input		logic [7:0] menuRGB,
					
					// hook 
					input		logic	hookDrawingRequest, 
					input		logic	[7:0] hookRGB, 
					     
					//line
					input    logic lineDrawingRequest,
					input		logic [7:0] lineRGB,
					
					//HUD
					input		logic HUDDrawingrequest,
					input		logic [7:0] HUDRGB,
					
					// treasure_caught
					input		logic TR_catchDrawingrequest,
					input		logic [7:0] TR_catchRGB,
			  
					////////////////////////
					// background 
					input    logic Object_MineRequest, 
					input		logic	[7:0] treasureRGB,    
					input		logic	BGDrawingRequest, 
					input		logic	[7:0] backGroundRGB,
					
					input		logic	[7:0] RGB_MIF, 
			  
				
	   			output	logic	[7:0] RGBOut
);

always_ff@(posedge clk or negedge resetN) begin
	if(!resetN) begin
			RGBOut	<= 8'b0;
	end
	
	else begin
		
		if(menu_mode && menuDrawRequest) //first priority
			RGBOut <= menuRGB;
		
		else if(!menu_mode && HUDDrawingrequest == 1'b1) //second priority
			RGBOut <= HUDRGB;		      
		
		else if (!menu_mode && !final_screen_mode && hookDrawingRequest == 1'b1 )  //third priority 
			RGBOut <= hookRGB;
			
		else if (!menu_mode && !final_screen_mode && lineDrawingRequest == 1'b1) //fourth priority
			RGBOut <= lineRGB;
			
		else if (!menu_mode && !final_screen_mode && TR_catchDrawingrequest == 1'b1) //fifth priority
			RGBOut <= TR_catchRGB;
				
		else if (!menu_mode && !final_screen_mode && Object_MineRequest == 1'b1) //sixth priority
			RGBOut <= treasureRGB;
				
		else begin 
			if(BGDrawingRequest == 1'b1) //seventh priority
				RGBOut <= backGroundRGB ;
			
			else 
				RGBOut <= RGB_MIF ;// last priority
				
		end	
	end
end
endmodule


