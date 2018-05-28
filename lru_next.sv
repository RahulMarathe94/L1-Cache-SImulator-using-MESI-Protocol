/////////////////////////////////////////////////////////////////////////////////////////
// Authors - Abhishek T Memane, Rahul Marathe, Shubham Lokhande
// lru_next.v - A task has been defined to compute the LRU bits of L1 Data Cache
//
/////////////////////////////////////////////////////////////////////////////////////////

task lru_next(output reg  [1:0] lru_bits0, lru_bits1, lru_bits2, lru_bits3, input reg [1:0] lrubits0, lrubits1, lrubits2, lrubits3,
				input reg [1:0] way_cnt);

begin
		case(way_cnt)
		2'd0: begin
			if(lrubits1<lrubits0)begin
				lru_bits1=lrubits1+1'b1;
				
				end
			else begin
				lru_bits1=lrubits1;
				
				end
			if(lrubits2<lrubits0) begin
				lru_bits2=lrubits2+1'b1;
				
				end
			else begin
				lru_bits2=lrubits2;
				
				end
			if(lrubits3<lrubits0) begin
				lru_bits3=lrubits3+1'b1;
				
				end
			else begin
				lru_bits3=lrubits3;
				
			end
			lru_bits0=2'b00;
			
			end

		2'd1: begin
			if(lrubits0<lrubits1)begin
				lru_bits0=lrubits0+1'b1;
				
				end
			else begin
				lru_bits0=lrubits0;
				
				end
			if(lrubits2<lrubits1) begin
				lru_bits2=lrubits2+1'b1;
				
				end
			else begin
				lru_bits2=lrubits2;
				
				end
			if(lrubits3<lrubits1) begin
				lru_bits3=lrubits3+1'b1;
				
				end
			else begin
				lru_bits3=lrubits3;
				
			end
			lru_bits1=2'b00;
			
			end

		2'd2: begin
			if(lrubits0<lrubits2)begin
				lru_bits0=lrubits0+1'b1;
				
				end
			else begin
				lru_bits0=lrubits0;
				
				end
			if(lrubits1<lrubits2) begin
				lru_bits1=lrubits1+1'b1;
				
				end
			else begin
				lru_bits1=lrubits1;
				
				end
			if(lrubits3<lrubits2) begin
				lru_bits3=lrubits3+1'b1;
				
				end
			else begin
				lru_bits3=lrubits3;
				
			end
			lru_bits2=2'b00;
			
			end

		2'd3: begin
			if(lrubits0<lrubits3)begin
				lru_bits0=lrubits0+1'b1;
				
				end
			else begin
				lru_bits0=lrubits0;
				
				end
			if(lrubits2<lrubits3) begin
				lru_bits2=lrubits2+1'b1;
				
				end
			else begin
				lru_bits2=lrubits2;
				
				end
			if(lrubits1<lrubits3) begin
				lru_bits1=lrubits1+1'b1;
				
				end
			else begin
				lru_bits1=lrubits1;
				
			end
			lru_bits3=2'b00;
			
			end
		endcase
	end				
endtask			
				