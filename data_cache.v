/////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// data_cache.v - Simulates a L1-Data Cache using MESI protocol
//				  for Cache Coherence Problem
/////////////////////////////////////////////////////////////////////////////////////////

	
	`define Sets 1024*16
	`define Ways 4
	`define Index_Bits 14
	`define Tag_Bits 12



	module data_cache(
	  // Outputs from the cache
	  output reg [31:0] hit     = 32'b0, 	// to statistics module
	  output reg [31:0] miss    = 32'b0, 	// to statistics module
	  output reg [31:0] reads   = 32'b0, 	// to statistics module
	  output reg [31:0] writes  = 32'b0,  	// to statistics module
	  output reg [25:0] addr_to_L2 = 26'bZ, 	// to next-level shared L2 cache
	  output reg [1:0]  command_to_L2 = 2'b00,  // to next-level shared L2 cache
	
	  // Inputs to the cache
	  input [3:0]  n,       // Command from trace file
	  input [31:0] address_in,  // 32-bit address from trace file
	  input Clock,
	  input mode 		// from command line 
	  );
	  `include "lru_next.sv"
	  parameter True        = 1'b1;
	  parameter False       = 1'b0;
	  
	  // Valid MESI MESIs for data cache
	  parameter MODIFIED	= 2'd3; 
	  parameter EXCLUSIVE	= 2'd2;
	  parameter SHARED		= 2'd1;
	  parameter INVALID 	= 2'd0;
	  
	  // Valid commands for data cache
	  parameter Reset       = 4'd8;
	  parameter Invalidate  = 4'd3;
	  parameter Read        = 4'd0;
	  parameter Write       = 4'd1;
	  parameter Snoop	    = 4'd4;
	  parameter Print       = 4'd9;
	 
	  // Data cache sends following commands to next-level cache
	  parameter Read_In     = 2'b01;     	  // Read in from L2 cache
	  parameter Write_Out   = 2'b10;     	  // Write to L2
	  parameter RWITM_In    = 2'b10;  		  // Read with intent to modify from L2
	  parameter NOP         = 2'b00;		  // No Operation

	  // Tag bits
	  // 12 Tagbits per way in each set
	  reg [11:0]  Tag   [`Sets-1:0] [`Ways-1:0];
	  
	  // 2-bit Variables to get output from lru_next task
	  reg [1:0] lrubits0, lrubits1, lrubits2, lrubits3;
	  
	  // 2 MESI bits per way in each set
	  reg [1:0] MESI [`Sets-1:0] [`Ways-1:0];    
	  
	  // LRU bits for counter implementation
	  // 2 bits per way in each set
	  reg [1:0]   LRU [`Sets-1:0][`Ways-1:0];
	  
	  // Loop counters
	  integer index_counter='0, way_counter='0;
	  
	  // Used to set the values of LRU bits during Reset 
	  reg [1:0] count = 2'd3;
	  
	  // To know the task is complete
	  reg Finish = False;
	  
	  // Bit-selecting tag and index bits from input address 
	  wire [11:0] current_tag   = address_in[31:20];           
	  wire [13:0] current_index = address_in[19:6];
	  
	  always@(posedge Clock)
	  begin 
		addr_to_L2 		= 26'bZ;
		command_to_L2   = 2'b00;    
		Finish          = False;
		
		case(n)
		  Reset: 
		  // Set the all the ways in all sets INVALID
		  // Set LRU bits of all ways as follows:
		  // Way0=3 Way1=2 Way2=2 Way3=0
		  // Tag of all ways 0
		  // Reset statistics parameters
		  begin
				hit    = 32'b0;
				miss   = 32'b0;
				reads  = 32'b0;
				writes = 32'b0;

				// for every index 
				for (index_counter = 0; index_counter < `Sets; index_counter = index_counter + 1'b1)  
				begin
					// for all ways 
					for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)  
					begin
						Tag [index_counter][way_counter] = 12'b0;
						LRU [index_counter][way_counter] = count;
						MESI[index_counter][way_counter] = INVALID;
						count = count - 2'd1;
					end
				end
			end
		  
		  Invalidate:
		  begin
			 // When an invalidate command is passed in, check to see if its tag match but not modified, if modified write back to L2
			 // then invalidate the way
			 for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
			 begin
					if (Finish == False)
					begin
						if (Tag[current_index][way_counter] == current_tag)
						begin
							lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
							LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
							
							LRU[current_index][0] = lrubits0;
							LRU[current_index][1] = lrubits1; 
							LRU[current_index][2] = lrubits2;
							LRU[current_index][3] = lrubits3;
							if(MESI [current_index][way_counter] == SHARED || EXCLUSIVE)
							begin
								Finish = True;
								MESI  [current_index][way_counter] = INVALID; 
				 			end
																
							else if(MESI [current_index][way_counter]== MODIFIED) 
							begin
								Finish = True;
								addr_to_L2= address_in[31:6];
								command_to_L2= Write_Out;
								/*if(mode==1)
									$display("Write to L2 %3h%5h",Tag [index_counter][way_counter],address_in);*/
								MESI[current_index][way_counter]= INVALID;
						
							end  
						end
					end
				end
			end
		  
		  Read:
		  begin
			 // increment the number of total reads since reset occurred 
			 reads = reads + 1'b1;
			 // search the ways within the set, if there is a hit update the LRU bits of each way 
			 // and increment the hit counter
			
			 for (way_counter = 0; way_counter < `Ways; way_counter = way_counter +  1'b1)
			 begin
				  if (Finish == False)                       
				  begin 
						if (Tag[current_index][way_counter] == current_tag ) 
						begin	 
							if(  MESI[current_index][way_counter]== SHARED || MESI[current_index][way_counter]== MODIFIED || MESI[current_index][way_counter]== EXCLUSIVE)
							begin 
								lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
								LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
								
								LRU[current_index][0] = lrubits0;
								LRU[current_index][1] = lrubits1; 
								LRU[current_index][2] = lrubits2;
								LRU[current_index][3] = lrubits3;
				    			hit               	  = hit + 1'b1;
								MESI[current_index][way_counter] = MESI[current_index][way_counter];
								Finish                = True;
							end
						end
					end
				end 
			 
			 // If  there was no hit, check to see if there is an invalid way in the set
			 for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
			 begin
				 if (Finish == False)
				 begin
					 if (MESI[current_index][way_counter]== INVALID)
					 begin
						 addr_to_L2                    = address_in[31:6];   
						 command_to_L2                 = Read_In;       
						 if(mode==1)
						 begin	
						    	$display("Read FROM L2 %8h", address_in); 
						   end
						 lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
						 LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
						 
						 LRU[current_index][0] = lrubits0;
						 LRU[current_index][1] = lrubits1; 
						 LRU[current_index][2] = lrubits2;
						 LRU[current_index][3] = lrubits3;
						 Tag[current_index][way_counter]    = current_tag;
						 MESI[current_index][way_counter]   = SHARED;
						 miss = miss + 1'b1;
						 Finish                             = True;
					    end
				    end
			    end
			
			 // If there was no invalid way, evict the LRU way
			 // If the victime line is EXCLUSIVE or SHARED no need to write back the line
			 if (Finish == False)
			 begin
				 for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
				 begin	
					if(Finish==False)
					begin
						if (LRU[current_index][way_counter]==2'b11)
						begin
							if (MESI[current_index][way_counter]== EXCLUSIVE || SHARED)
							begin
								addr_to_L2       = address_in[31:6];  // generate read
								command_to_L2    = Read_In;      // generate read
								if(mode==1)
									$display("Read from L2 %8h",address_in);
							    end
								Tag[current_index][way_counter]      = current_tag; 
								MESI[current_index][way_counter]	 = SHARED; 
								lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
								LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
								
								LRU[current_index][0] = lrubits0;
								LRU[current_index][1] = lrubits1; 
								LRU[current_index][2] = lrubits2;
								LRU[current_index][3] = lrubits3;
								miss = miss + 1'b1;
								Finish                = True;
							end
						end
					end
			    end
			
			 // If the victim line is MODIFIED the line needs to be wrote back
			 if (Finish == False)
			 begin
				for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
				begin
					if(Finish==False)
					begin
						if (LRU[current_index][way_counter]==2'b11)
						begin						
							if (MESI[current_index][way_counter]== MODIFIED)
							begin
								addr_to_L2     = address_in[31:6];       
								command_to_L2  = Write_Out;      
								if(mode==1)
									$display("Write to L2 %3h%5h",Tag[current_index][way_counter],address_in[19:0]); ////////changed
								addr_to_L2     = address_in[31:6];  
								command_to_L2  = Read_In;      
								if(mode==1)
									$display("Read from L2 %8h",address_in);	
							end			  
							Tag[current_index][way_counter]      = current_tag; 
							MESI[current_index][way_counter]	 = SHARED;
							lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
							LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]); 
							
							LRU[current_index][0] = lrubits0;
							LRU[current_index][1] = lrubits1; 
							LRU[current_index][2] = lrubits2;
							LRU[current_index][3] = lrubits3;
							miss = miss + 1'b1;
				     		Finish=True;
						end
					end
				end
			end

		end
			
			
		  	
		  
		  Write:
		  begin
			 // increment the number of total writes since reset occurred 
			 writes = writes + 1;
			
			 // search the ways within the set, if there is a hit, update the LRU
			 // and increment the hit counter

			 //first write hit, write through policy, L1 switches to write back             
			 for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
			 begin
			     if (Finish == False)
			     begin                                                  
					 if (Tag[current_index][way_counter] == current_tag && MESI[current_index][way_counter] == SHARED)
					 begin
						 lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
						 LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
						 
						 LRU[current_index][0] = lrubits0;
						 LRU[current_index][1] = lrubits1; 
						 LRU[current_index][2] = lrubits2;
						 LRU[current_index][3] = lrubits3;
						 hit                   = hit + 1'b1;
						 addr_to_L2            = address_in[31:6];  
						 command_to_L2         = Write_Out;    
						 if(mode==1)
						 	$display("Write to L2 %8h",address_in);
						 MESI[current_index][way_counter] = EXCLUSIVE;
						 Finish                = True;
						end
					end
				end 
		  

			 if(Finish==False)
			 begin
			 //Multiple writes to the same line, write back policy implemented
			    	for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
				    begin
						if (Finish == False) 
						begin
							if (Tag[current_index][way_counter] == current_tag && 
							(MESI[current_index][way_counter] == EXCLUSIVE || MESI[current_index][way_counter] == MODIFIED ))	////Handled modified
							begin   
								lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
								LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
								
								LRU[current_index][0] = lrubits0;
								LRU[current_index][1] = lrubits1; 
								LRU[current_index][2] = lrubits2;
								LRU[current_index][3] = lrubits3;
								hit               = hit + 1'b1;
								MESI[current_index][way_counter]=MODIFIED;
								Finish              = True;	
							end
						end
					end
				end	
			
			 // If there was no hit, check to see if there is an empty			
			 if(Finish==False)
			 begin
					for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
					begin
						if (Finish == False)
						begin
							if (MESI[current_index][way_counter] == INVALID)
							begin
								addr_to_L2 = address_in[31:6];  // read data w/ intent to mod
								command_to_L2 = RWITM_In;       // read data w/ intent to mod
								if(mode==1)
									$display("Read for ownership from %8h", address_in);
								lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
								LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
								
								LRU[current_index][0] = lrubits0;
								LRU[current_index][1] = lrubits1; 
								LRU[current_index][2] = lrubits2;
								LRU[current_index][3] = lrubits3;
								Tag[current_index][way_counter]    = current_tag;
								MESI[current_index][way_counter]   = EXCLUSIVE;							
								addr_to_L2                         = address_in[31:6]; 
								command_to_L2                      = Write_Out;    
								if(mode==1)
									$display("Write to L2 %8h", address_in);
								miss = miss + 1'b1;
								Finish                        = True;
							end
						end
					end
				end

				// If no way is empty evict the LRU way
				if(Finish==False)
				begin
					for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
					begin
						if(Finish==False)
						begin
							if(LRU[current_index][way_counter]==2'b11)
							begin
								addr_to_L2       = address_in[31:6]; 
								command_to_L2    = RWITM_In;      
								if(mode==1)		  
									$display("Read for Ownership from L2 %8h",address_in);
								if (MESI[current_index][way_counter] == EXCLUSIVE || MESI[current_index][way_counter] == SHARED)
								begin
									Tag[current_index][way_counter]    = current_tag;
									MESI[current_index][way_counter]	  = EXCLUSIVE;								
									lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
									LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
									
									LRU[current_index][0] = lrubits0;
									LRU[current_index][1] = lrubits1; 
									LRU[current_index][2] = lrubits2;
									LRU[current_index][3] = lrubits3;
									miss = miss + 1'b1;
									if(mode==1)
									$display("Write to L2 %8h", address_in);
									Finish                       = True;
								end
							end
						end
					end
				end
				
				if(Finish==False)
				begin
					for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
					begin
						if(Finish==False)
						begin
							if(LRU[current_index][way_counter]==2'b11)
							begin
								
								if (MESI[current_index][way_counter] == MODIFIED)
								begin
									addr_to_L2       = address_in[31:6]; 
									command_to_L2    = Write_Out;      
									if(mode==1)		  
										$display("Write to L2 %8h",address_in);
									addr_to_L2       = address_in[31:6]; 
									command_to_L2    = RWITM_In;      
									if(mode==1)		  
										$display("Read for Ownership from L2 %8h",address_in);
									Tag[current_index][way_counter]    = current_tag;
									MESI[current_index][way_counter]	  = EXCLUSIVE;								
									lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
									LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
									
									LRU[current_index][0] = lrubits0;
									LRU[current_index][1] = lrubits1; 
									LRU[current_index][2] = lrubits2;
									LRU[current_index][3] = lrubits3;
									miss = miss + 1'b1;
									Finish                       = True;
								end
							end
						end
					end
				end
				
				
			end
		
		 Snoop:
		 begin
			if(Finish==False)begin
				for (way_counter = 0; way_counter < `Ways; way_counter = way_counter + 1'b1)
				begin
					if (Finish == False)
					begin
						if (Tag[current_index][way_counter] == current_tag && (MESI[current_index][way_counter] == MODIFIED||MESI[current_index][way_counter]==EXCLUSIVE))
						begin 
							addr_to_L2         = address_in[31:6]; 	
							command_to_L2      = Write_Out;    
							if(mode==1)			 
								$display("Return data to L2 %8h",address_in);
							lru_next(lrubits0, lrubits1, lrubits2, lrubits3,
							LRU[current_index][0],LRU[current_index][1], LRU[current_index][2],LRU[current_index][3],way_counter[1:0]);
							
							LRU[current_index][0] = lrubits0;
							LRU[current_index][1] = lrubits1; 
							LRU[current_index][2] = lrubits2;
							LRU[current_index][3] = lrubits3;
							Tag[current_index][way_counter]    = current_tag;
							MESI[current_index][way_counter]	  = SHARED;
							Finish                        = True;
						end
					end
				end
			end
		end
			
		  // Printing the contents of data cache
	  	  Print:
		  begin
				
				$display("========================================DATA CACHE CONTENTS====================================================\n");
				for (index_counter = 0; index_counter < `Sets; index_counter = index_counter+1)
					begin
			  		  if (MESI[index_counter][0]!=INVALID) 
					  begin
						$write(" SET:%4h | LRU:%d WAY:0 ",index_counter[`Index_Bits-1:0], LRU[index_counter][0]);
						if(MESI[index_counter][0]==1)
							$write("MESI: S ");
						else if(MESI[index_counter][0]==2)
							$write("MESI: E ");
						else if(MESI[index_counter][0]==3)
							$write("MESI: M ");
						$write(" TAG:%3h | ", MESI[index_counter][0]!=INVALID ? Tag[index_counter][0] : "");
					   end
					   
						if(MESI[index_counter][1]!=INVALID) 
						begin
						$write(" LRU:%d WAY:1 ", LRU[index_counter][1]);
						if(MESI[index_counter][1]==1)
							$write("MESI: S ");
						else if(MESI[index_counter][1]==2)
							$write("MESI: E ");
						else if(MESI[index_counter][1]==3)
							$write("MESI: M ");
						$write(" TAG:%3h |", MESI[index_counter][1]!=INVALID ? Tag[index_counter][1] : "");
						end 

						if(MESI[index_counter][2]!=INVALID)
						begin
						$write(" LRU:%d WAY:2 ", LRU[index_counter][2]);
					    if(MESI[index_counter][2]==1)
							$write("MESI: S ");
						else if(MESI[index_counter][2]==2)
							$write("MESI: E ");
						else if(MESI[index_counter][2]==3)
							$write("MESI: M ");
						$write(" TAG:%3h |", MESI[index_counter][2]!=INVALID ? Tag[index_counter][2] :"");
						end
						
						 if(MESI[index_counter][3]!=INVALID )
						 begin
						$write(" LRU:%d WAY:3 ", LRU[index_counter][3]);
						 if(MESI[index_counter][3]==1)
							$write("MESI: S ");
						else if(MESI[index_counter][3]==2)
							$write("MESI: E ");
						else if(MESI[index_counter][3]==3)
							$write("MESI: M ");
						$write("TAG:%3h \n", MESI[index_counter][3]!=INVALID ? Tag[index_counter][3] : "");
						end
						
					end
					$display("\n======================================END OF DATA CACHE CONTENTS===============================================\n");
				end			
		  
		  default: ; 
		endcase
	  end
	endmodule

