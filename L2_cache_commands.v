/////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// L2_cache_commands.v - Commands to and from L2 Cache
//
/////////////////////////////////////////////////////////////////////////////////////////
module L2_cache_commands(
	// INPUTS
	input [25:0]  address_in,		// address in from L1
	input [1:0]   command_in		// command from L1 
   );
	
	  parameter Read_In     = 2'b01;     	  // Read in from L2 cache
	  parameter Write_Out   = 2'b10;     	  // Write to L2
	  parameter RWITM_In    = 2'b10;  		  // Read with intent to modify from L2
	  parameter NOP         = 2'b00;		  // No Operation

endmodule
