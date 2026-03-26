module line_drawing (
    input  logic        clk,
    input  logic        resetN,
    input  logic        startOfFrame,
    input  logic [10:0] object_topLeftX, // Hook top-left X
    input  logic [10:0] object_topLeftY, // Hook top-left Y
    input  logic [10:0] current_x_drawing,
    input  logic [10:0] current_y_drawing,

    output logic        drawingRequest,
    output logic [7:0]  RGBout
);

    // --- Signed Variables for Line Equation ---
    int signed x, y;
    int signed x1, y1; // Anchor point (Fixed physics origin)
    int signed x2, y2; // Target point (Moving Hook center)
    
    int signed a, b, epsilon;
    int signed abs_dx, abs_dy;
    
    // Variable for visual masking (where the rope actually starts drawing)
    int signed visual_start_y;

    // Bounding box flags
    logic in_x_bounds, in_y_bounds;

    // --- Parameters ---
    logic [4:0] epsilon_star = 5'd2; // Line width factor
    
    // Mathematical center (Anchor) - The rope angle is calculated from here
    parameter int X_CENTER = 327; 
    parameter int Y_CENTER = 32;

    always_comb begin
        // 1. Cast current pixel coordinates to signed
        x  = signed'({1'b0, current_x_drawing});
        y  = signed'({1'b0, current_y_drawing});

        // 2. Define Physics Anchor Point
        x1 = X_CENTER;
        y1 = Y_CENTER;
        
        // 3. Define Target Point with Center Offset
        // Targeting the center (32,32) of the 64x64 hook for best rotation support
        x2 = signed'({1'b0, object_topLeftX}) + 32;
        y2 = signed'({1'b0, object_topLeftY}) + 32; 

        // 4. Calculate Absolute Distances (for width calculation)
        abs_dx = (x2 > x1) ? (x2 - x1) : (x1 - x2);
        abs_dy = (y2 > y1) ? (y2 - y1) : (y1 - y2);

        // 5. Line Equation Factors (Based on physics anchor y1)
        // a = (y - y1)(x2 - x1)
        a = (y - y1) * (x2 - x1);
        
        // b = (y2 - y1)(x - x1)
        b = (y2 - y1) * (x - x1);

        // 6. Dynamic Epsilon Calculation
        if (abs_dx > abs_dy)
            epsilon = epsilon_star * abs_dx;
        else
            epsilon = epsilon_star * abs_dy;

        // 7. Bounding Box & Visual Masking Logic
        
        // Define where the rope visually appears (16 pixels below the physics anchor)
        // This creates the "pulley" effect without breaking the line angle
        visual_start_y = y1 + 16; 

        // X Bounds
        if (x1 < x2) 
            in_x_bounds = (x >= x1) && (x <= x2);
        else         
            in_x_bounds = (x >= x2) && (x <= x1);

        // Y Bounds (Updated with visual masking)
        // Check if pixel is below the visual start point AND above the hook
        if (y1 < y2) 
            in_y_bounds = (y >= visual_start_y) && (y <= y2);
        else         
            in_y_bounds = (y >= y2) && (y <= visual_start_y);

        // 8. Final Draw Condition
        if ( ((b - epsilon) < a) && (a < (b + epsilon)) && in_x_bounds && in_y_bounds ) begin
            drawingRequest = 1'b1;
            RGBout = 8'h49; //  dark grey rope
        end else begin
            drawingRequest = 1'b0;
            RGBout = 8'h00;
        end
    end

endmodule