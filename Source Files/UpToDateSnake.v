`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// VGA verilog template
// Author:  Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module vga_demo(ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD, btnL, btnR, btnC,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnU, btnD, btnL, btnR, btnC, Sw0, Sw1;
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
	wire [9:0] CounterX;
	wire [9:0] CounterY;

	hvsync_generator syncgen(.clk(clk), .reset(reset),.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////
	
	// positions for the block that the user will control
	reg [9:0] positionX;
	reg [9:0] positionY;
	reg [9:0] position;
	
	// positions for food (needs to be random, currently are fixed)

	reg [4:0] flag;
	
	////////////////////////FOOD///////////////////////
	
	reg [9:0] foodX; //Stores x location of food
	reg [9:0] foodY; //Stores y location of food
	reg food_in_X; //is the current pixel within the x bounds of food?
	reg food_in_Y; //is the current pixel within the y bounds of food?
	reg apple; //1 if current pixel is in food
	wire [9:0] random_x, random_y;
	randomPos randomPos(clk, random_x, random_y); //Assigns random values to random_x and random_y at every clock
	
	always @(posedge clk)
	begin
		food_in_X <= ((CounterX > (foodX - 10)) && (CounterX < (foodX + 10)));
		food_in_Y <= ((CounterY > (foodY - 10)) && (CounterY < (foodY + 10)));
		apple <= food_in_X && food_in_Y; // True if the current pixel is part of the apple
	end
	

	always@(posedge clk)
		begin	
			if(eatFood)
				begin
					if((random_x<10) || (random_x>630) || (random_y<10) || (random_y>470))
						begin
							foodX <= 40;
							foodY <= 30;
						end
					else
						begin
							foodX <= random_x;
							foodY <= random_y;
						end
				end
			else if(reset)
				begin
					if((random_x<10) || (random_x>630) || (random_y<10) || (random_y>470))
						begin
							foodX <=340;
							foodY <=430;
						end
					else
						begin
							foodX <= random_x;
							foodY <= random_y;
						end
				end
		end
		

	////////////////////////FOOD END///////////////////////
	
	//////////////////////SNAKE SIZE///////////////////////

	integer count1;
	integer count2;
	reg [4:0] snakeSize;
	reg [9:0] snakeX[0:32];
	reg [9:0] snakeY[0:32];

	
	//This part was moved to the main always block
	
	//always @(posedge DIV_CLK[21], posedge reset)
	//	begin
	//		if(reset)
	//			begin
	//				for(count1 = 1; count1 < 11; count1 = count1+1)
	//					begin
	//						snakeX[count1] = 120;
	//						snakeY[count1] = 270;
	//					end
	//			end
			//else
		//		begin
					//for(count2 = 10; count2 > 0; count2 = count2 - 1)
						//begin
							//if(count2 <= snakeSize - 1)
								//begin
									//snakeX[count2] = snakeX[count2 - 1];
									//snakeY[count2] = snakeY[count2 - 1];
								//end
						//end
				//end
	//	end


	reg found;
	wire snakeHead;
	reg snakeBody;
	integer count3;

	always@(posedge clk)
		begin
			found = 0;
			
			for(count3 = 1; count3 < snakeSize; count3 = count3 + 1) //For each pixel, every part of the snake will be scanned to see if the pixel is in that part
				begin
					if(~found)
						begin				
							snakeBody = ((CounterX > (snakeX[count3] - 10) && CounterX < snakeX[count3]+10) && (CounterY > (snakeY[count3] - 10) && CounterY < snakeY[count3]+10));
							found = snakeBody;
						end
				end

		end
	assign snakeHead = (CounterX > (snakeX[0] - 10) && CounterX < (snakeX[0]+10)) && (CounterY > (snakeY[0] - 10) && CounterY < (snakeY[0]+10));

	///////////////////////SNAKE SIZE END//////////////////
	
	
	/////////////////////Non-Lethal Collision//////////////
	reg eatFood;

	always @(posedge clk)
		begin
			if(apple && snakeHead && ~eatFood) //If snake and apple are both in the current pixel, grow the snake and replace apple
				begin
					snakeSize <= snakeSize + 1;
					eatFood <= 1;
				end
			else if(reset)
				begin
					snakeSize <= 1;
				end
			else
				begin
					eatFood <= 0;
				end
		end

	/////////////////////Non-Lethal Collision End/////////////
	
	
	
	localparam 
	INI = 5'b00001,
	UP = 5'b00010,
	DOWN = 5'b00100,
	LEFT = 5'b01000,
	RIGHT = 5'b10000;
	
	wire qR, qL, qD, qU, qI;
	assign {qR, qL, qD, qU, qI} = flag;
	
	always @(posedge DIV_CLK[21], posedge reset)
		begin
			if(reset)
				begin
					flag<=INI;
					positionX <= 9'bXXXXXXXXX;
					positionY <= 9'bXXXXXXXXX;

				end
			else
				begin
					
					for(count2 = 32; count2 > 0; count2 = count2 - 1) //Makes each snake segment take the place of the last one
						begin
							//if(count2 <= snakeSize - 1)
								//begin
									snakeX[count2] = snakeX[count2 - 1];
									snakeY[count2] = snakeY[count2 - 1];
								//end
						end
					
					case(flag)
						INI :
							begin
								for(count1 = 1; count1 < 33; count1 = count1+1) //Initializing all parts of snake
									begin
										snakeX[count1] = 120;
										snakeY[count1] = 270;
									end
							
								// state transition
								if(btnU)// && ~btnD && ~btnL && ~btnC) // block goes down
									flag<=UP;
								else if(btnD)// && ~btnL && ~btnC) // block goes up
									flag<=DOWN;
								else if( btnL )//&& ~btnC) // block goes left 
									flag<=LEFT;
								else if(btnC) // block goes right		
									flag<=RIGHT;
							
									
								positionX<=120;
								snakeX[0] = 120;
								positionY<=270;
								snakeY[0] = 270;
								
							end
						UP :
							begin
								//state transition
								if(btnC)
									flag<=RIGHT;
								else if(btnL)
									flag<=LEFT;
									
								//RTL
								if(positionY == 10)
									positionY <= 10;
								else// if(positionX%20 == 0)
									begin
										positionY <= positionY-5;
										snakeY[0] = positionY - 5;
									end
							end
						DOWN :
							begin
								//state transition
								if(btnC)
									flag<=RIGHT;
								else if(btnL)
									flag<=LEFT;
								
								//RTL
								if(positionY == 470)
									positionY <= 470;
								else// if(positionX%20 == 0)
									begin
										positionY <= positionY+5;
										snakeY[0] = positionY + 5;
									end
							end
						RIGHT :
							begin
								// state transition
								if(btnU)
									flag<=UP;
								else if(btnD)
									flag<=DOWN;
								
								// RTL			
								if(positionX == 630)
									positionX <= 630;
								else// if(positionY%20 == 0)// to move in a grid like fashion
									begin
										positionX <= positionX+5;
										snakeX[0] = positionX + 5;
									end
							end
						LEFT :
							begin
								// state transition
								if(btnU)
									flag<=UP;
								else if(btnD)
									flag<=DOWN;
								
								
								// RTL			
								if(positionX == 10)
									positionX <= 10;
								else// if(positionY%20 == 0)// to move in a grid like fashion
									begin
										positionX <= positionX-5;
										snakeX[0] = positionX - 5;
									end
							end
					endcase
			
				end
		end
		
	// 0 -- up
	// 1 -- down
	// 2 -- left
	// 3 -- right


	//wire R = CounterY>=(positionY-10) && CounterY<=(positionY+10) && CounterX[8:5]==7;
	// This alteration of wire R allows us to move the red block left,right,up, and down
	//wire R = CounterY>=(positionY-10) && CounterY<=(positionY+10) && CounterX>=(positionX-10) && CounterX<=(positionX+10);
	wire R = snakeHead || snakeBody;
	
	
	
	//wire G = CounterX>100 && CounterX<200 && CounterY[5:3]==7;
	
	//wire G = (CounterX<640 && CounterX>0 && ((CounterY<50 && CounterY>0) || (CounterY<640 && CounterY>590))) || (((CounterX<40 && CounterX>10)||(CounterX<600 && CounterX>560)) && (CounterY<600 && CounterY>20));
	//wire G = CounterY>=(foodY-10) && CounterY<=(foodY+10) && CounterX>=(foodX-10) && CounterX<=(foodX+10);;
	wire G = apple;
	
	//wire B = CounterY>=(position-10) && CounterY<=(position+10) && CounterX[8:5]==7;
	wire B = snakeBody;
	
	
	
	
	
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
	//assign SSD1 = 4'b1111;
	assign SSD1 = positionX[3:0];
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
