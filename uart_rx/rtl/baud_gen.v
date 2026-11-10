`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: baud_gen
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


module baud_gen (
input  wire clk_i,
input  wire rst_n_i,
// Divisor Latch Register (DLR)
input  wire [7:0] dlr_lsb_i,
input  wire [7:0] dlr_msb_i,
// Baud tick output (16x baud rate)
output reg baud_tick_o);
wire [15:0] divisor;
wire [11:0] threshold;
reg  [11:0] baud_cnt;
always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
baud_cnt   <= 12'd0;
baud_tick_o <= 1'b0;
end
else begin
baud_tick_o <= 1'b0;
if (baud_cnt == threshold) begin
baud_cnt    <= 12'd0;
baud_tick_o <= 1'b1;
end
else begin
baud_cnt <= baud_cnt + 1'b1;
end

end
end

assign divisor   = {dlr_msb_i, dlr_lsb_i};
assign threshold = (divisor >> 4) - 1'b1;
endmodule
