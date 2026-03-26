
module melody_player_1 (
    input logic resetN,
    input logic CLOCK_31p5,
    input logic startMelodyKey, // Tied to '1' at Top-Level
    input logic [3:0] melodySelect, 
 
    output logic [3:0] tone,
    output logic EnableSoundOut,
    output logic melodyEnded        
);

    localparam logic [5:0] beat_duration = 6'd8; 
    localparam logic [4:0] gap_duration = 5'd2; 

    enum logic [1:0] {s_idle, s_playNote, s_gap, s_ended} SM_Maestro;

    logic [9:0] noteTimeCounter; 
    logic [9:0] noteDuration;    
    logic hundredthSecPulse; 

    logic [3:0] note_length;    
    logic silenceN;         
    logic [4:0] noteIndex;
    
    // Register to detect melody selection changes
    logic [3:0] last_melodySelect;
    
    assign noteDuration = beat_duration * note_length;        
            
    Mili_sec_counter #(.SIMULATION_MODE(1'h0), .mSecPerTick(10), .PLLClock(315)) mili_sec_counter_inst 
                     (.clk(CLOCK_31p5), .resetN(resetN), .turbo(1'h0), .hundredth_sec(hundredthSecPulse));
                                
    // Jukebox instance
    JukeBox1 JukeBox1 (.melodySelect(melodySelect), .noteIndex(noteIndex), .tone(tone), .note_length(note_length), .silenceOutN(silenceN));
    
    always_ff @(posedge CLOCK_31p5 or negedge resetN) begin    
        if (!resetN) begin 
            SM_Maestro <= s_idle;
            noteIndex <= 5'b0;
            noteTimeCounter <= 0;
            EnableSoundOut <= 1'b0;
            melodyEnded <= 1'b0;
            last_melodySelect <= 4'd0;
        end 
        else begin                 
            
            // --- Melody Change Detection Mechanism ---
            if (melodySelect != last_melodySelect) begin
                // If 0 is selected, force silence (override Jukebox default)
                if (melodySelect == 0) begin
                     SM_Maestro <= s_idle;
                end
                else begin 
                    // For any other ID, restart playback immediately
                    noteIndex <= 5'b0;        
                    SM_Maestro <= s_playNote; 
                    noteTimeCounter <= 0;     
                end
                last_melodySelect <= melodySelect;
            end
            
            // Default output values
            EnableSoundOut <= 1'b0;
            melodyEnded <= 1'b0;
        
            case (SM_Maestro)           
                s_idle: begin
                    noteIndex <= 5'b0;
                    // Waiting for selection change (handled in the if-block above)
                end 

                s_playNote: begin    
                    // Ensure silence if ID is 0, even if state is active
                    if (melodySelect != 0) EnableSoundOut <= silenceN;     
                    
                    if (note_length != 4'b0) begin 
                        if (hundredthSecPulse) noteTimeCounter <= noteTimeCounter - 10'b1;
                        if (noteTimeCounter == 10'b0) begin 
                            noteIndex <= noteIndex + 1'b1;   
                            SM_Maestro <= s_gap;    
                            noteTimeCounter <= gap_duration; 
                        end 
                    end   
                    else begin
                        SM_Maestro <= s_ended; // End of song
                    end
                end 

                s_gap: begin    
                    if (hundredthSecPulse) noteTimeCounter <= noteTimeCounter - 10'b1;  
                    if (noteTimeCounter == 10'b0) begin 
                        SM_Maestro <= s_playNote;     
                        noteTimeCounter <= noteDuration;      
                    end 
                end 

                s_ended: begin
                    melodyEnded <= 1'b1;    
                    SM_Maestro <= s_idle; // Melody finished -> Go to Idle (No Loop)
                end 

                default: SM_Maestro <= s_idle;
            endcase
        end 
    end 
endmodule


