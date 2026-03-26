// holds the bitmaps of the main menu thaat includes a title screen and instruction menu

module MenuBitMap (
    input logic clk,
    input logic resetN,
    input logic [10:0] pixelX,
    input logic [10:0] pixelY,
    
    output logic DrawingRequest,
    output logic [7:0] RGBout
);

//params

localparam int TITLE_WIDTH = 300; 
localparam int TITLE_HEIGHT = 100;
localparam int TITLE_START_X = 170; 
localparam int TITLE_START_Y = 90;

localparam int INST_WIDTH = 180; 
localparam int INST_HEIGHT = 200;
localparam int INST_START_X = 430; 
localparam int INST_START_Y = 260; 

localparam logic [7:0] TRANSPARENT_COLOR = 8'hFF;

//memory logic
logic [7:0] title_mem [0:TITLE_WIDTH*TITLE_HEIGHT-1];
logic [7:0] inst_mem  [0:INST_WIDTH*INST_HEIGHT-1];

// load the filrs from the folder
initial begin
    $readmemh("title_data.hex", title_mem);
    $readmemh("inst_data.hex", inst_mem);
end

//logics for pos and bound calcs
logic inside_title, inside_inst;
logic [10:0] title_offsetX, title_offsetY;
logic [10:0] inst_offsetX, inst_offsetY;

//bound calcs
assign inside_title = (pixelX >= TITLE_START_X) && (pixelX < TITLE_START_X + TITLE_WIDTH) &&
                      (pixelY >= TITLE_START_Y) && (pixelY < TITLE_START_Y + TITLE_HEIGHT);

assign inside_inst  = (pixelX >= INST_START_X) && (pixelX < INST_START_X + INST_WIDTH) &&
                      (pixelY >= INST_START_Y) && (pixelY < INST_START_Y + INST_HEIGHT);

//offset calcs
assign title_offsetX = pixelX - TITLE_START_X;
assign title_offsetY = pixelY - TITLE_START_Y;

assign inst_offsetX = pixelX - INST_START_X;
assign inst_offsetY = pixelY - INST_START_Y;

//calcs for addresses
logic [15:0] title_addr;
logic [15:0] inst_addr;

assign title_addr = (title_offsetY * TITLE_WIDTH) + title_offsetX;
assign inst_addr  = (inst_offsetY * INST_WIDTH) + inst_offsetX;


// values to save data from memory
logic [7:0] title_data_out;
logic [7:0] inst_data_out;

// values to save data from memory in one clk delay so we can check the values from memory without creating registers
logic inside_title_d, inside_inst_d;

always_ff @(posedge clk) begin
	 // read memory - the resault is ready on the next clk cycle
	 // the use of x_addr in always_ff make a ram memory instead of registers
    if (inside_title)
        title_data_out <= title_mem[title_addr];
        
    if (inside_inst)
        inst_data_out <= inst_mem[inst_addr];
    
	 //saving the state if were insiderec for next clk cycle
    if (!resetN) begin
        inside_title_d <= 1'b0;
        inside_inst_d <= 1'b0;
    end else begin
        inside_title_d <= inside_title;
        inside_inst_d <= inside_inst;
    end
end

//output logic - from the values that were read from memory
always_comb begin
	 //defualt
    RGBout = TRANSPARENT_COLOR;
    DrawingRequest = 1'b0;
	 
	 //check data_out the value from memory and delayed data(inside rec)
    if (inside_title_d) begin
        RGBout = title_data_out;
        if (title_data_out != TRANSPARENT_COLOR)
            DrawingRequest = 1'b1;
    end
    else if (inside_inst_d) begin
        RGBout = inst_data_out;
        if (inst_data_out != TRANSPARENT_COLOR)
            DrawingRequest = 1'b1;
    end
end

endmodule

