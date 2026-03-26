module JukeBox1 (
    input logic [3:0] melodySelect, 
    input logic [4:0] noteIndex,    
    
    output logic [3:0] tone,        
    output logic [3:0] note_length, 
    output logic silenceOutN        
);

    // --- Note Definitions ---
    // Assuming Linear mapping for decoder (1=Low, 15=High)
    localparam [3:0] 
        SILENCE = 4'd0,
        C_LOW = 4'd1, D_LOW = 4'd2, E_LOW = 4'd3, F_LOW = 4'd4, G_LOW = 4'd5, A_LOW = 4'd6, B_LOW = 4'd7,
        C_MED = 4'd8, D_MED = 4'd9, E_MED = 4'd10, F_MED = 4'd11, G_MED = 4'd12, A_MED = 4'd13, B_MED = 4'd14,
        C_HI  = 4'd15; 

    always_comb begin
        // Default values
        tone = SILENCE;
        note_length = 4'd1;
        silenceOutN = 1'b0; 

        case (melodySelect)
            
            // ============================================================
            // 1: Arcade Start (Slower, Retro Style)
            // ============================================================
            4'd1: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Intro: Classic "Ready-Set-Go" vibe
                    5'd0:  begin tone = C_LOW; note_length = 4'd2; end
                    5'd1:  begin tone = G_LOW; note_length = 4'd2; end
                    5'd2:  begin tone = C_MED; note_length = 4'd2; end
                    5'd3:  begin tone = E_MED; note_length = 4'd2; end
                    5'd4:  begin tone = G_MED; note_length = 4'd2; end
                    5'd5:  begin tone = C_HI;  note_length = 4'd4; end // Hold top note
                    
                    // Middle: Little descent
                    5'd6:  begin tone = G_MED; note_length = 4'd2; end
                    5'd7:  begin tone = E_MED; note_length = 4'd2; end
                    5'd8:  begin tone = C_MED; note_length = 4'd4; end
                    
                    // Outro: Fun ending
                    5'd9:  begin tone = D_MED; note_length = 4'd2; end
                    5'd10: begin tone = F_MED; note_length = 4'd2; end
                    5'd11: begin tone = A_MED; note_length = 4'd2; end
                    5'd12: begin tone = G_MED; note_length = 4'd6; end // Long finish
                    
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 2: GAME OVER (Extended, Slow, Sad)
            // ============================================================
            4'd2: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Slow chromatic descent
                    5'd0: begin tone = C_HI;  note_length = 4'd4; end
                    5'd1: begin tone = B_MED; note_length = 4'd4; end
                    5'd2: begin tone = A_MED; note_length = 4'd4; end
                    5'd3: begin tone = G_MED; note_length = 4'd4; end
                    5'd4: begin tone = F_MED; note_length = 4'd4; end
                    5'd5: begin tone = E_MED; note_length = 4'd4; end
                    5'd6: begin tone = D_MED; note_length = 4'd4; end
                    // The final "thud" - very long and low
                    5'd7: begin tone = C_LOW; note_length = 4'd8; end 
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 3: SCORE INCREASE (Happy "Ka-Ching")
            // ============================================================
            4'd3: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Quick Major Arpeggio (Pleasant)
                    5'd0: begin tone = E_MED; note_length = 4'd1; end
                    5'd1: begin tone = G_MED; note_length = 4'd1; end
                    5'd2: begin tone = C_HI;  note_length = 4'd2; end 
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 4: GRAB (Soft Blip)
            // ============================================================
            4'd4: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Two notes, gentle sound
                    5'd0: begin tone = G_LOW; note_length = 4'd1; end
                    5'd1: begin tone = C_MED; note_length = 4'd1; end 
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 5: BUMP (Wall) - Lower Pitch
            // ============================================================
            4'd5: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Using the lowest notes available for a "Thud" sound
                    5'd0: begin tone = C_LOW; note_length = 4'd1; end
                    5'd1: begin tone = D_LOW; note_length = 4'd1; end
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 6: WINNER (Long, Regal Fanfare)
            // ============================================================
            4'd6: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Slow intro
                    5'd0: begin tone = C_MED; note_length = 4'd3; end
                    5'd1: begin tone = E_MED; note_length = 4'd3; end
                    5'd2: begin tone = G_MED; note_length = 4'd3; end
                    
                    // The build up (Faster)
                    5'd3: begin tone = C_MED; note_length = 4'd1; end
                    5'd4: begin tone = E_MED; note_length = 4'd1; end
                    5'd5: begin tone = G_MED; note_length = 4'd1; end
                    5'd6: begin tone = C_HI;  note_length = 4'd3; end

                    // Victory lap
                    5'd7: begin tone = G_MED; note_length = 4'd2; end
                    5'd8: begin tone = A_MED; note_length = 4'd2; end
                    5'd9: begin tone = B_MED; note_length = 4'd2; end
                    5'd10: begin tone = C_HI; note_length = 4'd8; end // Grand finale
                    
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 7: SKULL (Dissonant / Negative Sound)
            // ============================================================
            4'd7: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Dissonant interval / descending slide
                    5'd0: begin tone = F_MED; note_length = 4'd2; end // High
                    5'd1: begin tone = E_MED; note_length = 4'd1; end // Slide down
                    5'd2: begin tone = D_MED; note_length = 4'd1; end // Slide down
                    5'd3: begin tone = C_LOW; note_length = 4'd4; end // Low buzz
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // ============================================================
            // 8: LEVEL START ("Ready? Go!")
            // ============================================================
            4'd8: begin
                silenceOutN = 1'b1;
                case (noteIndex)
                    // Quick rising triad
                    5'd0: begin tone = C_MED; note_length = 4'd1; end
                    5'd1: begin tone = E_MED; note_length = 4'd1; end
                    5'd2: begin tone = G_MED; note_length = 4'd1; end
                    5'd3: begin tone = C_HI;  note_length = 4'd4; end // "Go!"
                    default: begin note_length = 4'd0; silenceOutN = 1'b0; end
                endcase
            end

            // Default Silence
            default: begin
                silenceOutN = 1'b0;
                tone = SILENCE;
                note_length = 4'd0;
            end

        endcase
    end
endmodule