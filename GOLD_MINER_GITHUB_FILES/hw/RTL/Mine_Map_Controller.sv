

module Mine_Map_Controller (  
			 input  logic        clk,
			 input  logic        resetN,
			 input  logic [10:0] offsetX,        
			 input  logic [10:0] offsetY,        
			 input  logic        InsideRectangle,    
			 input  logic        collision_hook_treasure, 

			 input  logic [3:0]  map_select, 
			 input  logic        load_map,   

			 output logic        drawingRequest, 
			 output logic [7:0]  RGBout,
			 
			 output logic [3:0]  hit_object_id,
			 output logic [3:0]  map_current_id_out 
);

    // Parameters & Constants 
    localparam int TILE_NUMBER_OF_X_BITS = 6;  //object up to 64x32
    localparam int TILE_NUMBER_OF_Y_BITS = 5;
	 
    localparam int MAZE_NUMBER_OF__X_BITS = 3; //grid of 8x8   
    localparam int MAZE_NUMBER_OF__Y_BITS = 3; 

    localparam int TILE_WIDTH_X = 1 << TILE_NUMBER_OF_X_BITS;
    localparam int TILE_HEIGHT_Y = 1 << TILE_NUMBER_OF_Y_BITS;
    localparam int MAZE_WIDTH_X = 1 << MAZE_NUMBER_OF__X_BITS;
    localparam int MAZE_HEIGHT_Y = 1 << MAZE_NUMBER_OF__Y_BITS; 

    // Calculate Offsets 
    logic [10:0] offsetX_LSB;
    logic [10:0] offsetY_LSB; 
    logic [MAZE_NUMBER_OF__X_BITS-1:0] offsetX_MSB; 
    logic [MAZE_NUMBER_OF__Y_BITS-1:0] offsetY_MSB; 

    assign offsetX_LSB = offsetX[(TILE_NUMBER_OF_X_BITS-1):0]; 
    assign offsetY_LSB = offsetY[(TILE_NUMBER_OF_Y_BITS-1):0]; 
    
    assign offsetX_MSB = offsetX[(TILE_NUMBER_OF_X_BITS + MAZE_NUMBER_OF__X_BITS -1):TILE_NUMBER_OF_X_BITS]; 
    assign offsetY_MSB = offsetY[(TILE_NUMBER_OF_Y_BITS + MAZE_NUMBER_OF__Y_BITS -1):TILE_NUMBER_OF_Y_BITS]; 

    // Maze Map Logic 
    logic [0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MazeBitMapMask;  

    // Logic Variables 
    logic [MAZE_NUMBER_OF__X_BITS-1:0] last_seen_tile_X;
    logic [MAZE_NUMBER_OF__Y_BITS-1:0] last_seen_tile_Y;
    logic [3:0]                         last_seen_id_valid;
    int                                 delete_cooldown_timer; 
	 

    // Map Definitions:

	 
	 // ================= LEVEL 1 (Maps 0-2) =================	
	 
    // MAP 0: 
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_0 = {
        {4'h0, 4'h2, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0, 4'h0}, 
        {4'h0, 4'h0, 4'h0, 4'h1, 4'h0, 4'h0, 4'h0, 4'h2}, 
        {4'h2, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0}, 
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h0, 4'h0}, 
        {4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0}, 
        {4'h1, 4'h0, 4'h0, 4'h2, 4'h0, 4'h4, 4'h0, 4'h0}, 
        {4'h0, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0, 4'h0, 4'h5}, 
        {4'h0, 4'h2, 4'h0, 4'h0, 4'h5, 4'h0, 4'h2, 4'h0} 
    };

    // MAP 1: 
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_1 = {
        {4'h0, 4'h0, 4'h2, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h4, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h1, 4'h0, 4'h4, 4'h0, 4'h0, 4'h1, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h6, 4'h0, 4'h2},
        {4'h2, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0, 4'h5, 4'h0},
        {4'h0, 4'h5, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h1}
    };

    // MAP 2:
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_2 = {
        {4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h2},
        {4'h0, 4'h0, 4'h4, 4'h0, 4'h0, 4'h1, 4'h0, 4'h0},
        {4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h1, 4'h0, 4'h0, 4'h2, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h0, 4'h0, 4'h4, 4'h0, 4'h4, 4'h0, 4'h0, 4'h1},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h5, 4'h0, 4'h0, 4'h0, 4'h0, 4'h7, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h5}
    };


    // ================= LEVEL 2 (Maps 3-5) =================

    // MAP 3:
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_3 = {
        {4'h0, 4'h5, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0, 4'h2},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h1, 4'h0},
        {4'h4, 4'h0, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h3, 4'h2, 4'h0, 4'h0, 4'h3, 4'h0, 4'h6},
        {4'h0, 4'h6, 4'h0, 4'h0, 4'h5, 4'h0, 4'h0, 4'h0},
        {4'h7, 4'h0, 4'h0, 4'h5, 4'h0, 4'h0, 4'h5, 4'h0},
        {4'h5, 4'h0, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h0},
        {4'h0, 4'h2, 4'h0, 4'h7, 4'h1, 4'h0, 4'h0, 4'h7}
    };

    // MAP 4: 
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_4 = {
        {4'h0, 4'h0, 4'h0, 4'h6, 4'h0, 4'h2, 4'h0, 4'h0},
        {4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h5, 4'h0},
        {4'h0, 4'h0, 4'h5, 4'h0, 4'h1, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h2},
        {4'h0, 4'h0, 4'h0, 4'h3, 4'h0, 4'h6, 4'h0, 4'h0},
        {4'h6, 4'h7, 4'h0, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h0, 4'h0, 4'h1, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0},
        {4'h3, 4'h2, 4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0}
    };

    // MAP 5:
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_5 = {
        {4'h0, 4'h0, 4'h0, 4'h5, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h2, 4'h0, 4'h0, 4'h0, 4'h2, 4'h0, 4'h5},
        {4'h0, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h5, 4'h0, 4'h0, 4'h1, 4'h0, 4'h3, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h7, 4'h3, 4'h0, 4'h6, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h7, 4'h0, 4'h1},
        {4'h2, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0}
    };


    // ================= LEVEL 3 (Maps 6-8) =================

    // MAP 6: 
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_6 = {
        {4'h0, 4'h0, 4'h0, 4'h3, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h5, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0, 4'h3},
        {4'h3, 4'h0, 4'h0, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h7, 4'h0, 4'h0, 4'h7, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h1, 4'h0, 4'h0, 4'h5},
        {4'h0, 4'h4, 4'h0, 4'h3, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h7, 4'h0, 4'h0},
        {4'h3, 4'h0, 4'h1, 4'h0, 4'h0, 4'h0, 4'h0, 4'h3}
    };

    // MAP 7: 
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_7 = {
        {4'h2, 4'h4, 4'h0, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h3, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h5, 4'h0, 4'h0},
        {4'h0, 4'h5, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0},
        {4'h3, 4'h0, 4'h3, 4'h0, 4'h0, 4'h3, 4'h0, 4'h0},
        {4'h0, 4'h4, 4'h0, 4'h1, 4'h0, 4'h0, 4'h0, 4'h6},
        {4'h7, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h5, 4'h0},
        {4'h0, 4'h0, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0, 4'h7}
    };

    // MAP 8:  
    localparam logic[0:MAZE_HEIGHT_Y-1][0:MAZE_WIDTH_X-1][3:0] MAP_8 = {
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h2},
        {4'h0, 4'h0, 4'h2, 4'h5, 4'h0, 4'h0, 4'h4, 4'h0},
        {4'h2, 4'h6, 4'h0, 4'h0, 4'h0, 4'h4, 4'h0, 4'h0},
        {4'h0, 4'h0, 4'h3, 4'h0, 4'h3, 4'h0, 4'h0, 4'h0},
        {4'h4, 4'h0, 4'h0, 4'h7, 4'h0, 4'h0, 4'h2, 4'h1},
        {4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h3, 4'h0, 4'h0},
        {4'h0, 4'h3, 4'h6, 4'h0, 4'h7, 4'h0, 4'h0, 4'h0},
        {4'h7, 4'h0, 4'h0, 4'h0, 4'h0, 4'h0, 4'h7, 4'h0}
    };
	 
    // Determine Current Object ID
    logic [3:0] current_object_id;
    assign current_object_id = ((InsideRectangle) && (offsetX < 512)) ? MazeBitMapMask[offsetY_MSB][offsetX_MSB] : 4'h0;
    
    assign map_current_id_out = current_object_id;

    // Instantiate Renderer 
    Mine_Objects_BitMap objects_renderer (
        .clk(clk),
        .resetN(resetN),
        .offsetX(offsetX_LSB),       
        .offsetY(offsetY_LSB),       
        .InsideRectangle(InsideRectangle), 
        .objectId(current_object_id), 
        .drawingRequest(drawingRequest),
        .RGBout(RGBout)
    );

    // Map Update Logic 
    always_ff @(posedge clk or negedge resetN) begin
        if(!resetN) begin
            MazeBitMapMask <= MAP_0; 
            hit_object_id  <= 4'h0; 
            last_seen_tile_X <= 0;
            last_seen_tile_Y <= 0;
            last_seen_id_valid <= 4'h0;
            delete_cooldown_timer <= 0; // Reset timer
        end
        else begin
            hit_object_id <= 4'h0; 

            //  1. Cooldown Timer: Decrement at start of frame 
            if (offsetY == 0 && offsetX == 0) begin
                if (delete_cooldown_timer > 0)
                    delete_cooldown_timer <= delete_cooldown_timer - 1;
            end

            // 2. Latch Last Seen Object Location
            if (InsideRectangle && current_object_id != 4'h0) begin
                last_seen_tile_X   <= offsetX_MSB;
                last_seen_tile_Y   <= offsetY_MSB;
                last_seen_id_valid <= current_object_id;
            end

            // 3. Map Loading
            if(load_map) begin
                 case(map_select)
                    4'd0: MazeBitMapMask <= MAP_0;
                    4'd1: MazeBitMapMask <= MAP_1;
                    4'd2: MazeBitMapMask <= MAP_2;
                    4'd3: MazeBitMapMask <= MAP_3;
                    4'd4: MazeBitMapMask <= MAP_4;
                    4'd5: MazeBitMapMask <= MAP_5;
                    4'd6: MazeBitMapMask <= MAP_6;
                    4'd7: MazeBitMapMask <= MAP_7;
                    4'd8: MazeBitMapMask <= MAP_8;
                    default: MazeBitMapMask <= MAP_0;
                 endcase 
            end
            
            //  4. Protected Deletion Logic 
            else if (collision_hook_treasure) begin
                // Delete only if location is valid AND cooldown finished
                if (last_seen_id_valid != 4'h0 && delete_cooldown_timer == 0) begin
                    
                    hit_object_id <= last_seen_id_valid;
                    MazeBitMapMask[last_seen_tile_Y][last_seen_tile_X] <= 4'h00; 
                    
                    // Activate cooldown timer
                    delete_cooldown_timer <= 30; 
                end
            end
        end 
    end

endmodule