
module ViterbiDecoder#
(parameter n = 2, 
parameter k = 1, 
parameter m = 4, 
parameter L = 7)
(
	clk,
	reset,
	restart,
	enable,
	encoded,
	decoded,
	error,
	ready,
	load,
	state_address,
	input_address,
	next_state_data,
	output_data
);
////////////////////Calculating maxvalue/////////////////////
function integer clog2;
input integer value;
begin
value = value-1;
for (clog2=0; value>0; clog2=clog2+1) value = value>>1;
end
endfunction
localparam E = clog2(L*n);
integer max=(2**E)-1;
///////////////////////Inputs//////////////////////
input clk, reset, restart, enable, load;
input [0:m-k-1] state_address;
input [0:m-k-1] next_state_data;
input [0:k-1]input_address; 
input [0:n-1]output_data;
input [0:n-1] encoded;
/////////////////////////////////////////////////

/////////////////outputs////////////////
output [0:k*L-1] decoded;
output ready;
output [0:E] error;
///////////////memory Part//////////////////
reg [0:E-1] ErrorTable [0:2**(m-k)-1][0:L];
reg [0:(m-k-1)]HistoryTable [0:2**(m-k)-1][0:L];
reg [0:(m-k-1)]StateTable[0:2**(m-k)-1][0:(2**k)-1];
reg [0:n-1] OutputTable [0:2**(m-k)-1][0:(2**k)-1];
/////////////////////////////////////////////////////

///////////////////HistoryTable/////////////////////
reg  [0:2**(m-k)-1] CurrentState;
reg [0:2**(m-k)-1] NextState;
integer HistoryTableIndex=0;
//////////////////////////////
integer nextState_output;
///////////////integers for loops//////////////////
integer i;
integer j;
integer f;
/////////////////////////////////////////////////

///////////////////Temporary///////////////////
integer ERROR_Temp;
integer NextState_temp;
reg [0:n-1] tempOutput;
reg [0:E] Error_temp;
/////////////////////////backtracking/////////
integer min_error_index;
integer outputBit;
reg [0:k*L-1] FinalOutput;
integer ready_temp;
//////////////////////////////////////////

always @(posedge clk) begin
	if(reset)begin
		for(i=0;i<2**(m-k);i=i+1)begin
			for(j=0;j<2**(k);j=j+1)begin
				StateTable[i][j] = 0;
				OutputTable[i][j] = 0;
			end
			for(f=0;f<=L;f=f+1)begin
				HistoryTable[i][f] = 0;
				ErrorTable[i][f] = (2**E)-1;
			end
		end
		ErrorTable[0][0] = 0;
		CurrentState=0;
		CurrentState[0]=1;
		NextState=0;
		
	end
	else if (restart) begin
		for(i=0;i<2**(m-k);i=i+1)begin
			for(f=0;f<=L;f=f+1)begin
				HistoryTable[i][f] = 0;
				ErrorTable[i][f] = (2**E)-1;
			end
		end
		ErrorTable[0][0] = 0;
		CurrentState=0;
		CurrentState[0]=1;
		NextState=0;
	end	
	else if(load)begin
		StateTable[state_address][input_address] = next_state_data ;
		OutputTable[state_address][input_address] = output_data;
	end
	else if (enable) begin
		for (i=0;i<2**(m-k);i=i+1)begin
			if(CurrentState[i]==1)begin
				for(j=0;j<2**k;j=j+1)begin
					NextState_temp=StateTable[i][j];
					ERROR_Temp=ErrorTable[i][HistoryTableIndex];
					tempOutput=OutputTable[i][j];
					for (f=0; f<n; f=f+1) begin
						ERROR_Temp = ERROR_Temp + (encoded[f] ^ tempOutput[f]);
					end
					if (ERROR_Temp < ErrorTable[NextState_temp][HistoryTableIndex+1]) begin
						NextState[NextState_temp]=1;
						ErrorTable[NextState_temp][HistoryTableIndex+1] = ERROR_Temp;
						HistoryTable[NextState_temp][HistoryTableIndex+1]= i;
					end
				end
			end
		end
		HistoryTableIndex=HistoryTableIndex+1;
		if(HistoryTableIndex==L) begin
			ready_temp=1;
		end
		CurrentState=NextState;
	end
		else if(ready_temp) begin
			for(i=0;i<2**(m-k);i=i+1) begin
				if(ErrorTable[i][L]<max) begin
					max=ErrorTable[i][L];
					min_error_index=i;
					Error_temp=max;
				end
			end
			for(i=L-1;i>=0;i=i-1) begin	
				nextState_output=HistoryTable[min_error_index][i+1];
				for(j=0;j<2**k;j=j+1) begin 
					if(StateTable[nextState_output][j]==min_error_index) begin
						outputBit=j;
						min_error_index=HistoryTable[min_error_index][i+1];
						FinalOutput[i*k+:k-1]=outputBit;
					end
				end
					
			end
		end


end
assign error=Error_temp;
assign ready=ready_temp;
assign decoded=FinalOutput;
endmodule
