//////////////////////////////////////////////////////////////////////////////////
// Org:        	FNAL
// Author:      Quan Sun
// 
// Create Date:    Wed Jul 08 2020
// Design Name:    ETROC2 
// Module Name:    ts_scurve
// Project Name: 
// Description: threshold scan for s-curve approach
//
// Dependencies: 
//
// Revision: 
//
//
//////////////////////////////////////////////////////////////////////////////////
`define AccumulatorBit 12
module ts_scurve(
	CLK,
	RSTn,
        DiscriPul,
	CMD,
	QinjPul,
	Acc,
	ScanBusy
);
input CLK;				// 40 MHz clock
input RSTn;				// synchronous reset for some of registers, active low
input DiscriPul;			// from discriminator 
output QinjPul;				// charge injection pulse.
input [7:0] CMD;			// command from I2C, a falling edge at CMD[7] initializes the scan when CMD[6:0] == 6'b0011001
output [`AccumulatorBit-1:0] Acc;
output ScanBusy;

reg [`AccumulatorBit-1:0] AccReg;	// internal accumulator register
//reg [`AccumulatorBit-1:0] CounterAcc;	// counter for accumulation	
reg [7:0] CMD_reg;			// sampled command
reg ScanInit;				// bit helping to initialize scan 
reg ScanBusy;				// if a scan is onging, ScanBusy == 1;

reg [1:0] Counter_CLK;			// clock driven counter, used to generate QinjPul
reg [`AccumulatorBit + 2:0] Counter_Qinj;	// QinjPul driven counter, used to define the accumulation window
reg DiscriExt;				// extended discriminator pulse
reg SamplePul;				// sampling pulse

wire RSTn_int;				// synchronous reset for some of registers, active low
wire RSTn_int0;				// synchronous reset for RSTn_int counter

reg [3:0] Counter_Rst;			// counter for generating RSTn_int
wire clk_int;				// gated clock

assign clk_int = CLK & CMD[0];		// LSB of CMD gates the clock
assign DiscriPul_int = DiscriPul & CMD[0];	// LSB of CMD gates the DiscriPul

assign RSTn_int0 = !CMD[7];			// positive pulse reset the Counter_Rst 
assign RSTn_int = (Counter_Rst == 15)?1:0;

always@(posedge clk_int) begin
if(!RSTn_int0) begin
	Counter_Rst <= 0;
end
else begin
	if(Counter_Rst != 15)
		Counter_Rst <= Counter_Rst + 1;	
end
end

always@(posedge clk_int) begin		// sampling the command from I2C
if (!RSTn) begin
	CMD_reg <= 0;
	ScanInit <= 0;
end
else begin
	CMD_reg <= CMD;
	ScanInit <= CMD_reg[7];
end
end

always@(posedge clk_int) begin
if(!RSTn_int)
	Counter_Qinj <= 0;
else begin
	if(ScanBusy==1)
		Counter_Qinj <= Counter_Qinj + 1;
end
end

always@(posedge clk_int) begin		// initialization a scan
if (!RSTn) begin
	ScanBusy <= 0;
end
else begin
	if(ScanInit == 1'b1 &&  CMD_reg[7] == 1'b1 &&  CMD_reg[6:0] == 7'b0011001)
		ScanBusy <= 1;
	else 
		if(Counter_Qinj == 32767)
			ScanBusy <= 0;
end
end

assign QinjPul = Counter_CLK[1];		// generating Counter_CLK
always@(posedge clk_int) begin
if (!RSTn_int) 
	Counter_CLK <= 3;
else begin
	Counter_CLK <= Counter_CLK - 1;
end
end

always@(negedge QinjPul or posedge DiscriPul_int) begin	//extending the discriminator pulse
if(!QinjPul)
	DiscriExt <= 0;
else
	DiscriExt <= DiscriPul_int;
end

always@(negedge Counter_CLK[0]) begin	// generating the sampling pulse
if(!RSTn_int) 
	SamplePul <= 0;
else
	if(Counter_CLK[1]==1)
		SamplePul <= 1;
	else
		SamplePul <= 0;
end

assign Acc = AccReg;
always@(negedge RSTn_int or posedge SamplePul) begin
if(!RSTn_int) 
	AccReg <= 0;
else if(ScanBusy)
	AccReg <= AccReg + DiscriExt;
end


endmodule
