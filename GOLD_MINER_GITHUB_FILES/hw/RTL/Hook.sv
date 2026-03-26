// (c) Technion IIT, Department of Electrical Engineering 2025 
//-- Alex Grinshpun Apr 2017
//-- Dudy Nov 13 2017
// SystemVerilog version Alex Grinshpun May 2018
// coding convention dudy December 2018
// updated Eyal Lev April 2023
// updated to state machine Dudy March 2023 
// update the hit and collision algoritm - Eyal MAR 2024
// good practice code - Dudy MAR 2025

module	Hook	(	
 
					input	 logic 						clk,
					input	 logic 						resetN,
					input	 logic 						startOfFrame,      //short pulse every start of frame 30Hz 
					input	 logic 						Y_direction_key,   //move Y Up 
					input	 logic                  toggle_x_key,      //toggle X ,
					input  logic 						collision,         //collision if smiley hits an object
					input  logic 			[2:0] 	HitEdgeCode, 
					
					input  logic         [10:0] 	X_circle,
					input  logic         [10:0] 	Y_circle,
					input  logic signed  [15:0] 	cos_cur_degree,
					input  logic signed  [15:0]   sin_cur_degree,
					
					input  logic         [3:0]    caught_object_type,
					input  logic                  is_carrying,
					
					output logic signed 	[10:0]   topLeftX, // output the top left corner 
					output logic signed	[10:0]   topLeftY,  // can be negative , if the object is partliy outside 
					output logic                  circular_mov_cont // signal for circular motion
					
);


const int	FIXED_POINT_MULTIPLIER = 64; // note it must be 2^n 
// FIXED_POINT_MULTIPLIER is used to enable working with integers in high resolution so that 
// we do all calculations with topLeftX_FixedPoint to get a resolution of 1/64 pixel in calcuatuions,
// we devide at the end by FIXED_POINT_MULTIPLIER which must be 2^n, to return to the initial proportions


// movement limits 
const int   OBJECT_WIDTH_X = 64;
const int   OBJECT_HIGHT_Y = 64;
const int	SafetyMargin   =	2;

const int	x_FRAME_LEFT	=	(SafetyMargin)* FIXED_POINT_MULTIPLIER; 
const int	x_FRAME_RIGHT	=	(639 - SafetyMargin - OBJECT_WIDTH_X)* FIXED_POINT_MULTIPLIER; 
const int	y_FRAME_TOP		=	(SafetyMargin) * FIXED_POINT_MULTIPLIER;
const int	y_FRAME_BOTTOM	=	(479 -SafetyMargin - OBJECT_HIGHT_Y ) * FIXED_POINT_MULTIPLIER; //- OBJECT_HIGHT_Y

//edges 
	//------------
	//			 434
	//			 1x2
	//			 404
	//

const logic [4:0] CORNER =	5'b10000; 
const logic [3:0] TOP =		 4'b1000; 
const logic [3:0] RIGHT =   4'b0100; 
const logic [3:0] LEFT =	 4'b0010; 
const logic [3:0] BOTTOM =  4'b0001; 


enum  logic [2:0] {IDLE_ST,         	// initial state
						 MOVE_ST, 				// moving no colision 
						 START_OF_FRAME_ST,  // startOfFrame activity-after all data collected 
						 POSITION_CHANGE_ST, // position interpolate 
						 POSITION_LIMITS_ST  // check if inside the frame  
						}  SM_Motion ;

int Xspeed  ; // speed    
int Yspeed  ; 
int Xposition ; //position   
int Yposition ;  

logic toggle_x_key_D;
logic is_shooting; // flag for shoot state
 

logic [4:0] hit_reg = 5'b00000;

 
// --- Speed Logic (Combinatorial) ---
// This runs continuously to determine the correct speed based on what is caught

int SHOOT_SPEED; //total velocity of the hook for y and x


