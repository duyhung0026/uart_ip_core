`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 08:41:42 PM
// Design Name: 
// Module Name: rx_top
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


module rx_top(
// System signals
input  wire clk_i,
input  wire rst_n_i,
// UART RX interface
input  wire baud_tick_i,
input  wire rxd_i,
// UART configuration
input  wire [1:0] char_len_sel_i,
input  wire parity_en_i,
input  wire even_parity_sel_i,
input  wire stick_parity_en_i,
// Register read control
input  wire rbr_rd_i,
input  wire lsr_rd_i,
// RBR output
output wire [7:0] rbr_data_o,
// LSR output
output wire data_rdy_o,
output wire overrun_err_o,
output wire parity_err_o,
output wire framing_err_o,
// RX ready
output wire rx_ready_n_o
);
// Internal signals between UART RX and RX Buffer
wire rx_valid;
wire [7:0] rx_data;
wire rx_parity_err;
wire rx_framing_err;

uart_rx u_uart_rx (
.clk_i (clk_i),
.rst_n_i (rst_n_i),
.baud_tick_i (baud_tick_i),
.rxd_i (rxd_i),

.char_len_sel_i (char_len_sel_i),
.parity_en_i (parity_en_i),
.even_parity_sel_i (even_parity_sel_i),
.stick_parity_en_i (stick_parity_en_i),

.rx_valid_o (rx_valid),
.rx_data_o (rx_data),
.rx_parity_err_o (rx_parity_err),
.rx_framing_err_o (rx_framing_err)
);

rx_buf u_rx_buf (
.clk_i (clk_i),
.rst_n_i (rst_n_i),

.rx_valid_i (rx_valid),
.rx_data_i (rx_data),
.rx_parity_err_i (rx_parity_err),
.rx_framing_err_i (rx_framing_err),

.rbr_rd_i (rbr_rd_i),
.lsr_rd_i (lsr_rd_i),

.rbr_data_o (rbr_data_o),
.data_rdy_o (data_rdy_o),
.overrun_err_o (overrun_err_o),
.parity_err_o (parity_err_o),
.framing_err_o (framing_err_o),
.rx_ready_n_o (rx_ready_n_o)
);
endmodule
