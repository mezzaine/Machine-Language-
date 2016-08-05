//===========================================================
//  This code was created by Ni A Nguyen and Sarah Dunning
//===========================================================

module KeypadScanner(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,
	output							rawValid,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// GPIO_0, GPIO_0 connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);

	//output rawValid; //defaults to type wire
	wire [3:0] rawKey; // 4 keys 	
	reg [15:0] counter; // (4.6)  a 16-bit counter of the number of key depressions 
	wire reset = ~KEY[3]; //assigning key to resest LEDs

	/* HEX asssignments and counter */
	SevenSegment Hex0(rawKey[3:0], rawValid, HEX0);
	SevenSegment Hex1(0, 0, HEX1);
	SevenSegment Hex2(counter[3:0], 1, HEX2);
	SevenSegment Hex3(counter[7:4], (counter>15), HEX3);
	SevenSegment Hex4(counter[11:8], (counter>255), HEX4);
	SevenSegment Hex5(counter[15:12], (counter>4095), HEX5);

	ScanPad keypad(CLOCK_50, 
					  {GPIO[11],GPIO[13],GPIO[15],GPIO[17],
					   GPIO[19],GPIO[21],GPIO[23],GPIO[25]},
				      rawKey, rawValid);
					  
	/* Counts number of time a key is pressed 
		Triggered when rawValid changes either from a 
		1 to 0 OR 0 to 1*/
	always @ (posedge rawValid, posedge reset)
		begin
			if(reset)
				counter <= 0; 
			else 
				begin 
					if(rawValid == 1)
						counter <= counter + 1; 
				end 
		end
		
endmodule

module ScanPad( input CLOCK_50, inout [7:0] keypad, output reg [3:0] rawKey, output reg rawValid );

	reg [1:0] counter; // (1) 2 bit column counter 
	reg [3:0] column;	 //4-bit
	wire [3:0] row;	 //4-bit 
	
	assign row = keypad[7:4];
	assign keypad[3:0] = column;
					
	always @(posedge CLOCK_50)
		begin 
			if(&row)
				begin 
					counter <= counter + 1;
					rawValid <= 0; // No Keys is being pressed
				end
				else 
					rawValid <= 1; 
		end

	/* (2) Decode the column number to drive the selected 
	column to 0 and the rest to z (high impedance) */
	always @(*)
		case(counter) 
			2'b00 : column = 4'b0zzz; 
			2'b01 : column = 4'bz0zz; 
			2'b10 : column = 4'bzz0z; 
			2'b11 : column = 4'bzzz0; 
		endcase
	
	/* (5) If a key is pressed, translate the row and column 
	number coordinates into the corresponding hex value as rawKey. */
	always @(*)
	begin 
		casex (column)
			4'b0xxx:
				begin
					case (row)
						4'b0111 : rawKey = 4'b0001; //1 
						4'b1011 : rawKey = 4'b0100; //4
						4'b1101 : rawKey = 4'b0111; //7
						4'b1110 : rawKey = 4'b1110; //E
					endcase
				end
			4'bx0xx:
				begin
					case (row)
						4'b0111 : rawKey = 4'b0010; //2 
						4'b1011 : rawKey = 4'b0101; //5
						4'b1101 : rawKey = 4'b1000; //8
						4'b1110 : rawKey = 4'b0000; //0
					endcase
				end
			4'bxx0x:
				begin
					case (row)
						4'b0111 : rawKey = 4'b0011; //3 
						4'b1011 : rawKey = 4'b0110; //6
						4'b1101 : rawKey = 4'b1001; //9
						4'b1110 : rawKey = 4'b1111; //F
					endcase
				end
			4'bxxx0:
				begin
					case (row)
						4'b0111 : rawKey = 4'b1010; //A
						4'b1011 : rawKey = 4'b1011; //B
						4'b1101 : rawKey = 4'b1100; //C
						4'b1110 : rawKey = 4'b1101; //D
					endcase
				end
			endcase
		end

endmodule

module SevenSegment( input [3:0] hexDigit, ENABLE, output [6:0] segments );

	wire b0, b1, b2, b3;
	wire [6:0] s; 
	
	assign b0 = hexDigit[0];
	assign b1 = hexDigit[1];
	assign b2 = hexDigit[2];
	assign b3 = hexDigit[3];
	
	assign s[0] = (b1&b2)|(~b1&~b2&b3)|(~b0&b3)|(~b0&~b2)|(b0&b2&~b3)|(b1&~b3);
	assign s[1] = (~b0&~b2)|(b0&b1&~b3)|(b0&~b2&~b3)|(b0&~b1&b3)|(~b0&~b1&~b3);
	assign s[2] = (~b1&~b3)|(~b1&b0)|(b3&~b2)|(~b3&b2)|(b0&~b3);
	assign s[3] = (b3&~b1) | (b2&~b1&b0) | (~b2&b1&b0) | (b1&~b0&b2) | (~b1&~b0&~b2)|(b1&~b3&~b2);
	assign s[4] = (~b0&~b2)|(b3&b2)|(b1&~b0)|(b1&b0&b3);
	assign s[5] = (~b1&~b0)|(b3&~b2)|(b3&b2&b1)|(b1&~b0&b2)|(~b3&b2&~b1);
	assign s[6] = (b1&~b0)|(b3&~b2)|(b1&~b3&~b2)|(~b1&~b3&b2)|(b2&b3&b0);
	
	assign segments = (ENABLE ? ~s: 7'b1111111);
	
endmodule