always_comb begin
	if (is_carrying == 1'b0) begin
		         SHOOT_SPEED = 16; // Fast speed when shooting down or empty
		 end
		 else begin
					case (caught_object_type)
						 4'd1: SHOOT_SPEED = 2; // Big Gold 
						 4'd2: SHOOT_SPEED = 5; // Small Gold 
						 4'd3: SHOOT_SPEED = 6; // Skull
						 4'd4: SHOOT_SPEED = 4; // Big Rock 
						 4'd5: SHOOT_SPEED = 3; // Med Rock
						 4'd6: SHOOT_SPEED = 4; // Small Rock
						 4'd7: SHOOT_SPEED = 6; // Diamond 
						 default: SHOOT_SPEED = 16;        
					endcase
			  end
end
 
always_ff @(posedge clk or negedge resetN)
begin : fsm_sync_proc

	if (resetN == 1'b0) begin 
		SM_Motion <= IDLE_ST ; 
		Xspeed <= 0; 
		Yspeed <= 0; 
		Xposition <= 0; 
		Yposition <= 0; 
		toggle_x_key_D <= 0;
		hit_reg <= 5'b0;	
		circular_mov_cont <= 0;
		is_shooting <= 1'b0;
	
	end 	
	
	else begin
	
		toggle_x_key_D <= toggle_x_key ;  //shift register to detect edge 
		circular_mov_cont <= 0;
	
		case(SM_Motion)
		
		//------------
			IDLE_ST: begin
		//------------
		
				
				Xspeed  <= 0 ; 
				Yspeed  <= 0; 
				Xposition <= X_circle*FIXED_POINT_MULTIPLIER; 
				Yposition <= Y_circle*FIXED_POINT_MULTIPLIER; 

				if (startOfFrame) 
					SM_Motion <= MOVE_ST ;
 	
			end
	
		//------------
			MOVE_ST:  begin     // moving collecting colisions 
		//------------
		
		//our code
	
				if (is_shooting == 1'b0) begin
					Xposition <= X_circle * FIXED_POINT_MULTIPLIER;
					Yposition <= Y_circle * FIXED_POINT_MULTIPLIER;
					Xspeed <= 0;
					Yspeed <= 0;

       
					if (Y_direction_key) begin
					is_shooting <= 1'b1; 
					Yspeed <= -((SHOOT_SPEED * sin_cur_degree) >>> 6);
					Xspeed <= (SHOOT_SPEED * cos_cur_degree) >>> 6;
					end
				end
				
				if (collision) begin
                case (HitEdgeCode)
                    3'd2: hit_reg[1] <= 1'b1; // Bitmap Left(2)  -> FSM Left Bit(1)
                    3'd4: hit_reg[2] <= 1'b1; // Bitmap Right(4) -> FSM Right Bit(2)
                    
                    // Map other codes (Top/Bottom) directly
                    default: hit_reg[HitEdgeCode] <= 1'b1; 
                endcase
            end
				
				if (startOfFrame )
					SM_Motion <= START_OF_FRAME_ST ; 
		end 
		
		//------------
			START_OF_FRAME_ST:  begin      //check if any colisin was detected 
		//------------
		
            if (hit_reg != 5'b00000) begin // If any collision occurred (Left, Right, Bottom, Corner)
                
                // Only reverse if we are currently moving OUT (downwards)
                // This prevents getting stuck inside a wall while already retracting
					 if (Yspeed > 0) begin
                     Yspeed <= ((SHOOT_SPEED * sin_cur_degree) >>> 6);
                     Xspeed <= -((SHOOT_SPEED * cos_cur_degree) >>> 6);
                end
            end
            
            hit_reg <= 5'b00000; // Clear hit register
            SM_Motion <= POSITION_CHANGE_ST;
	 
		end

		//------------------------
			POSITION_CHANGE_ST : begin  // position interpolate 
		//------------------------
	
				Xposition <= Xposition + Xspeed ; 
				Yposition <= Yposition + Yspeed ;
	
				
				SM_Motion <= POSITION_LIMITS_ST ; 
			end
		
		//------------------------
			POSITION_LIMITS_ST : begin  //check if still inside the frame 
		//------------------------
				if (Xposition < x_FRAME_LEFT) 
						Xposition <= x_FRAME_LEFT ; 
				if (Xposition > x_FRAME_RIGHT)
						Xposition <= x_FRAME_RIGHT ; 

				if (Yposition > y_FRAME_BOTTOM) 
						Yposition <= y_FRAME_BOTTOM ;
		
				if(is_shooting && Yposition <= Y_circle * FIXED_POINT_MULTIPLIER) begin
						is_shooting <= 1'b0;
			
						Yposition <= Y_circle * FIXED_POINT_MULTIPLIER; // Align Y 
						Xposition <= X_circle * FIXED_POINT_MULTIPLIER; // Align X 
			
						Xspeed <= 0; // Stop!
						Yspeed <= 0; // Stop!
			
						circular_mov_cont <= 1'b1;
				
						SM_Motion <= MOVE_ST ; 
				end
				else begin 
					SM_Motion <= MOVE_ST ; 
				end
			end
		endcase  // case for state machine 
	end 
end // end fsm_sync


//return from FIXED point trunc back to prame size parameters 
  
assign 	topLeftX = Xposition >>> 6 ;   
assign 	topLeftY = Yposition >>> 6 ;    
	

endmodule	


