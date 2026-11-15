`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: baud_gen_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module baud_gen_tb;
reg clk = 0;
reg rst_n = 0;
reg [15:0] divisor = 16'd434;
wire tick;

always #5 clk = ~clk;

baud_gen dut (
.clk_i      (clk),
.rst_n_i    (rst_n),
.dlr_lsb_i  (divisor[7:0]),
.dlr_msb_i  (divisor[15:8]),
.baud_tick_o(tick)
);
integer checks = 0;
integer fails  = 0;

task check(input [8*40-1:0] name, input integer got, input integer exp);
begin
checks = checks + 1;
if (got !== exp) begin
fails = fails + 1;
$display("[FAIL] %0s: got %0d, exp %0d", name, got, exp);
end
end
endtask

task set_divisor(input [15:0] d);
begin
@(negedge clk);
divisor = d;
end
endtask

integer gap_min, gap_max;
task measure_gaps(input integer skip, input integer n);
integer clk_no, last_tick_clk, tick_no;
begin
gap_min = 1 << 30;
gap_max = 0;
clk_no = 0;  last_tick_clk = 0;  tick_no = 0;
while (tick_no < skip + 1 + n) begin
@(posedge clk);
clk_no = clk_no + 1;
if (tick) begin
if (tick_no > skip) begin
if (clk_no - last_tick_clk < gap_min) gap_min = clk_no - last_tick_clk;
if (clk_no - last_tick_clk > gap_max) gap_max = clk_no - last_tick_clk;
end
last_tick_clk = clk_no;
tick_no = tick_no + 1;
end
end
end
endtask

task check_period(input [8*40-1:0] name, input [15:0] d, input integer exp_clks);
begin
set_divisor(d);
measure_gaps(2, 6);
check({name, " (min gap)"}, gap_min, exp_clks);
check({name, " (max gap)"}, gap_max, exp_clks);
end
endtask

task check_reprogram(input [8*40-1:0] name, input [15:0] from, input [15:0] to);
integer i, quiet, quiet_max;
begin
set_divisor(from);
repeat (3007) @(posedge clk);
set_divisor(to);
quiet = 0;  quiet_max = 0;
for (i = 0; i < 6000; i = i + 1) begin
@(posedge clk);
quiet = tick ? 0 : quiet + 1;
if (quiet > quiet_max) quiet_max = quiet;
end
check({name, " (stall <= new period)"}, quiet_max <= (to >> 4), 1);
end
endtask

initial begin
#22 rst_n = 1;

check_period("div 434 (reset value)", 16'd434, 27);
check_period("div 64", 16'd64, 4);
check_period("div 32", 16'd32, 2);
check_period("div 1600", 16'd1600, 100);
check_period("div 65535 (max)", 16'hFFFF, 4095);
check_period("div 16 (fastest legal)", 16'd16, 1);
check_period("div 17", 16'd17, 1);
check_period("div 31", 16'd31, 1);
check_period("div 15 (illegal)", 16'd15, 1);
check_period("div 0 (illegal)", 16'd0, 1);

set_divisor(16'd160);
@(posedge clk);  
while (!tick) @(posedge clk);
@(posedge clk);
check("tick width 1 clk", tick, 0);

check_reprogram("4080 -> 64",   16'd4080, 16'd64);
check_reprogram("1600 -> 32",   16'd1600, 16'd32);
check_reprogram("64 -> 1600",   16'd64, 16'd1600);

rst_n = 0;  #1;
check("tick low in reset", tick, 0);

if (fails == 0) $display("ALL TESTS PASSED (%0d checks)", checks);
else $display("TEST FAILED: %0d / %0d checks failed", fails, checks);
$finish;
end

initial begin
#500_000_000;
$display("TIMEOUT");
$finish;
end
endmodule
