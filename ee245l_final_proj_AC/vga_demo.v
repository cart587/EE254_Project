`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnC, btnL, btnR, btnU, btnD,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, btnC, btnL, btnR, btnU, btnD, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign	button_clk = DIV_CLK[18];
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [18:0] CounterX;
	wire [18:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	//Player Variables
	reg [9:0] positionY;
	reg [9:0] positionX;
	reg [9:0] velocityX;
	reg [9:0] velocityY;
	reg [1:0] direction;
	
	reg [18:0] bombY;
	reg [18:0] bombX;
	reg [18:0] bombRad;
	reg [1:0] bombCount;
	reg [7:0] bombTimer;
	reg [7:0] bombDelay;
	reg [4:0] explodeTimer;
	reg explode;
	
	wire maze_block_0 = (positionX > 55 && positionX < 165) && (positionY > 38 && positionY < 130);
	wire maze_block_1 = (positionX > 195 && positionX < 305) && (positionY > 38 && positionY < 130);
	wire maze_block_2 = (positionX > 335 && positionX < 445) && (positionY > 38 && positionY < 130);
	wire maze_block_3 = (positionX > 475 && positionX < 585) && (positionY > 38 && positionY < 130);
	wire maze_block_4 = (positionX > 55 && positionX < 165) && (positionY > 142 && positionY < 234);
	wire maze_block_5 = (positionX > 195 && positionX < 305) && (positionY > 142 && positionY < 234);
	wire maze_block_6 = (positionX > 335 && positionX < 445) && (positionY > 142 && positionY < 234);
	wire maze_block_7 = (positionX > 475 && positionX < 585) && (positionY > 142 && positionY < 234);
	wire maze_block_8 = (positionX > 55 && positionX < 165) && (positionY > 246 && positionY < 338);
	wire maze_block_9 = (positionX > 195 && positionX < 305) && (positionY > 246 && positionY < 338);
	wire maze_block_10 = (positionX > 335 && positionX < 445) && (positionY > 246 && positionY < 338);
	wire maze_block_11 = (positionX > 475 && positionX < 585) && (positionY > 246 && positionY < 338);
	wire maze_block_12 = (positionX > 55 && positionX < 165) && (positionY > 350 && positionY < 442);
	wire maze_block_13 = (positionX > 195 && positionX < 305) && (positionY > 350 && positionY < 442);
	wire maze_block_14 = (positionX > 335 && positionX < 445) && (positionY > 350 && positionY < 442);
	wire maze_block_15 = (positionX > 475 && positionX < 585) && (positionY > 350 && positionY < 442);
	
	always @ (posedge DIV_CLK[21])
		begin
			if (reset)
				begin
					velocityX <= 0;
					velocityY <= 0;
					direction <= 2'bXX;
					bombY <= 240;
					bombX <= 100;
					bombRad <= 15;
					bombCount <= 0;
					bombTimer <= 0;
					bombDelay <= 72; //3 seconds
					explodeTimer <= 24;
					explode <= 0;
				end
			else if (btnU && ~btnD && ~btnL && ~btnR)
				begin
					velocityY <= -3;
					direction <= 0;
				end
			else if (btnD && ~btnU && ~btnL && ~btnR)
				begin
					velocityY <= 3;
					direction <= 1;
				end
			else if (btnL && ~btnD && ~btnU && ~btnR)
				begin
					velocityX <= -3;
					direction <= 2;
				end
			else if (btnR && ~btnU && ~btnL && ~btnD)
				begin
					velocityX <= 3;
					direction <= 3;
				end
			else
				begin
					velocityX <= 0;
					velocityY <= 0;
				end
			if(btnC && bombCount == 0 && bombTimer == 0 && explode == 0)
				begin
					bombCount <= bombCount + 1;
					bombTimer <= bombDelay;
					bombY <= positionY;
					bombX <= positionX;
				end
				if(!(bombTimer == 0))
					bombTimer<= bombTimer - 1;
				else if((bombTimer == 0) && !(bombCount == 0))
				begin
					bombCount<= bombCount - 1;
					explode <= 1;
				end
				
				if(explode)
					explodeTimer <=  explodeTimer - 1;
					
				if(explodeTimer == 0)
				begin
					explode <= 0;
					explodeTimer <= 24;
				end
		end
		
	always @ (posedge DIV_CLK[21])	
		begin
			if(reset)
				begin
					positionX <= 100;
					positionY <= 240;
				end
			else
				begin
					positionX <= positionX + velocityX;
					positionY <= positionY + velocityY;
					if (positionY < 26)
						positionY <= 27;
					else if (positionY > 454)
						positionY <= 453;					
					else if (positionX < 25)
						positionX <= 26;
					else if (positionX > 615)
						positionX <= 614;
					else if (direction == 0)
						begin
							if (maze_block_0 || maze_block_1 || maze_block_2 || maze_block_3)
								positionY <= 131;
							else if (maze_block_4 || maze_block_5 || maze_block_6 || maze_block_7)
								positionY <= 235;
							else if (maze_block_8 || maze_block_9 || maze_block_10 || maze_block_11)
								positionY <= 339;
							else if (maze_block_12 || maze_block_13 || maze_block_14 || maze_block_15)
								positionY <= 443;
						end
					else if (direction == 1)
						begin
							if (maze_block_0 || maze_block_1 || maze_block_2 || maze_block_3)
								positionY <= 37;
							else if (maze_block_4 || maze_block_5 || maze_block_6 || maze_block_7)
								positionY <= 141;
							else if (maze_block_8 || maze_block_9 || maze_block_10 || maze_block_11)
								positionY <= 245;
							else if (maze_block_12 || maze_block_13 || maze_block_14 || maze_block_15)
								positionY <= 349;
						end
					else if (direction == 2)
						begin
							if (maze_block_0 || maze_block_4 || maze_block_8 || maze_block_12)
								positionX <= 166;
							else if (maze_block_1 || maze_block_5 || maze_block_9 || maze_block_13)
								positionX <= 306;
							else if (maze_block_2 || maze_block_6 || maze_block_10 || maze_block_14)
								positionX <= 446;
							else if (maze_block_3 || maze_block_7 || maze_block_11 || maze_block_15)
								positionX <= 586;
						end
					else if (direction == 3)
						begin
							if (maze_block_0 || maze_block_4 || maze_block_8 || maze_block_12)
								positionX <= 54;
							else if (maze_block_1 || maze_block_5 || maze_block_9 || maze_block_13)
								positionX <= 194;
							else if (maze_block_2 || maze_block_6 || maze_block_10 || maze_block_14)
								positionX <= 334;
							else if (maze_block_3 || maze_block_7 || maze_block_11 || maze_block_15)
								positionX <= 474;
						end			
				end
		end
	
	
	
	wire BOMB_DROP = (((CounterY-bombY)*(CounterY-bombY)) + ((CounterX-bombX)*(CounterX-bombX))) < (bombRad*bombRad) && (bombCount == 1) && bombTimer[3] == 0;
	//wire EXPLOSION = (((CounterY >= bombY- 20) && (CounterY <= bombY + 20)) || ((CounterX >= bombX - 25) && (CounterX <= bombX + 25))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION0 = (bombY >= 6 && bombY <= 58) && (((CounterY >= 10) && (CounterY <= 54)) && ((CounterX >= 9) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION1 = (bombY >= 110 && bombY <= 162) && (((CounterY >= 114) && (CounterY <= 158)) && ((CounterX >= 9) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION2 = (bombY >= 214 && bombY <= 266) && (((CounterY >= 218) && (CounterY <= 262)) && ((CounterX >= 9) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION3 = (bombY >= 318 && bombY <= 370) && (((CounterY >= 322) && (CounterY <= 366)) && ((CounterX >= 9) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION4 = (bombY >= 422 && bombY <= 474) && (((CounterY >= 426) && (CounterY <= 470)) && ((CounterX >= 9) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION5 = (bombX >= 5 && bombX <= 75) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 9) && (CounterX <= 69))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION6 = (bombX >= 145 && bombX <= 215) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 149) && (CounterX <= 211))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION7 = (bombX >= 285 && bombX <= 355) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 289) && (CounterX <= 351))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION8 = (bombX >= 425 && bombX <= 495) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 429) && (CounterX <= 491))) && !(explodeTimer == 0) && explode;
	wire EXPLOSION9 = (bombX >= 565 && bombX <= 635) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 569) && (CounterX <= 631))) && !(explodeTimer == 0) && explode;
	
	wire MAZE_WALL_X = (CounterX >= 0 && CounterX <= 5) || (CounterX >= 635 && CounterX <= 640);
	wire MAZE_WALL_Y = (CounterY >= 0 && CounterY <= 6) || (CounterY >= 474 && CounterY <= 480);
	wire MAZE_WALL = MAZE_WALL_X || MAZE_WALL_Y;
	
	wire MAZE_BLOCK_X_0 = CounterX >= 75 && CounterX <= 145;
	wire MAZE_BLOCK_X_1 = CounterX >= 215 && CounterX <= 285;
	wire MAZE_BLOCK_X_2 = CounterX >= 355 && CounterX <= 425;
	wire MAZE_BLOCK_X_3 = CounterX >= 495 && CounterX <= 565;
	wire MAZE_BLOCK_Y_0 = CounterY >= 58 && CounterY <= 110;
	wire MAZE_BLOCK_Y_1 = CounterY >= 162 && CounterY <= 214;
	wire MAZE_BLOCK_Y_2 = CounterY >= 266 && CounterY <= 318;
	wire MAZE_BLOCK_Y_3 = CounterY >= 370 && CounterY <= 422;
	
	wire MAZE_BLOCK_0 = MAZE_BLOCK_X_0 && MAZE_BLOCK_Y_0;
	wire MAZE_BLOCK_1 = MAZE_BLOCK_X_0 && MAZE_BLOCK_Y_1;
	wire MAZE_BLOCK_2 = MAZE_BLOCK_X_0 && MAZE_BLOCK_Y_2;
	wire MAZE_BLOCK_3 = MAZE_BLOCK_X_0 && MAZE_BLOCK_Y_3;
	wire MAZE_BLOCK_4 = MAZE_BLOCK_X_1 && MAZE_BLOCK_Y_0;
	wire MAZE_BLOCK_5 = MAZE_BLOCK_X_1 && MAZE_BLOCK_Y_1;
	wire MAZE_BLOCK_6 = MAZE_BLOCK_X_1 && MAZE_BLOCK_Y_2;
	wire MAZE_BLOCK_7 = MAZE_BLOCK_X_1 && MAZE_BLOCK_Y_3;
	wire MAZE_BLOCK_8 = MAZE_BLOCK_X_2 && MAZE_BLOCK_Y_0;
	wire MAZE_BLOCK_9 = MAZE_BLOCK_X_2 && MAZE_BLOCK_Y_1;
	wire MAZE_BLOCK_10 = MAZE_BLOCK_X_2 && MAZE_BLOCK_Y_2;
	wire MAZE_BLOCK_11 = MAZE_BLOCK_X_2 && MAZE_BLOCK_Y_3;
	wire MAZE_BLOCK_12 = MAZE_BLOCK_X_3 && MAZE_BLOCK_Y_0;
	wire MAZE_BLOCK_13 = MAZE_BLOCK_X_3 && MAZE_BLOCK_Y_1;
	wire MAZE_BLOCK_14 = MAZE_BLOCK_X_3 && MAZE_BLOCK_Y_2;
	wire MAZE_BLOCK_15 = MAZE_BLOCK_X_3 && MAZE_BLOCK_Y_3;
	
	wire MAZE_BLOCK = MAZE_BLOCK_0 || MAZE_BLOCK_1 || MAZE_BLOCK_2 || MAZE_BLOCK_3 || MAZE_BLOCK_4 || MAZE_BLOCK_5 || MAZE_BLOCK_6 || MAZE_BLOCK_7 || 
		MAZE_BLOCK_8 || MAZE_BLOCK_9 || MAZE_BLOCK_10 || MAZE_BLOCK_11 || MAZE_BLOCK_12 || MAZE_BLOCK_13 || MAZE_BLOCK_14 || MAZE_BLOCK_15;
	
	wire R = (CounterY >= (positionY-20) && CounterY <= (positionY+20) && CounterX >= (positionX-20) && CounterX <= (positionX+20));
	wire G = MAZE_WALL || MAZE_BLOCK;
	wire B = BOMB_DROP || EXPLOSION0 || EXPLOSION1 || EXPLOSION2 || EXPLOSION3 || EXPLOSION4 || EXPLOSION5 || EXPLOSION6 ||
		EXPLOSION7 || EXPLOSION8 || EXPLOSION9;
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == `QI);
	assign LD5 = (state == `QGAME_1);	
	assign LD6 = (state == `QGAME_2);
	assign LD7 = (state == `QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = 4'b1111;
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = positionY[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule
