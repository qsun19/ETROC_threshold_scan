//////////////////////////////////////////////////////////////////////////////////
// Org:        	FNAL
// Author:      Quan Sun
// 
// Create Date:    Fri Jul 10 2020
// Design Name:    ETROC2 
// Module Name:    ts_scurve_tb
// Project Name: 
// Description: testbench for threshold scan for s-curve approach
//
// Dependencies: 
//
// Revision: 
//
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ps / 10fs

module ts_scurve_tb();
reg clk40M;
reg clk4000M;
reg DiscriPul;
wire QinjPul;
integer TH;					// threshold
reg RSTn;
reg [7:0] CMD;					// command from I2C

wire [11:0] Acc;				
wire ScanBusy;


real bl;					// baseline
real seed, mean, standard_deviation;		// parameter for baseline generation
real ampl;					// amplitude due to charge injection
real peak;					// peak of the preamp signal

initial begin
clk40M = 0;
clk4000M = 0;
DiscriPul = 0;
//QinjPul = 0;
TH = 420000;
seed = 11;
mean = 399000;					// in DAC
standard_deviation = 1000;				// in DAC
bl = 399000;					// in DAC
ampl = 20000;					// in DAC

RSTn = 1;

CMD = 8'b00011001;				// 

#100000
RSTn = 0;

#100000
RSTn = 1;

#10000
CMD = 8'b10011001;				// 

#100000
CMD = 8'b00011001;				// 

#1000000000 
$finish();
end

always #12500 clk40M = ~clk40M;
always #125 clk4000M = ~clk4000M;
//always #50000 QinjPul = ~QinjPul;

always@(posedge clk4000M) begin
bl<=$dist_normal (seed, mean, standard_deviation) ;
end



always@(posedge QinjPul) begin
peak = ampl+bl;
if(peak>TH) begin
	# 1250 DiscriPul = 1;
	# 2500 DiscriPul = 0;
end
else
	DiscriPul = 0;
end

integer AccRef;
always@(negedge RSTn or posedge DiscriPul) begin
if(!RSTn)
	AccRef = 0;
else if(ScanBusy)
	AccRef = AccRef + 1;
end

ts_scurve ts_scurve_instts_scurve(
	.CLK(clk40M),
	.RSTn(RSTn),
        .DiscriPul(DiscriPul),
	.CMD(CMD),
	.QinjPul(QinjPul),
	.Acc(Acc),
	.ScanBusy(ScanBusy)
);

endmodule
