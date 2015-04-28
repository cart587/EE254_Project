`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, btnC,
	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS,
	MISO, SS, MOSI, SCLK);
	
	input ClkPort, btnC;
	input MISO;
	output MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output SS, MOSI, SCLK;
	reg vga_r, vga_g, vga_b;
	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk, button_clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, btnC);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign button_clk = DIV_CLK[18];
	assign clk = DIV_CLK[1];
	assign {MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS} = {5'b11111};
	
	wire inDisplayArea;
	wire [18:0] CounterX;
	wire [18:0] CounterY;
	
	wire SS;
	wire MOSI;
	wire SCLK;
	
	wire [7:0] sndData = 8'b10000000;
	wire sendRec;
	wire [39:0] jstkData;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	//-----------------------------------------------
	//  	  			PmodJSTK Interface
	//-----------------------------------------------
	PmodJSTK PmodJSTK_Int(
			.CLK(clk),
			.RST(reset),
			.sndRec(sndRec),
			.DIN(sndData),
			.MISO(MISO),
			.SS(SS),
			.SCLK(SCLK),
			.MOSI(MOSI),
			.DOUT(jstkData)
	);
	
	//-----------------------------------------------
	//  			 Send Receive Generator
	//-----------------------------------------------
	ClkDiv_5Hz genSndRec(
			.CLK(clk),
			.RST(reset),
			.CLKOUT(sndRec)
	);
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	//Player Variables
	reg [9:0] positionY;
	reg [9:0] positionX;
	reg [9:0] velocityX;
	reg [9:0] velocityY;
	reg [1:0] direction;
	
	wire [9:0] joystickX = {jstkData[25:24], jstkData[39:32]};
	wire [9:0] joystickY = {jstkData[9:8], jstkData[23:16]};
	wire joystickBombButton = jstkData[1];
	wire joystickStartButton = jstkData[2];
	
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
					bombDelay <= 96; //4 seconds
					explodeTimer <= 24;
					explode <= 0;
				end
			else if (joystickY > 700 && ~(joystickX < 300) && ~(joystickX > 700))
				begin
					velocityY <= -3;
					direction <= 0;
				end
			else if (joystickY < 300 && ~(joystickX < 300) && ~(joystickX > 700))
				begin
					velocityY <= 3;
					direction <= 1;
				end
			else if (joystickX < 300 && ~(joystickY < 300) && ~(joystickY > 700))
				begin
					velocityX <= -3;
					direction <= 2;
				end
			else if (joystickX > 700 && ~(joystickY < 300) && ~(joystickY > 700))
				begin
					velocityX <= 3;
					direction <= 3;
				end
			else
				begin
					velocityX <= 0;
					velocityY <= 0;
				end
			if(joystickBombButton && bombCount == 0 && bombTimer == 0 && explode == 0)
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
	
endmodule
