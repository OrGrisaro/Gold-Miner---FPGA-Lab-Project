//this module is responsible for the game's HUD print : timer and score
module HUD_Display(
	input	logic	clk,
	input	logic	resetN,
	input logic	[10:0] pixelX,// pos x on screen
	input logic	[10:0] pixelY,// pos  y on screen
	
	// inputs from timer and score modules (future)
	input	logic [10:0] score, // max 999 but we makeit 11 bits for logics in game controller
	input logic [6:0] timer, // max 99 so 128 bits
	
	//inputs from game controller
	input logic [1:0] level,
	input logic [1:0] msg_sel,//00=menu , 01=run, 10=win, 11=lose
	
	output logic HUD_DrawingRequest, //output that the pixel should be dispalyed 
	output logic [7:0] hud_rgb 
);
	
	// dimensions
	parameter int DIGIT_W= 16;
	parameter int DIGIT_H = 32;
	parameter int LEVEL_TXT_W = 80;
	parameter int MSG_W = 144;
	
	//pos of score -> top left
	parameter int SCORE_X = 10;
	parameter int SCORE_Y = 20;
	
	//pos of timer -> top right
	parameter int TIMER_X = 580;
	parameter int TIMER_Y = 20;
	
	//pos of level -> top center right
	parameter int LEVEL_X= 400;
	parameter int LEVEL_Y = 20;
	
	//pos of Messages -> center o screen
	// (640 - 144) / 2 = 248
	// (480 - 32) / 2 = 224
	parameter int MSG_X = 248;
	parameter int MSG_Y = 224;
	
	//init digits of mumbers
	
	
	logic [3:0] s_hun, s_ten, s_uni; // score
	logic [3:0] t_hun, t_ten, t_uni; // timer
	
	bin_to_bcd_11bit score_converter (
		.binary(score),
		.hundreds(s_hun),
		.tens(s_ten),
		.ones(s_uni)
	);
	
	bin_to_bcd_11bit timer_converter (
		.binary({4'b0000, timer}), 
		.hundreds(t_hun),
		.tens(t_ten),
		.ones(t_uni)
	);
	
	//init level digit
	logic [3:0] lvl_digit; // the digit after the level msg
	assign lvl_digit = {2'b00, level};
	
	
	
	//logic of texts
	logic show_msg;
	//if the pixel is in the bounds of a txt
	logic in_s_hun, in_s_ten, in_s_uni;
	logic in_t_ten, in_t_uni;
	logic in_lvl_txt, in_lvl_digit;
	logic in_msg;
	//draw reqs for modules
	logic draw_s_hun, draw_s_ten, draw_s_uni;
	logic draw_t_ten, draw_t_uni;
	logic draw_lvl_txt, draw_level_digit;
	logic draw_msg;
	//rgbs for modules
	logic [7:0] rgb_s_hun, rgb_s_ten, rgb_s_uni;
	logic [7:0] rgb_t_ten, rgb_t_uni;
	logic [7:0] rgb_lvl_txt, rgb_lvl_digit;
	logic [7:0] rgb_msg;
	
	
	//digits bounds calcs for score
	assign in_s_hun = (pixelX >= SCORE_X) && (pixelX < SCORE_X + DIGIT_W) && 
                      (pixelY >= SCORE_Y) && (pixelY < SCORE_Y + DIGIT_H);
	assign in_s_ten = (pixelX >= SCORE_X + DIGIT_W) && (pixelX < SCORE_X + 2*DIGIT_W) && 
                      (pixelY >= SCORE_Y) && (pixelY < SCORE_Y + DIGIT_H);
	assign in_s_uni = (pixelX >= SCORE_X + 2*DIGIT_W) && (pixelX < SCORE_X + 3*DIGIT_W) && 
                      (pixelY >= SCORE_Y) && (pixelY < SCORE_Y + DIGIT_H);
	
	//digits bounds calcs for timer
	assign in_t_ten = (pixelX >= TIMER_X) && (pixelX < TIMER_X + DIGIT_W) && 
                      (pixelY >= TIMER_Y) && (pixelY < TIMER_Y + DIGIT_H);
   assign in_t_uni = (pixelX >= TIMER_X + DIGIT_W) && (pixelX < TIMER_X + 2*DIGIT_W) && 
                      (pixelY >= TIMER_Y) && (pixelY < TIMER_Y + DIGIT_H);
	
	//level txt bounds
	assign in_lvl_txt = (pixelX >= LEVEL_X) && (pixelX < LEVEL_X + LEVEL_TXT_W) &&
								(pixelY >= LEVEL_Y) && (pixelY < LEVEL_Y + DIGIT_H);
	assign in_lvl_digit = (pixelX >= LEVEL_X + LEVEL_TXT_W + 10) && (pixelX < LEVEL_X + LEVEL_TXT_W + 10 + DIGIT_W) &&
									(pixelY >= LEVEL_Y) && (pixelY < LEVEL_Y + DIGIT_H);
	
	//level msg bounds + condition
	assign show_msg = (msg_sel[1] == 1'b1); // 10 (win) or 11 (lose)
	assign in_msg = show_msg && 
							(pixelX >= MSG_X) && (pixelX < MSG_X + MSG_W) &&
							(pixelY >= MSG_Y) && (pixelY < MSG_Y + DIGIT_H);
	
	
	
	//assign offsets for modules
	logic [10:0] offsetY_common;
	logic [10:0] offsetY_msg;
	assign offsetY_common = pixelY - SCORE_Y; //offset for top row elems
	assign offsetY_msg = pixelY - MSG_Y; // offset for center msg
	
	
	logic [10:0] offsetX_s_hun, offsetX_s_ten, offsetX_s_uni;
	logic [10:0] offsetX_t_ten, offsetX_t_uni;
	logic [10:0] offsetX_lvl_txt, offsetX_lvl_digit;
	logic [10:0] offsetX_msg;
	//offsets of digits for score
	assign offsetX_s_hun = pixelX - SCORE_X;
	assign offsetX_s_ten = pixelX - (SCORE_X + DIGIT_W);
	assign offsetX_s_uni = pixelX - (SCORE_X + 2*DIGIT_W);
	//offsets of digits for timer
	assign offsetX_t_ten = pixelX - TIMER_X;
	assign offsetX_t_uni = pixelX - (TIMER_X + DIGIT_W);
	//offsets of level texts
	assign offsetX_lvl_txt = pixelX - LEVEL_X;
	assign offsetX_lvl_digit = pixelX - (LEVEL_X +LEVEL_TXT_W + 10); 
	//offsets of msg
	assign offsetX_msg = pixelX - MSG_X;
	
	
	
	// create modules of digits
	
	
	// score
	TextBitMap score_hunds_inst (
        .clk(clk), .resetN(resetN), 
        .offsetX(offsetX_s_hun), .offsetY(offsetY_common),
        .InsideRectangle(in_s_hun),
        .digit(s_hun), .type_select(2'b00),
        .drawingRequest(draw_s_hun), .RGBout(rgb_s_hun)
    );
	 
	 TextBitMap score_tens_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_s_ten), .offsetY(offsetY_common),
        .InsideRectangle(in_s_ten),
        .digit(s_ten), .type_select(2'b00),
        .drawingRequest(draw_s_ten), .RGBout(rgb_s_ten)
    );
	 
	 TextBitMap score_uni_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_s_uni), .offsetY(offsetY_common),
        .InsideRectangle(in_s_uni),
        .digit(s_uni), .type_select(2'b00),
        .drawingRequest(draw_s_uni), .RGBout(rgb_s_uni)
    );
	 
	 
	 //timer
	 TextBitMap timer_tens_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_t_ten), .offsetY(offsetY_common),
        .InsideRectangle(in_t_ten),
        .digit(t_ten), .type_select(2'b00),
        .drawingRequest(draw_t_ten), .RGBout(rgb_t_ten)
    );
	
	TextBitMap timer_uni_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_t_uni), .offsetY(offsetY_common),
        .InsideRectangle(in_t_uni),
        .digit(t_uni), .type_select(2'b00),
        .drawingRequest(draw_t_uni), .RGBout(rgb_t_uni)
    );
	 
	 
	 //level
	 
	 TextBitMap level_txt_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_lvl_txt), .offsetY(offsetY_common),
        .InsideRectangle(in_lvl_txt),
        .digit(4'd0), .type_select(2'b01),
        .drawingRequest(draw_lvl_txt), .RGBout(rgb_lvl_txt)
    );
	 
	 TextBitMap level_digit_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_lvl_digit), .offsetY(offsetY_common),
        .InsideRectangle(in_lvl_digit),
        .digit(lvl_digit), .type_select(2'b00),
        .drawingRequest(draw_level_digit), .RGBout(rgb_lvl_digit)
    );
	 
	 
	 //msg win/lose
	 
	 TextBitMap msg_inst (
        .clk(clk), .resetN(resetN),
        .offsetX(offsetX_msg), .offsetY(offsetY_msg),
        .InsideRectangle(in_msg),
        .digit(4'd0), .type_select(msg_sel),
        .drawingRequest(draw_msg), .RGBout(rgb_msg)
    );
	 
	 
	 
	 // choses which digit to draw 
	 always_comb begin
        HUD_DrawingRequest = 1'b0;
        hud_rgb = 8'h00; 
		  //priority Msg -> level -> score -> timer
		  if (draw_msg) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_msg};
		  else if (draw_lvl_txt) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_lvl_txt};
		  else if (draw_level_digit) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_lvl_digit};
        else if (draw_s_hun) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_s_hun};
        else if (draw_s_ten) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_s_ten};
        else if (draw_s_uni) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_s_uni};
        else if (draw_t_ten) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_t_ten};
        else if (draw_t_uni) {HUD_DrawingRequest, hud_rgb} = {1'b1, rgb_t_uni};
    end
	

endmodule      