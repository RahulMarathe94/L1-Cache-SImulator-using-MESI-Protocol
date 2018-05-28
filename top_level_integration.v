/////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// top_level_integration.v - Integrates all modules
//
/////////////////////////////////////////////////////////////////////////////////////////

module top_level_integration(
 // Outputs
  output reg [25:0] addr_to_L2,
  output reg [1:0]  command_to_L2,
  input mode, 
  
  // Inputs
  input Clock, 
  input clear, 
  input [3:0] n, 
  input [31:0] address_in,
  input Finish);  
  
  // For statistics module
  wire [31:0] data_hit;
  wire [31:0] data_miss;
  wire [31:0] data_reads;
  wire [31:0] data_writes;
  wire [31:0] instr_hit; 
  wire [31:0] instr_miss;  
  wire [31:0] instr_reads;
  
  // Commands from tracefile
  parameter Reset       = 4'd8;
  parameter Invalidate  = 4'd3;
  parameter Read        = 4'd0;
  parameter Write       = 4'd1;
  parameter Instruction_Fetch 	= 4'd2;
  parameter Print       = 4'd9;
parameter Snoop         =4'd4;
  
  // Communication between L1 and L2 caches
  wire [1:0]   l2_i_cmd, l2_d_cmd;
  wire [25:0]  l2_i_add,  l2_d_add;
  
  // signals from file to caches
  wire [31:0] i_add, d_add;
  
  assign i_add = address_in;
  assign d_add = address_in;

  //Mux the commands accordingly to L2 cache
  always @(n)
  begin
		if(n == Instruction_Fetch)
		begin
			addr_to_L2 = l2_i_add;
			command_to_L2 = l2_i_cmd;
		end
		else
		begin
			addr_to_L2 = l2_d_add;
			command_to_L2 = l2_d_cmd;
		end
	end

	data_cache data_cache (
		.n(n), 
		.address_in(address_in), 
		.Clock(Clock), 
		.addr_to_L2(l2_d_add), 
		.command_to_L2(l2_d_cmd), 
		.hit(data_hit), 
		.miss(data_miss), 
		.reads(data_reads), 
		.writes(data_writes),
		.mode(mode)); 
		
	instruction_cache instr_cache (
	.Clock(Clock), 
		.n(n), 
		.address_in(address_in), 
		.addr_to_L2(l2_i_add),  
		.command_to_L2(l2_i_cmd),  
		.hit(instr_hit), 
		.miss(instr_miss),
		.reads(instr_reads),
		.mode(mode)); 

	statistics stats(
		.print(Finish),
		.ins_reads(instr_reads),
		.ins_hit(instr_hit),
		.ins_miss(instr_miss),
		.data_reads(data_reads),
		.data_writes(data_writes),
		.data_hit(data_hit),
		.data_miss(data_miss)
		);

endmodule
