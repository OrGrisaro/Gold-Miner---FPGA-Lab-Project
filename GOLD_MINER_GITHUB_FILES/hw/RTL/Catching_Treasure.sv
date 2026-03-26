module Catching_Treasure (
				 input  logic        clk,
				 input  logic        resetN,
				 input  logic        startOfFrame,
				 
				 input  logic [10:0] object_topLeftX, // Hook Position
				 input  logic [10:0] object_topLeftY, 
				 
				 input  logic [10:0] current_x_drawing, // Screen Scanning Coordinates
				 input  logic [10:0] current_y_drawing,

				 // Collision Inputs
				 input  logic        collision_Hook_Treasure, // Hit detected
				 input  logic [3:0]  current_treasure_id,     // ID of the hit treasure (from Map)
				 
				 input  logic        hook_returned_to_circle, // input from circular_motion

				 output logic        treasureDR, // Visual Outputs
				 output logic [7:0]  RGBout,
				 
				 // Logic Outputs (For Score / Game Manager)
				 output logic        collection_pulse,       // Pulses high when treasure reaches top
				 output logic [3:0]  caught_treasure_type,    // Outputs the ID of the collected treasure
				 output logic 			hook_is_carrying
);

    // --- Constants ---
    localparam int TREASURE_WIDTH  = 64;
    localparam int TREASURE_HEIGHT = 32;

    // --- Internal Registers ---
    logic [3:0] caught_object_id; 
    logic       is_carrying;  

	 assign hook_is_carrying = is_carrying;
    
    // --- Last Seen ID Logic (The Fix) ---
    // Variable to store the last ID seen on screen, to bridge timing gaps
    logic [3:0] last_seen_id; 

    // --- Coordinates Calculations ---
    logic [10:0] diffX;
    logic [10:0] diffY;
    logic        inside_rect;

    // --- Connect Internal Register to Output ---
    assign caught_treasure_type = caught_object_id;

    // --- ID Latching Logic (Mechanism to remember what was seen) ---
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            last_seen_id <= 4'h0;
        end else begin
            // Clear memory at the start of every new frame
            if (startOfFrame) begin
                last_seen_id <= 4'h0;
            end
            // If we currently see a treasure - save it to memory
            else if (current_treasure_id != 4'h0) begin
                last_seen_id <= current_treasure_id;
            end
        end
    end

    // --- State Machine ---
    always_ff @(posedge clk or negedge resetN) begin
        if (!resetN) begin
            is_carrying      <= 1'b0;
            caught_object_id <= 4'h0;
            collection_pulse <= 1'b0;
        end
        else begin
            collection_pulse <= 1'b0; 
            
            if (!is_carrying) begin
                // --- New Catch Condition ---
                if (collision_Hook_Treasure) begin 
                    // Priority 1: Check memory (what was just seen)
                    if (last_seen_id != 4'h0) begin
                        is_carrying      <= 1'b1;
                        caught_object_id <= last_seen_id; 
                    end
                    // Priority 2 (Backup): Check current pixel (in case of perfect sync)
                    else if (current_treasure_id != 4'h0) begin
                        is_carrying      <= 1'b1;
                        caught_object_id <= current_treasure_id;
                    end
                end
            end
            else begin
                // Release treasure when hook returns to top
                if (hook_returned_to_circle) begin
                    is_carrying      <= 1'b0; 
                    collection_pulse <= 1'b1;
                end
            end
        end
    end

    // --- Drawing Logic ---
    assign diffX = current_x_drawing - object_topLeftX;
    assign diffY = current_y_drawing - object_topLeftY;

    // Check if current pixel is within the square below the hook
    assign inside_rect = (current_x_drawing >= object_topLeftX) && 
                         (current_x_drawing <  object_topLeftX + TREASURE_WIDTH) &&
                         (current_y_drawing >= object_topLeftY + 32) && 
                         (current_y_drawing <  object_topLeftY + 32 + TREASURE_HEIGHT);

    // --- Instantiate the Bitmap Module ---
    Mine_Objects_BitMap treasure_renderer (
        .clk(clk),
        .resetN(resetN),
        .offsetX(diffX),       
        .offsetY(diffY - 32),
        .InsideRectangle(inside_rect && is_carrying), // Draw only if carrying AND inside rectangle
        .objectId(caught_object_id), 
        
        .drawingRequest(treasureDR),
        .RGBout(RGBout)
    );

endmodule