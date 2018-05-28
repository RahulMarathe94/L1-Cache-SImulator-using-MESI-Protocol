/////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// instruction_cache.v - Simulates a L1-Instruction Cache using MESI protocol
//				  		 for Cache Coherence Problem
/////////////////////////////////////////////////////////////////////////////////////////
`define Sets 1024*16
`define Ways 2
`define Index_Bits 14
`define Tag_Bits 12


module instruction_cache(
  // Outputs from the cache
  output reg [31:0] hit     = 32'b0,  			// to statistics module
  output reg [31:0] miss    = 32'b0,  			// to statistics module
  output reg [31:0] reads   = 32'b0,    		// to statistics module
  output reg [25:0] addr_to_L2 = 26'bZ,  		// to next-level shared L2 cache
  output reg [1:0]  command_to_L2 = 2'b00,    	// to next-level shared L2 cache
  
  // Inputs to the cache
  input [3:0]  n,           // from trace file
  input [31:0] address_in,  // from trace file
  input Clock,
  input mode				// from command line 
  

  );
  
  parameter TRUE       = 1'b1;
  parameter FALSE      = 1'b0;
  
  // Valid MESI states for instruction cache
  parameter EXCLUSIVE	= 2'd2;
  parameter SHARED	= 2'd1;
  parameter INVALID 	= 2'd0;
  
  // Valid commands for instruction cache
  parameter Reset        = 4'd8;
  parameter Instruction_Fetch   = 4'd2;
  parameter Print        = 4'd9;
  
 // Instruction cache sends following commands to next-level cache
  parameter Read_In    = 2'b01;
  parameter NOP         = 2'b00;
  
  // Tag bits
  // 12 Tagbits per way in each set
  reg [`Tag_Bits-1:0] Tag [`Sets-1:0][`Ways-1:0];
    
  // 2 MESI bits per way in each set
  reg [1:0] MESI [`Sets-1:0] [`Ways-1:0]; 
  
  // LRU bit for instruction cache
  // 1 bit per set
  reg LRU [`Sets-1:0];

  // Loop counters
  integer index_counter, way_counter;
   
  // To know the task is complete
  reg Finish = 1'b0;
  
  // Bit-selecting tag and index bits from input address 
  wire [11:0] current_tag = address_in[31:20];
  wire [13:0] current_index = address_in[19:6];

  always @(posedge Clock)
  begin  
		addr_to_L2 = 26'bZ;  
		command_to_L2 = NOP;    
		Finish    = FALSE;  
   
		case(n)
		  // Set the all the ways in all sets INVALID
		  // Tag of all ways 0
		  // Reset statistics parameters
			Reset:
			begin
				hit    = 32'b0;
				miss   = 32'b0;
				reads  = 32'b0;
				for (index_counter = 0; index_counter < `Sets; index_counter = index_counter + 1'b1) 
				begin
					LRU[index_counter] = 1'b0;  // set the LRU to 0
					for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1) 
					begin
						Tag    [index_counter][way_counter]  = `Tag_Bits'b0;
						MESI  [index_counter][way_counter]   = INVALID;
					end
				end
			end
      
			Instruction_Fetch:
			begin
				// increment the number of total reads since reset occurred 
				reads = reads + 1'b1; 
				// search the ways within the set, if there is a hit update the LRU bits of  
				// and increment the hit counter
				for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
				begin
					if (Finish == FALSE)
						if (Tag[current_index][way_counter] == current_tag && (MESI[current_index][way_counter]== SHARED ||
							MESI[current_index][way_counter]== EXCLUSIVE))
							begin
								LRU[current_index] = ~way_counter[0]; 
								hit             = hit + 1'b1;
								Finish             = TRUE;
							end
					else ;
			end
        
			// If there was no hit, increment the miss counter
			if (Finish == FALSE)
				miss = miss + 1'b1;
        
			// If  there was no hit, check to see if there is an invalid way in the set
			for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
			begin
				if (Finish == FALSE)
					if (MESI[current_index][way_counter]== INVALID)
					begin
						addr_to_L2         = address_in[31:6]; 
						command_to_L2      = Read_In;    
						if(mode==1)
							$display("Read from L2 %8h",address_in);
						Tag[current_index][way_counter] = current_tag;
						LRU[current_index]              = ~way_counter[0]; 
						MESI[current_index][way_counter]    = SHARED;
						Finish                           = TRUE;
					end
			end
        
			// If there was no invalid way, evict the LRU way
			// If the victime line is EXCLUSIVE or SHARED no need to write back the line
			if (Finish == FALSE)
			begin
				addr_to_L2                   = address_in[31:6]; 
				command_to_L2                = Read_In; 
				if(mode==1)
					$display("Read from L2 %8h",address_in);
				Tag[current_index][LRU[current_index]]  = current_tag;  
				LRU[current_index]                      = ~LRU[current_index]; 
				MESI[current_index][way_counter]	 	= SHARED;
				Finish                                  = TRUE;
			end
		end
    
		Print:
		begin   
			
			$display("\n==========INSTRUCTION CACHE CONTENTS========");
			for (index_counter = 0; index_counter < `Sets; index_counter = index_counter+1)
			begin
				if (MESI[index_counter][0]!=INVALID)
				begin
					$write("\nSET: %4h | LRU: %d | WAY:0 ",index_counter[`Index_Bits-1:0], LRU[index_counter]);
					if(MESI[index_counter][0]==1) begin
						$write("MESI: S ");
						$write(" TAG: \t%3h | ",MESI[index_counter][0]!=INVALID ? Tag[index_counter][0] : "" );
					end
				end
				
				if (MESI[index_counter][1]!=INVALID)
				begin
					$write(" WAY:1 ");
					if(MESI[index_counter][1]==1) begin
						$write("MESI: S ");
						$write(" TAG: \t%3h\n",MESI[index_counter][1]!=INVALID ? Tag[index_counter][1] : "" );
					end
				end
			end
			$display("\n======END OF INSTRUCTION CACHE CONTENTS========\n");
		end
      
		default:;
	endcase
  end    
  
endmodule
