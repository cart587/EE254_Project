`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// EE-254 Final Project (PyroMaster)
// Author:  Anthony Asuquo & Chris Carter
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, btnU, btnD, btnL, btnR, btnC,
	MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS,
	vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b,
	p1_SS, p1_MISO, p1_MOSI, p1_SCLK,
	p2_SS, p2_MISO, p2_MOSI, p2_SCLK,
	LCD_data, LCD_e, LCD_rs, LCD_rw, LCD_bl);
	
	input ClkPort, btnU, btnD, btnL, btnR, btnC;
	input p1_MISO, p2_MISO;
	output MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output p1_SS, p1_MOSI, p1_SCLK;
	output p2_SS, p2_MOSI, p2_SCLK;
	output [7:0] LCD_data;
	output LCD_e, LCD_rs, LCD_rw, LCD_bl;
	reg vga_r, vga_g, vga_b;

	
	//////////////////////////////////////////////////////////////////////////////////////////
	
	/*  LOCAL SIGNALS */
	wire Reset, ClkPort, board_clk, sys_clk;
	wire GameStart, Accept, Decline;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (Reset, btnC);
	BUF BUF3 (GameStart, btnU);
	BUF BUF4 (Accept, btnL);
	BUF BUF5 (Decline, btnR);
	
	reg [27:0]	DIV_CLK;
	always @ (posedge board_clk, posedge Reset)  
	begin : CLOCK_DIVIDER
      if (Reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	

	assign sys_clk = DIV_CLK[1];
	assign {MemOE, MemWR, RamCS, FlashCS, QuadSpiFlashCS} = {5'b11111};
	
	wire inDisplayArea;
	wire [18:0] CounterX, CounterY;
	
	wire p1_SS, p1_MOSI, p1_SCLK;
	wire p2_SS, p2_MOSI, p2_SCLK;
	
	wire [7:0] p1_sndData = 8'b10000000;
	wire p1_sendRec;
	wire [39:0] p1_jstkData;
	
	wire [7:0] p2_sndData = 8'b10000000;
	wire p2_sendRec;
	wire [39:0] p2_jstkData;
	
	//intermediate data wires carrying the 32 characters to the LCD module
	reg [7:0] data1, data2, data3, data4, data5, data6, data7, data8,
		data9, data10, data11, data12, data13, data14, data15, data16,
		data17, data18, data19, data20, data21, data22, data23, data24,
		data25, data26, data27, data28, data29, data30, data31, data32;
	
	reg [4:0] state;
	
	localparam
	MAIN_MENU	= 4'b0000,
	WAIT			= 4'b0001,
	WAIT_P1		= 4'b0010,
	WAIT_P2		= 4'b0011,
	READY			= 4'b0100,
	GAME			= 4'b0101,
	RND_WON_P1	= 4'b0110,
	RND_WON_P2	= 4'b0111,
	RND_DRAW		= 4'b1011,
	GAME_WON_P1	= 4'b1000,
	GAME_WON_P2	= 4'b1001,
	PLAY_AGAIN	= 4'b1010;
	
	reg [7:0] waitTimer1;
	reg [7:0] waitTimer2;
	reg [3:0] countDigit;
		
	// Player 1 Variables ----------------------------------------------------------------------------------------------
	reg [9:0] positionY;
	reg [9:0] positionX;
	reg [9:0] velocityX;
	reg [9:0] velocityY;
	reg [1:0] direction;
	
	wire [9:0] joystickX = {p1_jstkData[25:24], p1_jstkData[39:32]};
	wire [9:0] joystickY = {p1_jstkData[9:8], p1_jstkData[23:16]};
	wire joystickBombButton = p1_jstkData[1];
	wire joystickStartButton = p1_jstkData[2];
	
	reg [18:0] bombY;
	reg [18:0] bombX;
	reg [18:0] bombRad;
	reg [1:0] bombCount;
	reg [7:0] bombTimer;
	reg [7:0] bombDelay;
	reg [4:0] explodeTimer;
	reg explode;
	reg p1_dead;
	
	reg [3:0] p1_score;
	
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
	
	wire p1_killed0 = (bombY >= 6 && bombY <= 58) && (positionY >= 6 && positionY <= 58) && !(explodeTimer == 0) && explode;
	wire p1_killed1 = (bombY >= 110 && bombY <= 162) && (positionY >= 110 && positionY <= 162) && !(explodeTimer == 0) && explode;
	wire p1_killed2 = (bombY >= 214 && bombY <= 266) && (positionY >= 214 && positionY <= 266) && !(explodeTimer == 0) && explode;
	wire p1_killed3 = (bombY >= 318 && bombY <= 370) && (positionY >= 318 && positionY <= 370) && !(explodeTimer == 0) && explode;
	wire p1_killed4 = (bombY >= 422 && bombY <= 474) && (positionY >= 422 && positionY <= 474) && !(explodeTimer == 0) && explode;
	wire p1_killed5 = (bombX >= 5 && bombX <= 75) && (positionX >= 5 && positionX <= 75) && !(explodeTimer == 0) && explode;
	wire p1_killed6 = (bombX >= 145 && bombX <= 215) && (positionX >= 145 && positionX <= 215) && !(explodeTimer == 0) && explode;
	wire p1_killed7 = (bombX >= 285 && bombX <= 355) && (positionX >= 285 && positionX <= 355) && !(explodeTimer == 0) && explode;
	wire p1_killed8 = (bombX >= 425 && bombX <= 495) && (positionX >= 425 && positionX <= 495) && !(explodeTimer == 0) && explode;
	wire p1_killed9 = (bombX >= 565 && bombX <= 635) && (positionX >= 565 && positionX <= 635) && !(explodeTimer == 0) && explode;
	
	wire p1_killed0_by_p2 = (p2_bombY >= 6 && p2_bombY <= 58) && (positionY >= 6 && positionY <= 58) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed1_by_p2 = (p2_bombY >= 110 && p2_bombY <= 162) && (positionY >= 110 && positionY <= 162) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed2_by_p2 = (p2_bombY >= 214 && p2_bombY <= 266) && (positionY >= 214 && positionY <= 266) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed3_by_p2 = (p2_bombY >= 318 && p2_bombY <= 370) && (positionY >= 318 && positionY <= 370) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed4_by_p2 = (p2_bombY >= 422 && p2_bombY <= 474) && (positionY >= 422 && positionY <= 474) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed5_by_p2 = (p2_bombX >= 5 && p2_bombX <= 75) && (positionX >= 5 && positionX <= 75) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed6_by_p2 = (p2_bombX >= 145 && p2_bombX <= 215) && (positionX >= 145 && positionX <= 215) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed7_by_p2 = (p2_bombX >= 285 && p2_bombX <= 355) && (positionX >= 285 && positionX <= 355) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed8_by_p2 = (p2_bombX >= 425 && p2_bombX <= 495) && (positionX >= 425 && positionX <= 495) && !(p2_explodeTimer == 0) && p2_explode;
	wire p1_killed9_by_p2 = (p2_bombX >= 565 && p2_bombX <= 635) && (positionX >= 565 && positionX <= 635) && !(p2_explodeTimer == 0) && p2_explode;
	
	wire p1_killed = p1_killed0 || p1_killed1 || p1_killed2 || p1_killed3 || p1_killed4 || p1_killed5 || p1_killed6 || p1_killed7 || p1_killed8 || p1_killed9 ||
		p1_killed0_by_p2 || p1_killed1_by_p2 || p1_killed2_by_p2 || p1_killed3_by_p2 || p1_killed4_by_p2 || p1_killed5_by_p2 || p1_killed6_by_p2 ||p1_killed7_by_p2 ||
		p1_killed8_by_p2 || p1_killed9_by_p2;
	
	// Player 2 Variables ----------------------------------------------------------------------------------------------
	reg [9:0] p2_positionY;
	reg [9:0] p2_positionX;
	reg [9:0] p2_velocityX;
	reg [9:0] p2_velocityY;
	reg [1:0] p2_direction;
	
	wire [9:0] p2_joystickX = {p2_jstkData[25:24], p2_jstkData[39:32]};
	wire [9:0] p2_joystickY = {p2_jstkData[9:8], p2_jstkData[23:16]};
	wire p2_joystickBombButton = p2_jstkData[1];
	wire p2_joystickStartButton = p2_jstkData[2];
	
	reg [18:0] p2_bombY;
	reg [18:0] p2_bombX;
	reg [18:0] p2_bombRad;
	reg [1:0] p2_bombCount;
	reg [7:0] p2_bombTimer;
	reg [7:0] p2_bombDelay;
	reg [4:0] p2_explodeTimer;
	reg p2_explode;
	reg p2_dead;
	
	reg [3:0] p2_score;
	
	wire p2_maze_block_0 = (p2_positionX > 55 && p2_positionX < 165) && (p2_positionY > 38 && p2_positionY < 130);
	wire p2_maze_block_1 = (p2_positionX > 195 && p2_positionX < 305) && (p2_positionY > 38 && p2_positionY < 130);
	wire p2_maze_block_2 = (p2_positionX > 335 && p2_positionX < 445) && (p2_positionY > 38 && p2_positionY < 130);
	wire p2_maze_block_3 = (p2_positionX > 475 && p2_positionX < 585) && (p2_positionY > 38 && p2_positionY < 130);
	wire p2_maze_block_4 = (p2_positionX > 55 && p2_positionX < 165) && (p2_positionY > 142 && p2_positionY < 234);
	wire p2_maze_block_5 = (p2_positionX > 195 && p2_positionX < 305) && (p2_positionY > 142 && p2_positionY < 234);
	wire p2_maze_block_6 = (p2_positionX > 335 && p2_positionX < 445) && (p2_positionY > 142 && p2_positionY < 234);
	wire p2_maze_block_7 = (p2_positionX > 475 && p2_positionX < 585) && (p2_positionY > 142 && p2_positionY < 234);
	wire p2_maze_block_8 = (p2_positionX > 55 && p2_positionX < 165) && (p2_positionY > 246 && p2_positionY < 338);
	wire p2_maze_block_9 = (p2_positionX > 195 && p2_positionX < 305) && (p2_positionY > 246 && p2_positionY < 338);
	wire p2_maze_block_10 = (p2_positionX > 335 && p2_positionX < 445) && (p2_positionY > 246 && p2_positionY < 338);
	wire p2_maze_block_11 = (p2_positionX > 475 && p2_positionX < 585) && (p2_positionY > 246 && p2_positionY < 338);
	wire p2_maze_block_12 = (p2_positionX > 55 && p2_positionX < 165) && (p2_positionY > 350 && p2_positionY < 442);
	wire p2_maze_block_13 = (p2_positionX > 195 && p2_positionX < 305) && (p2_positionY > 350 && p2_positionY < 442);
	wire p2_maze_block_14 = (p2_positionX > 335 && p2_positionX < 445) && (p2_positionY > 350 && p2_positionY < 442);
	wire p2_maze_block_15 = (p2_positionX > 475 && p2_positionX < 585) && (p2_positionY > 350 && p2_positionY < 442);
	
	wire p2_killed0 = (p2_bombY >= 6 && p2_bombY <= 58) && (p2_positionY >= 6 && p2_positionY <= 58) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed1 = (p2_bombY >= 110 && p2_bombY <= 162) && (p2_positionY >= 110 && p2_positionY <= 162) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed2 = (p2_bombY >= 214 && p2_bombY <= 266) && (p2_positionY >= 214 && p2_positionY <= 266) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed3 = (p2_bombY >= 318 && p2_bombY <= 370) && (p2_positionY >= 318 && p2_positionY <= 370) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed4 = (p2_bombY >= 422 && p2_bombY <= 474) && (p2_positionY >= 422 && p2_positionY <= 474) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed5 = (p2_bombX >= 5 && p2_bombX <= 75) && (p2_positionX >= 5 && p2_positionX <= 75) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed6 = (p2_bombX >= 145 && p2_bombX <= 215) && (p2_positionX >= 145 && p2_positionX <= 215) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed7 = (p2_bombX >= 285 && p2_bombX <= 355) && (p2_positionX >= 285 && p2_positionX <= 355) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed8 = (p2_bombX >= 425 && p2_bombX <= 495) && (p2_positionX >= 425 && p2_positionX <= 495) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_killed9 = (p2_bombX >= 565 && p2_bombX <= 635) && (p2_positionX >= 565 && p2_positionX <= 635) && !(p2_explodeTimer == 0) && p2_explode;
	
	wire p2_killed0_by_p1 = (bombY >= 6 && bombY <= 58) && (p2_positionY >= 6 && p2_positionY <= 58) && !(explodeTimer == 0) && explode;
	wire p2_killed1_by_p1 = (bombY >= 110 && bombY <= 162) && (p2_positionY >= 110 && p2_positionY <= 162) && !(explodeTimer == 0) && explode;
	wire p2_killed2_by_p1 = (bombY >= 214 && bombY <= 266) && (p2_positionY >= 214 && p2_positionY <= 266) && !(explodeTimer == 0) && explode;
	wire p2_killed3_by_p1 = (bombY >= 318 && bombY <= 370) && (p2_positionY >= 318 && p2_positionY <= 370) && !(explodeTimer == 0) && explode;
	wire p2_killed4_by_p1 = (bombY >= 422 && bombY <= 474) && (p2_positionY >= 422 && p2_positionY <= 474) && !(explodeTimer == 0) && explode;
	wire p2_killed5_by_p1 = (bombX >= 5 && bombX <= 75) && (p2_positionX >= 5 && p2_positionX <= 75) && !(explodeTimer == 0) && explode;
	wire p2_killed6_by_p1 = (bombX >= 145 && bombX <= 215) && (p2_positionX >= 145 && p2_positionX <= 215) && !(explodeTimer == 0) && explode;
	wire p2_killed7_by_p1 = (bombX >= 285 && bombX <= 355) && (p2_positionX >= 285 && p2_positionX <= 355) && !(explodeTimer == 0) && explode;
	wire p2_killed8_by_p1 = (bombX >= 425 && bombX <= 495) && (p2_positionX >= 425 && p2_positionX <= 495) && !(explodeTimer == 0) && explode;
	wire p2_killed9_by_p1 = (bombX >= 565 && bombX <= 635) && (p2_positionX >= 565 && p2_positionX <= 635) && !(explodeTimer == 0) && explode;
	
	wire p2_killed = p2_killed0 || p2_killed1 || p2_killed2 || p2_killed3 || p2_killed4 || p2_killed5 || p2_killed6 || p2_killed7 || p2_killed8 || p2_killed9 ||
		p2_killed0_by_p1 || p2_killed1_by_p1 || p2_killed2_by_p1 || p2_killed3_by_p1 || p2_killed4_by_p1 || p2_killed5_by_p1 || p2_killed6_by_p1 ||p2_killed7_by_p1 ||
		p1_killed8_by_p2 || p2_killed9_by_p1;
		
	//////////////////////////////////////////////////////////////////////////////////////////
	
	
	/////////////////////////////////////////////////////////////////
	//////////////		State Machine starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	always @ (posedge DIV_CLK[21], posedge Reset)
	begin
		if (Reset)
			begin
				state <= MAIN_MENU;
				waitTimer1 <= 72; // 3 seconds
				waitTimer2 <= 48;	// 2 seconds
				countDigit <= 0;
				p1_score <= 0;
				p2_score <= 0;
			end	
		else
			begin
				case (state)
					MAIN_MENU:
						if (GameStart)
							state <= WAIT;
							
					WAIT:
					begin
						p1_score <= 0;
						p2_score <= 0;
						if (joystickStartButton && p2_joystickStartButton)
							state <= READY;
						else if (joystickStartButton)
							state <= WAIT_P2;
						else if (p2_joystickStartButton)
							state <= WAIT_P1;
					end
					
					WAIT_P1:
						if (joystickStartButton)
							state <= READY;
							
					WAIT_P2:
						if (p2_joystickStartButton)
							state <= READY;
							
					READY:
					begin
						if (waitTimer1 == 0)
							begin
								state <= GAME;
								waitTimer1 <= 72;
							end
						else
							begin
								if (waitTimer1 <= 24)
									countDigit <= 1;
								else if (waitTimer1 <= 48)
									countDigit <= 2;
								else if (waitTimer1 <= 72)
									countDigit <= 3;
								waitTimer1 <= waitTimer1 - 1;
							end	
					end
					
					GAME:
					begin
						if (p1_dead && p2_dead)
							state <= RND_DRAW;
						else if (p1_dead)
							begin
								state <= RND_WON_P2;
								p2_score <= p2_score + 1;
							end
						else if (p2_dead)
							begin
								state <= RND_WON_P1;
								p1_score <= p1_score + 1;
							end
					end
					
					RND_WON_P1:
					begin
						if (waitTimer2 == 0)
							begin
								if (p1_score == 3)
									state <= GAME_WON_P1;
								else
									state <= READY;
								waitTimer2 <= 48;
							end
						else
							waitTimer2 <= waitTimer2 - 1;
					end
					
					RND_WON_P2:
					begin
						if (waitTimer2 == 0)
							begin
								if (p2_score == 3)
									state <= GAME_WON_P2;
								else
									state <= READY;
								waitTimer2 <= 48;
							end
						else
							waitTimer2 <= waitTimer2 - 1;
					end
					
					RND_DRAW:
					begin
						if (waitTimer2 == 0)
							begin
								state <= READY;
								waitTimer2 <= 48;
							end
						else
							waitTimer2 <= waitTimer2 - 1;
					end
											
					GAME_WON_P1:
					begin
						if (waitTimer2 == 0)
							begin
								state <= PLAY_AGAIN;
								waitTimer2 <= 48;
							end
						else
							waitTimer2 <= waitTimer2 - 1;
					end
					
					GAME_WON_P2:
					begin
						if (waitTimer2 == 0)
							begin
								state <= PLAY_AGAIN;
								waitTimer2 <= 48;
							end
						else
							waitTimer2 <= waitTimer2 - 1;
					end
											
					PLAY_AGAIN:
					begin
						if (Accept)
							state <= WAIT;
						else if (Decline)
							state <= MAIN_MENU;
					end			
				endcase
			end
	end
	
	
	/////////////////////////////////////////////////////////////////
	////////////		Joystick control starts here		//////////////
	/////////////////////////////////////////////////////////////////
	PmodJSTK p1_PmodJSTK_Int(	// PmodJSTK Interfaces
			.CLK(sys_clk),
			.RST(Reset),
			.sndRec(p1_sndRec),
			.DIN(p1_sndData),
			.MISO(p1_MISO),
			.SS(p1_SS),
			.SCLK(p1_SCLK),
			.MOSI(p1_MOSI),
			.DOUT(p1_jstkData)
	);
	
	PmodJSTK p2_PmodJSTK_Int(
			.CLK(sys_clk),
			.RST(Reset),
			.sndRec(p2_sndRec),
			.DIN(p2_sndData),
			.MISO(p2_MISO),
			.SS(p2_SS),
			.SCLK(p2_SCLK),
			.MOSI(p2_MOSI),
			.DOUT(p2_jstkData)
	);
	
	ClkDiv_5Hz p1_genSndRec(	// Send/Recieve Generators
			.CLK(sys_clk),
			.RST(Reset),
			.CLKOUT(p1_sndRec)
	);
	
	ClkDiv_5Hz p2_genSndRec(
			.CLK(sys_clk),
			.RST(Reset),
			.CLKOUT(p2_sndRec)
	);
	
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	hvsync_generator syncgen(.clk(sys_clk), .reset(Reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync),
		.inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

	// Player 1 Settings -----------------------------------------------------------------------------------------------
	always @ (posedge DIV_CLK[21], posedge Reset)
	begin
		if (Reset)
			begin
				// p1 initialization
				velocityX <= 0;
				velocityY <= 0;
				direction <= 2'bXX;
				bombY <= 0;
				bombX <= 0;
				bombRad <= 15;
				bombCount <= 0;
				bombTimer <= 0;
				bombDelay <= 96; // 4 seconds
				explodeTimer <= 24;
				explode <= 0;
				p1_dead <= 0;
			end
		else
			begin
				case (state)
					MAIN_MENU:
					begin
						velocityX <= 0;
						velocityY <= 0;
						direction <= 2'bXX;
						bombY <= 0;
						bombX <= 0;
						bombRad <= 15;
						bombCount <= 0;
						bombTimer <= 0;
						bombDelay <= 96;
						explodeTimer <= 24;
						explode <= 0;
						p1_dead <= 0;
					end
					
					WAIT:
					begin
						velocityX <= 0;
						velocityY <= 0;
						direction <= 2'bXX;
						bombY <= 0;
						bombX <= 0;
						bombRad <= 15;
						bombCount <= 0;
						bombTimer <= 0;
						bombDelay <= 96;
						explodeTimer <= 24;
						explode <= 0;
						p1_dead <= 0;
					end
					
					READY:
					begin
						velocityX <= 0;
						velocityY <= 0;
						direction <= 2'bXX;
						bombY <= 0;
						bombX <= 0;
						bombRad <= 15;
						bombCount <= 0;
						bombTimer <= 0;
						bombDelay <= 96;
						explodeTimer <= 24;
						explode <= 0;
						p1_dead <= 0;
					end
					
					GAME:
					begin
						if (joystickY > 700 && ~(joystickX < 400) && ~(joystickX > 600))
							begin
								velocityY <= -3;
								direction <= 0;
							end
						else if (joystickY < 300 && ~(joystickX < 400) && ~(joystickX > 600))
							begin
								velocityY <= 3;
								direction <= 1;
							end
						else if (joystickX < 300 && ~(joystickY < 400) && ~(joystickY > 600))
							begin
								velocityX <= -3;
								direction <= 2;
							end
						else if (joystickX > 700 && ~(joystickY < 400) && ~(joystickY > 600))
							begin
								velocityX <= 3;
								direction <= 3;
							end
						else
							begin
								velocityX <= 0;
								velocityY <= 0;
							end
						if (joystickBombButton && bombCount == 0 && bombTimer == 0 && explode == 0)
							begin
								bombCount <= bombCount + 1;
								bombTimer <= bombDelay;
								bombY <= positionY;
								bombX <= positionX;
							end
						if (!(bombTimer == 0))
							bombTimer <= bombTimer - 1;
						else if ((bombTimer == 0) && !(bombCount == 0))
							begin
								bombCount <= bombCount - 1;
								explode <= 1;
							end			
						if (explode)
							explodeTimer <=  explodeTimer - 1;
						if (explodeTimer == 0)
							begin
								explode <= 0;
								explodeTimer <= 24;
							end
						if (p1_killed)
							p1_dead <= 1;
					end
				endcase
			end
	end
		
	always @ (posedge DIV_CLK[21], posedge Reset)	
	begin
		if(Reset)
			begin
				positionX <= 30;
				positionY <= 31;
			end
		else
			begin
				case (state)
					MAIN_MENU:
					begin
						positionX <= 30;
						positionY <= 31;
					end
					
					WAIT:
					begin
						positionX <= 30;
						positionY <= 31;
					end
					
					READY:
					begin
						positionX <= 30;
						positionY <= 31;
					end
					
					GAME:
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
				endcase
			end
	end
	
	// Player 2 Settings -----------------------------------------------------------------------------------------------
	always @ (posedge DIV_CLK[21], posedge Reset)
	begin
		if (Reset)
			begin
				// p2 initialization
				p2_velocityX <= 0;
				p2_velocityY <= 0;
				p2_direction <= 2'bXX;
				p2_bombY <= 0;
				p2_bombX <= 0;
				p2_bombRad <= 15;
				p2_bombCount <= 0;
				p2_bombTimer <= 0;
				p2_bombDelay <= 96; // 4 seconds
				p2_explodeTimer <= 24;
				p2_explode <= 0;
				p2_dead <= 0;
			end
		else
			begin
				case (state)
					MAIN_MENU:
					begin
						p2_velocityX <= 0;
						p2_velocityY <= 0;
						p2_direction <= 2'bXX;
						p2_bombY <= 0;
						p2_bombX <= 0;
						p2_bombRad <= 15;
						p2_bombCount <= 0;
						p2_bombTimer <= 0;
						p2_bombDelay <= 96;
						p2_explodeTimer <= 24;
						p2_explode <= 0;
						p2_dead <= 0;
					end
					
					WAIT:
					begin
						p2_velocityX <= 0;
						p2_velocityY <= 0;
						p2_direction <= 2'bXX;
						p2_bombY <= 0;
						p2_bombX <= 0;
						p2_bombRad <= 15;
						p2_bombCount <= 0;
						p2_bombTimer <= 0;
						p2_bombDelay <= 96;
						p2_explodeTimer <= 24;
						p2_explode <= 0;
						p2_dead <= 0;
					end
					
					READY:
					begin
						p2_velocityX <= 0;
						p2_velocityY <= 0;
						p2_direction <= 2'bXX;
						p2_bombY <= 0;
						p2_bombX <= 0;
						p2_bombRad <= 15;
						p2_bombCount <= 0;
						p2_bombTimer <= 0;
						p2_bombDelay <= 96;
						p2_explodeTimer <= 24;
						p2_explode <= 0;
						p2_dead <= 0;
					end
					
					GAME:
					begin
						if (p2_joystickY > 700 && ~(p2_joystickX < 400) && ~(p2_joystickX > 600))
							begin
								p2_velocityY <= -3;
								p2_direction <= 0;
							end
						else if (p2_joystickY < 300 && ~(p2_joystickX < 400) && ~(p2_joystickX > 600))
							begin
								p2_velocityY <= 3;
								p2_direction <= 1;
							end
						else if (p2_joystickX < 300 && ~(p2_joystickY < 400) && ~(p2_joystickY > 600))
							begin
								p2_velocityX <= -3;
								p2_direction <= 2;
							end
						else if (p2_joystickX > 700 && ~(p2_joystickY < 400) && ~(p2_joystickY > 600))
							begin
								p2_velocityX <= 3;
								p2_direction <= 3;
							end
						else
							begin
								p2_velocityX <= 0;
								p2_velocityY <= 0;
							end
						if (p2_joystickBombButton && p2_bombCount == 0 && p2_bombTimer == 0 && p2_explode == 0)
							begin
								p2_bombCount <= p2_bombCount + 1;
								p2_bombTimer <= p2_bombDelay;
								p2_bombY <= p2_positionY;
								p2_bombX <= p2_positionX;
							end
						if (!(p2_bombTimer == 0))
							p2_bombTimer <= p2_bombTimer - 1;
						else if ((p2_bombTimer == 0) && !(p2_bombCount == 0))
							begin
								p2_bombCount<= p2_bombCount - 1;
								p2_explode <= 1;
							end			
						if (p2_explode)
							p2_explodeTimer <=  p2_explodeTimer - 1;		
						if (p2_explodeTimer == 0)
							begin
								p2_explode <= 0;
								p2_explodeTimer <= 24;
							end
						if (p2_killed)
							p2_dead <= 1;
					end
				endcase
			end
	end
		
	always @ (posedge DIV_CLK[21], posedge Reset)	
	begin
		if (Reset)
			begin
				p2_positionX <= 610;
				p2_positionY <= 450;
			end
		else
			begin
				case (state)
					MAIN_MENU:
					begin
						p2_positionX <= 610;
						p2_positionY <= 450;
					end
					
					WAIT:
					begin
						p2_positionX <= 610;
						p2_positionY <= 450;
					end
					
					READY:
					begin
						p2_positionX <= 610;
						p2_positionY <= 450;
					end
					
					GAME:
					begin
						p2_positionX <= p2_positionX + p2_velocityX;
						p2_positionY <= p2_positionY + p2_velocityY;
						if (p2_positionY < 26)
							p2_positionY <= 27;
						else if (p2_positionY > 454)
							p2_positionY <= 453;					
						else if (p2_positionX < 25)
							p2_positionX <= 26;
						else if (p2_positionX > 615)
							p2_positionX <= 614;
						else if (p2_direction == 0)
							begin
								if (p2_maze_block_0 || p2_maze_block_1 || p2_maze_block_2 || p2_maze_block_3)
									p2_positionY <= 131;
								else if (p2_maze_block_4 || p2_maze_block_5 || p2_maze_block_6 || p2_maze_block_7)
									p2_positionY <= 235;
								else if (p2_maze_block_8 || p2_maze_block_9 || p2_maze_block_10 || p2_maze_block_11)
									p2_positionY <= 339;
								else if (p2_maze_block_12 || p2_maze_block_13 || p2_maze_block_14 || p2_maze_block_15)
									p2_positionY <= 443;
							end
						else if (p2_direction == 1)
							begin
								if (p2_maze_block_0 || p2_maze_block_1 || p2_maze_block_2 || p2_maze_block_3)
									p2_positionY <= 37;
								else if (p2_maze_block_4 || p2_maze_block_5 || p2_maze_block_6 || p2_maze_block_7)
									p2_positionY <= 141;
								else if (p2_maze_block_8 || p2_maze_block_9 || p2_maze_block_10 || p2_maze_block_11)
									p2_positionY <= 245;
								else if (p2_maze_block_12 || p2_maze_block_13 || p2_maze_block_14 || p2_maze_block_15)
									p2_positionY <= 349;
							end
						else if (p2_direction == 2)
							begin
								if (p2_maze_block_0 || p2_maze_block_4 || p2_maze_block_8 || p2_maze_block_12)
									p2_positionX <= 166;
								else if (p2_maze_block_1 || p2_maze_block_5 || p2_maze_block_9 || p2_maze_block_13)
									p2_positionX <= 306;
								else if (p2_maze_block_2 || p2_maze_block_6 || p2_maze_block_10 || p2_maze_block_14)
									p2_positionX <= 446;
								else if (p2_maze_block_3 || p2_maze_block_7 || p2_maze_block_11 || p2_maze_block_15)
									p2_positionX <= 586;
							end
						else if (p2_direction == 3)
							begin
								if (p2_maze_block_0 || p2_maze_block_4 || p2_maze_block_8 || p2_maze_block_12)
									p2_positionX <= 54;
								else if (p2_maze_block_1 || p2_maze_block_5 || p2_maze_block_9 || p2_maze_block_13)
									p2_positionX <= 194;
								else if (p2_maze_block_2 ||p2_maze_block_6 || p2_maze_block_10 || p2_maze_block_14)
									p2_positionX <= 334;
								else if (p2_maze_block_3 || p2_maze_block_7 || p2_maze_block_11 || p2_maze_block_15)
									p2_positionX <= 474;
							end			
					end
				endcase
			end
	end
	
	// PLAYER 1 BOMB
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
	
	// PLAYER 2 BOMB
	wire p2_BOMB_DROP = (((CounterY-p2_bombY)*(CounterY-p2_bombY)) + ((CounterX-p2_bombX)*(CounterX-p2_bombX))) < (p2_bombRad*p2_bombRad) && (p2_bombCount == 1) && p2_bombTimer[3] == 0;
	wire p2_EXPLOSION0 = (p2_bombY >= 6 && p2_bombY <= 58) && (((CounterY >= 10) && (CounterY <= 54)) && ((CounterX >= 9) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION1 = (p2_bombY >= 110 && p2_bombY <= 162) && (((CounterY >= 114) && (CounterY <= 158)) && ((CounterX >= 9) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION2 = (p2_bombY >= 214 && p2_bombY <= 266) && (((CounterY >= 218) && (CounterY <= 262)) && ((CounterX >= 9) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION3 = (p2_bombY >= 318 && p2_bombY <= 370) && (((CounterY >= 322) && (CounterY <= 366)) && ((CounterX >= 9) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION4 = (p2_bombY >= 422 && p2_bombY <= 474) && (((CounterY >= 426) && (CounterY <= 470)) && ((CounterX >= 9) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION5 = (p2_bombX >= 5 && p2_bombX <= 75) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 9) && (CounterX <= 69))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION6 = (p2_bombX >= 145 && p2_bombX <= 215) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 149) && (CounterX <= 211))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION7 = (p2_bombX >= 285 && p2_bombX <= 355) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 289) && (CounterX <= 351))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION8 = (p2_bombX >= 425 && p2_bombX <= 495) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 429) && (CounterX <= 491))) && !(p2_explodeTimer == 0) && p2_explode;
	wire p2_EXPLOSION9 = (p2_bombX >= 565 && p2_bombX <= 635) && (((CounterY >= 6) && (CounterY <= 474)) && ((CounterX >= 569) && (CounterX <= 631))) && !(p2_explodeTimer == 0) && p2_explode;
	
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
		
	wire PLAYER1 = (CounterY >= (positionY-20) && CounterY <= (positionY+20) && CounterX >= (positionX-20) && CounterX <= (positionX+20)) && ~p1_dead;
	wire PLAYER2 = (CounterY >= (p2_positionY-20) && CounterY <= (p2_positionY+20) && CounterX >= (p2_positionX-20) && CounterX <= (p2_positionX+20)) && ~p2_dead;
	
	wire p1_EXPLOSION = BOMB_DROP || EXPLOSION0 || EXPLOSION1 || EXPLOSION2 || EXPLOSION3 || EXPLOSION4 || EXPLOSION5 || EXPLOSION6 ||
		EXPLOSION7 || EXPLOSION8 || EXPLOSION9;
	wire p2_EXPLOSION = p2_BOMB_DROP || p2_EXPLOSION0 || p2_EXPLOSION1 || p2_EXPLOSION2 || p2_EXPLOSION3 || p2_EXPLOSION4 || 
		p2_EXPLOSION5 || p2_EXPLOSION6 || p2_EXPLOSION7 || p2_EXPLOSION8 || p2_EXPLOSION9;
	
	wire R = PLAYER1 || PLAYER2 || p1_EXPLOSION;
	wire G = PLAYER2 || MAZE_WALL || MAZE_BLOCK;
	wire B = p2_EXPLOSION || p1_EXPLOSION;
	
	always @(posedge sys_clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end


	/////////////////////////////////////////////////////////////////
	///////////////		LCD control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	assign LCD_bl = 0;
	
	lcd_core lcd_ctrl (
		.clk(board_clk), 
		.reset(Reset), 
		.lcd_data(LCD_data), 
		.lcd_e(LCD_e), 
		.lcd_rs(LCD_rs),
		.lcd_rw(LCD_rw),
		.data_f1(data1), .data_f2(data2), .data_f3(data3), .data_f4(data4), .data_f5(data5), .data_f6(data6), 
		.data_f7(data7), .data_f8(data8), .data_f9(data9), .data_f10(data10), .data_f11(data11), .data_f12(data12), 
		.data_f13(data13), .data_f14(data14), .data_f15(data15), .data_f16(data16),.data_s1(data17), .data_s2(data18), 
		.data_s3(data19), .data_s4(data20), .data_s5(data21),.data_s6(data22), .data_s7(data23), .data_s8(data24),
		.data_s9(data25), .data_s10(data26), .data_s11(data27), .data_s12(data28), .data_s13(data29), .data_s14(data30),
		.data_s15(data31), .data_s16(data32)
	);
	
	always @ (posedge DIV_CLK[21])
	begin
		case (state)
			MAIN_MENU:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= " ";
					data4 <= "P";
					data5 <= "y";
					data6 <= "r";
					data7 <= "o";
					data8 <= "M";
					data9 <= "a";
					data10 <= "s";
					data11 <= "t";
					data12 <= "e";
					data13 <= "r";
					data14 <= " ";
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= "P";
					data20 <= "r";
					data21 <= "e";
					data22 <= "s";
					data23 <= "s";
					data24 <= " ";
					data25 <= "S";
					data26 <= "t";
					data27 <= "a";
					data28 <= "r";
					data29 <= "t";
					data30 <= "!";
					data31 <= " ";
					data32 <= " ";
				end
			
			WAIT:
				begin
					data1 <= " ";
					data2 <= "W";
					data3 <= "a";
					data4 <= "i";
					data5 <= "t";
					data6 <= "i";
					data7 <= "n";
					data8 <= "g";
					data9 <= " ";
					data10 <= "f";
					data11 <= "o";
					data12 <= "r";
					data13 <= " ";
					data14 <= "P";
					data15 <= "1";
					data16 <= " ";

					data17 <= " ";
					data18 <= "W";
					data19 <= "a";
					data20 <= "i";
					data21 <= "t";
					data22 <= "i";
					data23 <= "n";
					data24 <= "g";
					data25 <= " ";
					data26 <= "f";
					data27 <= "o";
					data28 <= "r";
					data29 <= " ";
					data30 <= "P";
					data31 <= "2";
					data32 <= " ";
				end
			
			WAIT_P1:
				begin
					data1 <= " ";
					data2 <= "W";
					data3 <= "a";
					data4 <= "i";
					data5 <= "t";
					data6 <= "i";
					data7 <= "n";
					data8 <= "g";
					data9 <= " ";
					data10 <= "f";
					data11 <= "o";
					data12 <= "r";
					data13 <= " ";
					data14 <= "P";
					data15 <= "1";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= "P";
					data21 <= "2";
					data22 <= " ";
					data23 <= "R";
					data24 <= "e";
					data25 <= "a";
					data26 <= "d";
					data27 <= "y";
					data28 <= "!";
					data29 <= "!";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			WAIT_P2:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= " ";
					data4 <= "P";
					data5 <= "1";
					data6 <= " ";
					data7 <= "R";
					data8 <= "e";
					data9 <= "a";
					data10 <= "d";
					data11 <= "y";
					data12 <= "!";
					data13 <= "!";
					data14 <= " ";
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= "W";
					data19 <= "a";
					data20 <= "i";
					data21 <= "t";
					data22 <= "i";
					data23 <= "n";
					data24 <= "g";
					data25 <= " ";
					data26 <= "f";
					data27 <= "o";
					data28 <= "r";
					data29 <= " ";
					data30 <= "P";
					data31 <= "2";
					data32 <= " ";
				end
			
			READY:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= " ";
					data4 <= "G";
					data5 <= "a";
					data6 <= "m";
					data7 <= "e";
					data8 <= " ";
					data9 <= "S";
					data10 <= "t";
					data11 <= "a";
					data12 <= "r";
					data13 <= "t";
					data14 <= " ";
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= "i";
					data23 <= "n";
					data24 <= " ";
					data25 <= "-";
					data26 <= " ";
					data27 <= bin2x(countDigit);
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			GAME:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= "P";
					data4 <= "1";
					data5 <= " ";
					data6 <= "S";
					data7 <= "c";
					data8 <= "o";
					data9 <= "r";
					data10 <= "e";
					data11 <= " ";
					data12 <= "-";
					data13 <= " ";
					data14 <= bin2x(p1_score);
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= "P";
					data20 <= "2";
					data21 <= " ";
					data22 <= "S";
					data23 <= "c";
					data24 <= "o";
					data25 <= "r";
					data26 <= "e";
					data27 <= " ";
					data28 <= "-";
					data29 <= " ";
					data30 <= bin2x(p2_score);
					data31 <= " ";
					data32 <= " ";
				end
			
			RND_WON_P1:
				begin
					data1 <= " ";
					data2 <= "P";
					data3 <= "1";
					data4 <= " ";
					data5 <= "w";
					data6 <= "i";
					data7 <= "n";
					data8 <= "s";
					data9 <= " ";
					data10 <= "R";
					data11 <= "o";
					data12 <= "u";
					data13 <= "n";
					data14 <= "d";
					data15 <= "!";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= " ";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= " ";
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			RND_WON_P2:
				begin
					data1 <= " ";
					data2 <= "P";
					data3 <= "2";
					data4 <= " ";
					data5 <= "w";
					data6 <= "i";
					data7 <= "n";
					data8 <= "s";
					data9 <= " ";
					data10 <= "R";
					data11 <= "o";
					data12 <= "u";
					data13 <= "n";
					data14 <= "d";
					data15 <= "!";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= " ";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= " ";
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			RND_DRAW:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= "R";
					data4 <= "o";
					data5 <= "u";
					data6 <= "n";
					data7 <= "d";
					data8 <= " ";
					data9 <= "D";
					data10 <= "r";
					data11 <= "a";
					data12 <= "w";
					data13 <= "!";
					data14 <= "!";
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= " ";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= " ";
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			GAME_WON_P1:
				begin
					data1 <= " ";
					data2 <= "P";
					data3 <= "1";
					data4 <= " ";
					data5 <= "w";
					data6 <= "i";
					data7 <= "n";
					data8 <= "s";
					data9 <= " ";
					data10 <= "G";
					data11 <= "a";
					data12 <= "m";
					data13 <= "e";
					data14 <= "!";
					data15 <= "!";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= " ";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= " ";
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			GAME_WON_P2:
				begin
					data1 <= " ";
					data2 <= "P";
					data3 <= "2";
					data4 <= " ";
					data5 <= "w";
					data6 <= "i";
					data7 <= "n";
					data8 <= "s";
					data9 <= " ";
					data10 <= "G";
					data11 <= "a";
					data12 <= "m";
					data13 <= "e";
					data14 <= "!";
					data15 <= "!";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= " ";
					data21 <= " ";
					data22 <= " ";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= " ";
					data28 <= " ";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
			
			PLAY_AGAIN:
				begin
					data1 <= " ";
					data2 <= " ";
					data3 <= " ";
					data4 <= "P";
					data5 <= "l";
					data6 <= "a";
					data7 <= "y";
					data8 <= " ";
					data9 <= "A";
					data10 <= "g";
					data11 <= "a";
					data12 <= "i";
					data13 <= "n";
					data14 <= " ";
					data15 <= " ";
					data16 <= " ";

					data17 <= " ";
					data18 <= " ";
					data19 <= " ";
					data20 <= "Y";
					data21 <= "e";
					data22 <= "s";
					data23 <= " ";
					data24 <= " ";
					data25 <= " ";
					data26 <= " ";
					data27 <= "N";
					data28 <= "o";
					data29 <= " ";
					data30 <= " ";
					data31 <= " ";
					data32 <= " ";
				end
		endcase
	end
	
	//function for binary to hexadecimal(character) conversion
	function [7:0] bin2x;
		input [3:0] data;
		begin
			case (data)
				4'h0:	bin2x = "0";	4'h1: bin2x = "1";	4'h2: bin2x = "2";	4'h3: bin2x = "3";
				4'h4:	bin2x = "4";	4'h5: bin2x = "5";	4'h6: bin2x = "6";	4'h7: bin2x = "7";
				4'h8:	bin2x = "8";	4'h9: bin2x = "9";	4'hA: bin2x = "A";	4'hB: bin2x = "B";
				4'hC:	bin2x = "C";	4'hD: bin2x = "D";	4'hE: bin2x = "E";	4'hF: bin2x = "F";
				default: bin2x = "0";
			endcase
		end
	endfunction

	
endmodule
