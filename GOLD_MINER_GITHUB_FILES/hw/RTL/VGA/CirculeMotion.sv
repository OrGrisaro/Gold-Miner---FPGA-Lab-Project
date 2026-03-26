
module CirculeMotion (
    input  logic        clk,
    input  logic        resetN,    
    input  logic        startOfFrame,      // Short pulse every start of frame (30Hz)
    input  logic        movment_stop,      // Stop motion request
    input  logic        movment_continue,  // Resume motion request
    input  logic [3:0]  SWING_SPEED,       // determine the velocity according to the level
    
    output logic signed [10:0] x_out,       // Output X position 
    output logic signed [10:0] y_out,       // Output Y position 
    output logic signed [15:0] cos_degree,  // Output Cosine of current angle
    output logic signed [15:0] sin_degree,  // Output Sine of current angle
    output logic signed [7:0]  hook_degree  // Output current angle
);

    // --- Parameters ---
    parameter int x_center = 295;
    parameter int y_center = 32;
    parameter int Radius   = 64; 

    // --- Internal Signals ---
    logic [7:0] degree; // Current angle
    logic [1:0] pre_state; // Saved state for resuming motion

    // --- State Machine Definition ---
    enum logic [2:0] {
        IDLE_ST,                 
        MOVE_RIGHT_TO_BOTTOM_ST, // 0 -> 90
        MOVE_BOTTOM_TO_LEFT_ST,  // 90 -> 180
        MOVE_LEFT_TO_BOTTOM_ST,  // 180 -> 90
        MOVE_BOTTOM_TO_RIGHT_ST, // 90 -> 0
        STOP_MOVMENT_ST          // Motion paused
    } SM_Circular_Motion;

    // =============================================================
    // LUT: Sin(angle) 0 to -180 mapped to 0-180 index. 
    // Fixed Point Q10 (multiplied by 1024)
    // =============================================================
    const logic signed [15:0] sin_map [0:180] = '{
        16'h0000, 16'hFFEF, 16'hFFDD, 16'hFFCB, 16'hFFB9, 16'hFFA7, 16'hFF95, 16'hFF84, 16'hFF72, 16'hFF60, 
        16'hFF4F, 16'hFF3D, 16'hFF2C, 16'hFF1A, 16'hFF09, 16'hFEF7, 16'hFEE6, 16'hFED5, 16'hFEC4, 16'hFEB3, 
        16'hFEA2, 16'hFE92, 16'hFE81, 16'hFE70, 16'hFE60, 16'hFE50, 16'hFE40, 16'hFE30, 16'hFE20, 16'hFE10, 
        16'hFE01, 16'hFDF1, 16'hFDE2, 16'hFDD3, 16'hFDC4, 16'hFDB5, 16'hFDA7, 16'hFD98, 16'hFD8A, 16'hFD7C, 
        16'hFD6E, 16'hFD61, 16'hFD53, 16'hFD46, 16'hFD39, 16'hFD2C, 16'hFD20, 16'hFD14, 16'hFD08, 16'hFCFC, 
        16'hFCF0, 16'hFCE5, 16'hFCDA, 16'hFCCF, 16'hFCC4, 16'hFCBA, 16'hFCB0, 16'hFCA6, 16'hFC9C, 16'hFC93, 
        16'hFC8A, 16'hFC81, 16'hFC78, 16'hFC70, 16'hFC68, 16'hFC60, 16'hFC59, 16'hFC52, 16'hFC4B, 16'hFC45, 
        16'hFC3E, 16'hFC38, 16'hFC33, 16'hFC2D, 16'hFC28, 16'hFC23, 16'hFC1F, 16'hFC1B, 16'hFC17, 16'hFC13, 
        16'hFC10, 16'hFC0D, 16'hFC0A, 16'hFC08, 16'hFC06, 16'hFC04, 16'hFC03, 16'hFC02, 16'hFC01, 16'hFC01, 
        16'hFC00,                                                                                           
        16'hFC01, 16'hFC01, 16'hFC02, 16'hFC03, 16'hFC04, 16'hFC06, 16'hFC08, 16'hFC0A, 16'hFC0D, 16'hFC10, 
        16'hFC13, 16'hFC17, 16'hFC1B, 16'hFC1F, 16'hFC23, 16'hFC28, 16'hFC2D, 16'hFC33, 16'hFC38, 16'hFC3E, 
        16'hFC45, 16'hFC4B, 16'hFC52, 16'hFC59, 16'hFC60, 16'hFC68, 16'hFC70, 16'hFC78, 16'hFC81, 16'hFC8A, 
        16'hFC93, 16'hFC9C, 16'hFCA6, 16'hFCB0, 16'hFCBA, 16'hFCC4, 16'hFCCF, 16'hFCDA, 16'hFCE5, 16'hFCF0, 
        16'hFCFC, 16'hFD08, 16'hFD14, 16'hFD20, 16'hFD2C, 16'hFD39, 16'hFD46, 16'hFD53, 16'hFD61, 16'hFD6E, 
        16'hFD7C, 16'hFD8A, 16'hFD98, 16'hFDA7, 16'hFDB5, 16'hFDC4, 16'hFDD3, 16'hFDE2, 16'hFDF1, 16'hFE01, 
        16'hFE10, 16'hFE20, 16'hFE30, 16'hFE40, 16'hFE50, 16'hFE60, 16'hFE70, 16'hFE81, 16'hFE92, 16'hFEA2, 
        16'hFEB3, 16'hFEC4, 16'hFED5, 16'hFEE6, 16'hFEF7, 16'hFF09, 16'hFF1A, 16'hFF2C, 16'hFF3D, 16'hFF4F, 
        16'hFF60, 16'hFF72, 16'hFF84, 16'hFF95, 16'hFFA7, 16'hFFB9, 16'hFFCB, 16'hFFDD, 16'hFFEF, 16'h0000  
    };

    // =============================================================
    // LUT: Cos(angle) 0 to -180 mapped to 0-180 index.
    // Fixed Point Q10 (multiplied by 1024)
    // =============================================================
    const logic signed [15:0] cos_map [0:180] = '{
        16'h0400, 16'h03FF, 16'h03FF, 16'h03FE, 16'h03FD, 16'h03FC, 16'h03FA, 16'h03F8, 16'h03F6, 16'h03F3, 
        16'h03F0, 16'h03ED, 16'h03E9, 16'h03E5, 16'h03E1, 16'h03DD, 16'h03D8, 16'h03D3, 16'h03CD, 16'h03C8, 
        16'h03C2, 16'h03BB, 16'h03B5, 16'h03AE, 16'h03A7, 16'h03A0, 16'h0398, 16'h0390, 16'h0388, 16'h037F, 
        16'h0376, 16'h036D, 16'h0364, 16'h035A, 16'h0350, 16'h0346, 16'h033C, 16'h0331, 16'h0326, 16'h031B, 
        16'h0310, 16'h0304, 16'h02F8, 16'h02EC, 16'h02E0, 16'h02D4, 16'h02C7, 16'h02BA, 16'h02AD, 16'h029F, 
        16'h0292, 16'h0284, 16'h0276, 16'h0268, 16'h0259, 16'h024B, 16'h023C, 16'h022D, 16'h021E, 16'h020F, 
        16'h0200, 16'h01F0, 16'h01E0, 16'h01D0, 16'h01C0, 16'h01B0, 16'h01A0, 16'h0190, 16'h017F, 16'h016E, 
        16'h015E, 16'h014D, 16'h013C, 16'h012B, 16'h011A, 16'h0109, 16'h00F7, 16'h00E6, 16'h00D4, 16'h00C3, 
        16'h00B1, 16'h00A0, 16'h008E, 16'h007C, 16'h006B, 16'h0059, 16'h0047, 16'h0035, 16'h0023, 16'h0011, 
        16'h0000,                                                                                           
        16'hFFEF, 16'hFFDD, 16'hFFCB, 16'hFFB9, 16'hFFA7, 16'hFF95, 16'hFF84, 16'hFF72, 16'hFF60, 16'hFF4F, 
        16'hFF3D, 16'hFF2C, 16'hFF1A, 16'hFF09, 16'hFEF7, 16'hFEE6, 16'hFED5, 16'hFEC4, 16'hFEB3, 16'hFEA2, 
        16'hFE92, 16'hFE81, 16'hFE70, 16'hFE60, 16'hFE50, 16'hFE40, 16'hFE30, 16'hFE20, 16'hFE10, 16'hFE01, 
        16'hFDF1, 16'hFDE2, 16'hFDD3, 16'hFDC4, 16'hFDB5, 16'hFDA7, 16'hFD98, 16'hFD8A, 16'hFD7C, 16'hFD6E, 
        16'hFD61, 16'hFD53, 16'hFD46, 16'hFD39, 16'hFD2C, 16'hFD20, 16'hFD14, 16'hFD08, 16'hFCFC, 16'hFCF0, 
        16'hFCE5, 16'hFCDA, 16'hFCCF, 16'hFCC4, 16'hFCBA, 16'hFCB0, 16'hFCA6, 16'hFC9C, 16'hFC93, 16'hFC8A, 
        16'hFC81, 16'hFC78, 16'hFC70, 16'hFC68, 16'hFC60, 16'hFC59, 16'hFC52, 16'hFC4B, 16'hFC45, 16'hFC3E, 
        16'hFC38, 16'hFC33, 16'hFC2D, 16'hFC28, 16'hFC23, 16'hFC1F, 16'hFC1B, 16'hFC17, 16'hFC13, 16'hFC10, 
        16'hFC0D, 16'hFC0A, 16'hFC08, 16'hFC06, 16'hFC04, 16'hFC03, 16'hFC02, 16'hFC01, 16'hFC01, 16'hFC00  
    };


    always_ff @(posedge clk or negedge resetN) begin : fsm_sync_proc

        if (!resetN) begin
            SM_Circular_Motion <= IDLE_ST;
            degree <= 8'd0;
            pre_state <= 2'b00;
            x_out <= x_center + Radius; // Start at right edge
            y_out <= y_center;
            cos_degree <= 16'h0400; // cos(0) = 1 (1024)
            sin_degree <= 0;
            hook_degree <= 8'd0;
        end
        else begin
            // Calculate Position: Center + (Radius * val) / 1024
            x_out <= x_center + ((Radius * cos_map[degree]) >>> 10);
            y_out <= y_center - ((Radius * sin_map[degree]) >>> 10);
            
            // Output current trigonometry values
            cos_degree <= cos_map[degree];
            sin_degree <= sin_map[degree];
            hook_degree <= degree;
            
            case(SM_Circular_Motion)
            
                //------------
                IDLE_ST: begin
                //------------
                    degree <= 0;
                    if (startOfFrame) 
                        SM_Circular_Motion <= MOVE_RIGHT_TO_BOTTOM_ST;
                end
                    
                //------------
                MOVE_RIGHT_TO_BOTTOM_ST: begin
                //------------
                    pre_state <= 2'b00;
                    
                    if (movment_stop)
                        SM_Circular_Motion <= STOP_MOVMENT_ST;

                    // Transition Check (>= used to handle speed jumps)
                    else if (degree >= 90) 
                        SM_Circular_Motion <= MOVE_BOTTOM_TO_LEFT_ST;
        
                    else if (startOfFrame) begin
                        // Prevent overshooting 90
                        if (degree + SWING_SPEED > 90)
                            degree <= 90;
                        else
                            degree <= degree + SWING_SPEED;
                    end
                end 
                
                //------------
                MOVE_BOTTOM_TO_LEFT_ST: begin
                //------------
                    pre_state <= 2'b01;
                    
                    if (movment_stop)
                        SM_Circular_Motion <= STOP_MOVMENT_ST;
                        
                    // Transition Check
                    else if (degree >= 180) 
                        SM_Circular_Motion <= MOVE_LEFT_TO_BOTTOM_ST;
        
                    else if (startOfFrame) begin
                        // Prevent overshooting 180
                        if (degree + SWING_SPEED > 180)
                            degree <= 180;
                        else
                            degree <= degree + SWING_SPEED;
                    end    
                end 
            
                //------------
                MOVE_LEFT_TO_BOTTOM_ST: begin
                //------------
                    pre_state <= 2'b10;
                    
                    if (movment_stop)
                        SM_Circular_Motion <= STOP_MOVMENT_ST;
                        
                    // Transition Check (Moving backwards now)
                    else if (degree <= 90) 
                        SM_Circular_Motion <= MOVE_BOTTOM_TO_RIGHT_ST;
        
                    else if (startOfFrame) begin
                        // Prevent undershooting 90
                        if (degree < 90 + SWING_SPEED)
                            degree <= 90;
                        else
                            degree <= degree - SWING_SPEED;
                    end    
                end
            
                //------------
                MOVE_BOTTOM_TO_RIGHT_ST: begin
                //------------
                    pre_state <= 2'b11;
                    
                    if (movment_stop)
                        SM_Circular_Motion <= STOP_MOVMENT_ST;
                        
                    // Transition Check
                    else if (degree == 0) // or <= 0
                        SM_Circular_Motion <= MOVE_RIGHT_TO_BOTTOM_ST;
        
                    else if (startOfFrame) begin
                        // Prevent undershooting 0
                        if (degree < SWING_SPEED)
                            degree <= 0;
                        else
                            degree <= degree - SWING_SPEED;
                    end            
                end
            
                //------------
                STOP_MOVMENT_ST: begin
                //------------
                    if (movment_continue) begin
                        // Restore state based on where we stopped
                        case (pre_state)
                            2'b00: SM_Circular_Motion <= MOVE_RIGHT_TO_BOTTOM_ST;
                            2'b01: SM_Circular_Motion <= MOVE_BOTTOM_TO_LEFT_ST;
                            2'b10: SM_Circular_Motion <= MOVE_LEFT_TO_BOTTOM_ST;
                            2'b11: SM_Circular_Motion <= MOVE_BOTTOM_TO_RIGHT_ST;     
                        endcase
                    end
                end
                
            endcase
        end
    end
endmodule