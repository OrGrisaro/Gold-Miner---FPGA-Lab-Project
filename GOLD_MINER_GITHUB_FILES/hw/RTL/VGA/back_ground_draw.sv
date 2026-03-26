

// (c) Technion IIT, Department of Electrical Engineering 2025

module back_ground_draw (    
    input   logic        clk,
    input   logic        resetN,
    input   logic [10:0] pixelX,
    input   logic [10:0] pixelY,

    output  logic [7:0]  BG_RGB,
    output  logic        boardersDrawReq 
);

    const int xFrameSize = 635;
    const int yFrameSize = 475;
    const int bracketOffset = 32;

    localparam int GROUND_Y = 64;         // Start height of the mine
    localparam int BORDER_THICKNESS = 4;  

    logic [2:0] redBits;
    logic [2:0] greenBits;
    logic [1:0] blueBits;
    
    // Helper flag to determine if the current pixel is a border
    logic is_border;

    always_ff @(posedge clk or negedge resetN) begin
        if(!resetN) begin
            redBits   <= 0;    
            greenBits <= 0;    
            blueBits  <= 0;    
            boardersDrawReq <= 0;
            BG_RGB <= 0;
        end 
        else begin
            // --- 1. Calculate if we are currently on a border ---
            is_border = 1'b0; // Default

            // Left Border - Constrained vertically (Top: GROUND_Y, Bottom: End of Bottom Border)
            if ((pixelX <= bracketOffset) && 
                (pixelX >= (bracketOffset - BORDER_THICKNESS)) && 
                (pixelY >= GROUND_Y) && 
                // ADDED: Stop at the bottom edge of the bottom border
                (pixelY <= (yFrameSize - (bracketOffset - BORDER_THICKNESS)))) begin
                is_border = 1'b1;
            end 
            
            // Right Border - Constrained vertically
            else if ((pixelX >= (xFrameSize - bracketOffset)) && 
                     (pixelX <= (xFrameSize - (bracketOffset - BORDER_THICKNESS))) && 
                     (pixelY >= GROUND_Y) &&
                     // ADDED: Stop at the bottom edge of the bottom border
                     (pixelY <= (yFrameSize - (bracketOffset - BORDER_THICKNESS)))) begin
                is_border = 1'b1;
            end
            
            // Bottom Border - Restricted width (connects the side borders)
            else if ((pixelY >= (yFrameSize - bracketOffset)) && 
                     (pixelY <= (yFrameSize - (bracketOffset - BORDER_THICKNESS))) &&
                     // X-Axis Limit: Connect left and right borders
                     (pixelX >= (bracketOffset - BORDER_THICKNESS)) && 
                     (pixelX <= (xFrameSize - (bracketOffset - BORDER_THICKNESS)))) begin
                is_border = 1'b1;
            end


            // --- 2. Set final color based on the calculation result ---
            if (is_border) begin
                // Border Color: 8'h49 (Blue=01, Red=001, Green=001)
                blueBits  <= 2'b01;
                redBits   <= 3'b001;    
                greenBits <= 3'b001;    
                
                boardersDrawReq <= 1'b1;
            end
            else begin
                // Background Color: Light Green/Turquoise
                greenBits <= 3'b111; 
                redBits   <= 3'b000; 
                blueBits  <= 2'b11; 
                boardersDrawReq <= 1'b0; 
            end
            
            BG_RGB <= { blueBits, redBits, greenBits };      
        end
    end 
endmodule