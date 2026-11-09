`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: rx_buf
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


module rx_buf(
input  wire clk_i,
input  wire rst_n_i,

input  wire rx_valid_i,
input  wire [7:0] rx_data_i,
input  wire rx_parity_err_i,
input  wire rx_framing_err_i,

input  wire  rbr_rd_i,
input  wire lsr_rd_i,

output reg  [7:0] rbr_data_o,// RBR
output wire data_rdy_o,// LSR[0]
output reg overrun_err_o,// LSR[1]
output reg parity_err_o,// LSR[2]
output reg framing_err_o,// LSR[3]
output wire rx_ready_n_o
);

reg data_rdy;
wire accept = rx_valid_i && !data_rdy;
always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
rbr_data_o <= 8'h00;
data_rdy   <= 1'b0;
end
else if (accept) begin
rbr_data_o <= rx_data_i;
data_rdy   <= 1'b1;
end
else if (rbr_rd_i) begin
data_rdy <= 1'b0;
end
end


assign data_rdy_o   = data_rdy;
assign rx_ready_n_o = ~data_rdy;

wire overrun = rx_valid_i && data_rdy;
always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
overrun_err_o <= 1'b0;
else if (overrun)
overrun_err_o <= 1'b1;
else if (lsr_rd_i)
overrun_err_o <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
parity_err_o <= 1'b0;
else if (accept && rx_parity_err_i)
parity_err_o <= 1'b1;
else if (lsr_rd_i)
parity_err_o <= 1'b0;
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
framing_err_o <= 1'b0;
else if (accept && rx_framing_err_i)
framing_err_o <= 1'b1;
else if (lsr_rd_i)
framing_err_o <= 1'b0;
end

endmodule
