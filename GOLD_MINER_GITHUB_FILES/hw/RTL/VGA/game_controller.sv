// game controller responsible for runnig the game
//handling collisions
//handling  inputs from diff modules and routing the game as aresult
// managing the levels and game flow

module game_controller (

	// --- inputs---	
	
	//mainframe
	input logic clk,
   input logic resetN,
	input logic startOfFrame,
	
	// from user
	input logic start_key,
	input logic skip_level_key, // for design checks
	 
	//drwing reqs
   input logic drawing_request_hook,
   input logic drawing_request_boarders,
   input logic drawing_request_treasures, 

	//inputs from support moduls
	 
	input logic time_up,
	input logic claw_is_back,
	input logic [3:0] treasure_type,
	input logic [1:0] random_val_grid, // which grid is chosen from the random select number 0-2
	 
	// --- outputs ---
	
	//timer
	output logic timer_start,
	output logic timer_enable,
	output logic [6:0] timer_start_val,
	
	//for other moduls
	output logic [10:0] score,
	output logic [1:0] level,
	output logic [3:0] grid_select, // return which grid was chosen depends on level
	output logic [1:0] msg_select,
	output logic game_enable,
	output logic load_new_map,
	output logic menu_mode,
	output logic final_screen_mode,
	
	// collision handles
   output logic collision, 
   output logic collision_Hook_Treasure,
	
	//physic
	output logic [3:0] swing_speed,         // output the circular velocity per level
	//others
	output logic SingleHitPulse,
	output logic sound_score_pulse
);
 
	// --- internal signals ---
 
   logic flag_treasure; // New semaphore
   logic is_treasure_hit; // New internal signal
	logic collision_hook_boarders;
	logic [3:0] stored_grid_id; //which grid id did we get
	
	// --- internal varibles to manage the game ---
	
	logic skip_level_key_flag;
	logic [10:0] score_counter;
	logic [1:0] cur_level;
	logic [3:0] latch_treasure_type;
	logic [10:0] target_score;
	localparam [9:0] level1_quota = 100;
	localparam [9:0] level2_quota = 300;
	localparam [9:0] level3_quota = 600;
	localparam [6:0] level1_time = 7'd60;
	localparam [6:0] level2_time = 7'd40;
	localparam [6:0] level3_time = 7'd30;
	logic carrying_object;
	 
   // --- Assignments ---
	 
   assign is_treasure_hit = (drawing_request_hook && drawing_request_treasures);
	assign collision_hook_boarders = (drawing_request_hook && drawing_request_boarders);
   assign collision = (collision_hook_boarders || is_treasure_hit); 
	assign grid_select = stored_grid_id;

   // --- Sequential Logic collision and pulse handle ---
   always_ff @(posedge clk or negedge resetN) begin
		if(!resetN) begin 
			flag_treasure <= 1'b0;
			SingleHitPulse <= 1'b0;
			collision_Hook_Treasure <= 1'b0;
      end 
      else begin 
			SingleHitPulse <= 1'b0; 
         collision_Hook_Treasure <= 1'b0; 
         if(startOfFrame)  
				flag_treasure <= 1'b0;
         // Handle Treasure Collision
         if(is_treasure_hit && (flag_treasure == 1'b0) && !carrying_object) begin
				flag_treasure <= 1'b1;          
            collision_Hook_Treasure <= 1'b1;
				SingleHitPulse <= 1'b1 ; 
			end 
      end 
	end
	
	
	// FSM + score MANAGMENT
	typedef enum logic [2:0]{
		S_MENU,
		S_LEVEL_SETUP,
		S_GAME_RUN,
		S_LEVEL_CHECK,
		S_GAME_OVER,
		S_WIN_GAME
	}state_t;

	state_t cur_state, next_state; 
	
	//FSM State handle with synchronic 
	always_ff @(posedge clk or negedge resetN) begin
		if(!resetN)
			cur_state <= S_MENU;
		else
			cur_state <= next_state;
	end
	
	//FSM transition logic
	
	always_comb begin
		next_state = cur_state; // DEFAULT
		
		case(cur_state)
		
		S_MENU: begin
			if (start_key) next_state = S_LEVEL_SETUP; // need to setup the game
		end
		
		S_LEVEL_SETUP: begin
			next_state = S_GAME_RUN; // after the setup is done we can play
		end
		
		S_GAME_RUN: begin
			if(time_up && !carrying_object) next_state = S_LEVEL_CHECK; // if the timer ended well check if the player won the level or not
			else if(skip_level_key) next_state = S_LEVEL_CHECK; // in case we want to skip
			else if(score_counter >= 999 && cur_level == 2'd3) next_state = S_WIN_GAME;
			else next_state = S_GAME_RUN;
		end
		
		S_LEVEL_CHECK: begin
			if(score_counter >= target_score || skip_level_key_flag) begin
				if(cur_level == 2'd3)
					next_state = S_WIN_GAME; // we won
				else
					next_state = S_LEVEL_SETUP; // need to prepare for next level
			end
			else begin
				next_state = S_GAME_OVER; // we lost
			end
		end
		
		S_GAME_OVER: begin
			if(start_key) next_state = S_MENU;// can replay the game
		end
		
		S_WIN_GAME: begin
			if(start_key) next_state = S_MENU;// can replay the game
		end	
		endcase
	end
	
	
	//game and state logic + score 
	
	always_ff @(posedge clk or negedge resetN) begin
		if(!resetN) begin
			score_counter <= 0;
			cur_level <= 0;
			target_score <= level1_quota;
			carrying_object <= 0;
			sound_score_pulse <= 0;
			stored_grid_id <= 4'd0;
			skip_level_key_flag <= 0;
		end
		
		else begin
			sound_score_pulse <= 0;
			if(cur_state == S_GAME_RUN && skip_level_key)
				skip_level_key_flag <= 1;
			
			case(cur_state)
			
				S_MENU: begin
					score_counter <= 0;
					cur_level <= 1;
					target_score <= level1_quota;
					carrying_object <= 0;
					skip_level_key_flag <= 0;
					if(start_key)
						stored_grid_id <= {2'b00, random_val_grid};
					else
						stored_grid_id <= 4'b0;
				end
				
				S_LEVEL_SETUP: begin // need to add grid change from random
					skip_level_key_flag <= 0;
					// setup quotas
					if(cur_level == 1) target_score <= level1_quota;
					else if(cur_level == 2) target_score <= level2_quota;
					else target_score <= level3_quota;
				end
				
				S_LEVEL_CHECK: begin //checks if we can continue to the next level
					if((score_counter >= target_score || skip_level_key_flag) && cur_level < 3)
						cur_level <= cur_level + 1;
					if(cur_level == 1)
						stored_grid_id <= {2'b00,random_val_grid} + 4'd3;
					if(cur_level == 2)
						stored_grid_id <= {2'b00,random_val_grid} + 4'd6;
				end
				
				S_GAME_RUN: begin
					if(treasure_type != 4'd0)
						latch_treasure_type <= treasure_type;
					if(collision_Hook_Treasure)
						carrying_object <= 1'b1;
					else if(claw_is_back && carrying_object ) begin// check if to add score
						carrying_object <= 1'b0;
						if(!time_up) begin
							sound_score_pulse <= 1'b1;
							case(latch_treasure_type) 
								4'd1: score_counter <= score_counter + 40; // big gold
								4'd2: score_counter <= score_counter + 20; // small gold
								4'd3: begin
									if(score_counter >= 50)
										score_counter <= score_counter - 50; // skull
									else 
										score_counter <= 0;
								end
								4'd4: score_counter <= score_counter + 10; // big rock
								4'd5: score_counter <= score_counter + 5; // Med Rock
								4'd6: score_counter <= score_counter + 2;  // Small Rock
								4'd7: score_counter <= score_counter + 80; // diamond
								default: ; //nothing
							endcase
						end
					end
				end
			endcase
		end
	end
	
	
	// output logic
	always_comb begin
		//default
		timer_start = 0;
		timer_enable = 0;
		timer_start_val = 7'd60;
		game_enable = 0;
		msg_select = 2'b00;
		load_new_map = 0;
		menu_mode = 0;
		final_screen_mode = 0;
		// --- Swing Speed Logic (New) ---
        // Determines angular velocity based on current level
        if (cur_level == 1)      swing_speed = 4'd1;
        else if (cur_level == 2) swing_speed = 4'd2;
        else                     swing_speed = 4'd3; 
        //
		
		case(cur_state)
			S_MENU: begin
				msg_select = 2'b00;
				menu_mode = 1;
			end
		
			S_LEVEL_SETUP: begin
				timer_start = 1;
				load_new_map = 1;
				//by levels
				if(cur_level == 1) timer_start_val = level1_time;
				else if(cur_level == 2) timer_start_val = level2_time;
				else timer_start_val = level3_time;
			end
		
			S_GAME_RUN: begin
				msg_select = 2'b01;
				timer_enable = 1;
				game_enable = 1;
			end
			
			S_LEVEL_CHECK: begin
				// right now nothing
			end
			
			S_GAME_OVER: begin
				msg_select = 2'b11; // lose screen 
				final_screen_mode = 1;
			end
			
			S_WIN_GAME: begin
				msg_select = 2'b10; // win screen
				final_screen_mode = 1;
			end	
		endcase
	end
	
	assign score = (score_counter > 999) ? 11'd999 : score_counter[10:0];
	assign level = cur_level[1:0];
	
endmodule
