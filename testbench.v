 /////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// testbench.v - Testbench to implement the cache system
//
/////////////////////////////////////////////////////////////////////////////////////////

module testbench();
 
  parameter clock_period  = 20;
  parameter half_period  = clock_period/2;
  
  parameter TRUE   = 1'b1;
  parameter FALSE  = 1'b0;

  reg Clock;
  integer file;     
  reg  Finish;
  
  reg  [3:0]        command;
  reg  [31:0]       address;
  reg  [9000:0]     filename;
  wire [25:0]       addr_to_L2;
  wire [1:0]        command_to_L2;
  reg        mode;


  top_level_integration project(
	  .Clock(Clock),
	  .clear(clear),
	  .n(command),
	  .address_in(address),
	  .Finish(Finish),
	  .addr_to_L2(addr_to_L2),
	  .command_to_L2(command_to_L2),
	  .mode(mode)); 
	  
		L2_cache_commands l2_commands(
		.address_in(addr_to_L2),
		.command_in(command_to_L2)
  ); 

  initial
  begin
	 Clock=FALSE;
	 Finish=FALSE;
	 
	 if ($value$plusargs("Input_Trace=%s", filename) == FALSE)          
	   begin        
	   $display("Error: No tracefile provided");        
	   $stop;
	 end
	 
	 if ($value$plusargs("mode=%d", mode)== TRUE)
	// begin
	 // $display();
	 //end

 	 file = $fopen(filename, "r");
	
	 #half_period Clock = FALSE; 
	 command = 4'd8;  
	 #half_period Clock = TRUE; 
	

	 while (!$feof(file)) 
	 begin
		#half_period Clock = FALSE;
		$fscanf (file, "%d", command);
		if (command!==9)
        begin
          $fscanf (file, "%h", address);
		//  $display();
        end
		else
		$display();
		#half_period Clock= TRUE;
	 end
	 $fclose(file);
	 Finish = TRUE;
  end 
endmodule
