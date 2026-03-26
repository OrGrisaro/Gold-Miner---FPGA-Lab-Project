module MelodyMux (
    input logic clk,
    input logic resetN,
    
    // --- Inputs from Game Controller ---
    input logic score_pulse,        // Scoring pulse (claw returned)
    input logic collision,          // Raw collision signal (wall OR treasure)
    input logic col_hook_tres,      // Is it a treasure?
    input logic [3:0] treasure_type,// ID of the caught treasure (3 = Skull)
    input logic [1:0] msg_select,   // Current Screen (00=Menu, 01=Game, 10=Win, 11=Lose)
    input logic [1:0] level,        // Game Level (Maintained for interface compatibility)
    
    // --- Input from Player ---
    input logic melodyEnded,        // Signal when melody finishes
    
    // --- Output ---
    output logic [3:0] melody_select_out
);

    // --- Edge Detection ---
    logic collision_d, collision_rise;
    logic [1:0] msg_select_d;
    logic game_run_rise; 

    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            collision_d  <= 1'b0;
            msg_select_d <= 2'b00;
        end else begin
            collision_d  <= collision;
            msg_select_d <= msg_select;
        end
    end
    
    // Detect collision rising edge (0 -> 1)
    assign collision_rise = collision && !collision_d;
    
    // Detect transition INTO Game Mode (01) to trigger Level Start sound
    assign game_run_rise = (msg_select == 2'b01) && (msg_select_d != 2'b01);

    // --- State Machine Definitions ---
    typedef enum logic [2:0] {
        S_BACKGROUND, 
        S_WAIT_SYNC,   // Wait state to identify collision type
        S_PLAY_GRAB,   // Play grab sound (Index 4)
        S_PLAY_SCORE,  // Play positive score sound (Index 3)
        S_PLAY_SKULL,  // Play negative score sound (Index 7)
        S_PLAY_BUMP,   // Play bump sound (Index 5)
        S_PLAY_LEVEL   // Play level start jingle (Index 8)
    } state_t;

    state_t current_state, next_state;

    // --- Sequential Logic ---
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) 
            current_state <= S_BACKGROUND;
        else 
            current_state <= next_state;
    end

    // --- Next State Logic ---
    always_comb begin
        next_state = current_state; 
        
        // Master Reset: If back to Main Menu (00), force Background state immediately
        if (msg_select == 2'b00) begin
            next_state = S_BACKGROUND;
        end
        else begin
            case (current_state)
                S_BACKGROUND: begin
                    // Priority 1: Level Start (Transition to Game)
                    if (game_run_rise)
                        next_state = S_PLAY_LEVEL;

                    // Priority 2: Score Pulse (Claw returned)
                    else if (score_pulse) begin
                        // Check if the caught item was a Skull (ID 3)
                        if (treasure_type == 4'd3)
                            next_state = S_PLAY_SKULL;
                        else
                            next_state = S_PLAY_SCORE;
                    end
                    
                    // Priority 3: New Collision (Wall or start of catch)
                    else if (collision_rise) 
                        next_state = S_WAIT_SYNC; 
                end

                S_PLAY_LEVEL: begin
                    if (melodyEnded) next_state = S_BACKGROUND;
                    // Allow score/collision to interrupt immediately
                    else if (score_pulse) next_state = S_PLAY_SCORE; 
                    else if (collision_rise) next_state = S_WAIT_SYNC;
                end

                S_WAIT_SYNC: begin
                    // Wait 1 cycle for signals to stabilize
                    if (col_hook_tres) next_state = S_PLAY_GRAB; // It's a treasure
                    else               next_state = S_PLAY_BUMP; // It's a wall
                end

                S_PLAY_GRAB: begin
                    if (collision_rise) next_state = S_WAIT_SYNC;
                    else if (melodyEnded) next_state = S_BACKGROUND;
                end

                S_PLAY_SCORE: begin
                    if (melodyEnded) next_state = S_BACKGROUND;
                end

                S_PLAY_SKULL: begin
                    if (melodyEnded) next_state = S_BACKGROUND;
                end

                S_PLAY_BUMP: begin
                    // Allow interruption if score update occurs
                    if (score_pulse) begin
                         if (treasure_type == 4'd3) next_state = S_PLAY_SKULL;
                         else                       next_state = S_PLAY_SCORE;
                    end
                    else if (melodyEnded) next_state = S_BACKGROUND;
                end
                
                default: next_state = S_BACKGROUND;
            endcase
        end
    end

    // --- Output Logic ---
    always_comb begin
        case (current_state)
            S_PLAY_SCORE: melody_select_out = 4'd3; // Happy Score
            S_PLAY_GRAB:  melody_select_out = 4'd4; // Soft Grab
            S_PLAY_BUMP:  melody_select_out = 4'd5; // Wall Bump
            S_WAIT_SYNC:  melody_select_out = 4'd5; // Hold Bump during sync
            S_PLAY_SKULL: melody_select_out = 4'd7; // Sad Skull Sound
            S_PLAY_LEVEL: melody_select_out = 4'd8; // Level Start Jingle
            
            S_BACKGROUND: begin
                // --- Background Music Logic ---
                
                // Menu Screen (00) -> Play Start Melody
                if (msg_select == 2'b00) 
                    melody_select_out = 4'd1; 

                // Win Screen (10) -> Play Fanfare
                else if (msg_select == 2'b10) 
                    melody_select_out = 4'd6; 

                // Lose Screen (11) -> Play Sad Melody
                else if (msg_select == 2'b11) 
                    melody_select_out = 4'd2; 

                // Gameplay (01) -> Silence (Allow room for SFX)
                else 
                    melody_select_out = 4'd0; 
            end
            
            default: melody_select_out = 4'd0;
        endcase
    end

endmodule