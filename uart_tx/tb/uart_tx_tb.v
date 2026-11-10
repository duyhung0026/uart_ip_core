`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: uart_tx_tb
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


module uart_tx_tb;
reg  clk_i;
reg  rst_n_i;
reg  [1:0] char_len_sel_i;
reg  stop_bit_ctrl_i;
reg  parity_en_i;
reg  even_parity_sel_i;
reg  stick_parity_en_i;
reg  break_ctrl_en_i;

reg thr_wr_i;
reg  [7:0] thr_data_i;

reg  [7:0] dlr_msb_i;
reg  [7:0] dlr_lsb_i;


wire baud_tick_i;
wire thr_empty_o;
wire xmitr_empty_o;
wire tx_ready_n_o;
wire txd_o;

baud_gen u_baud_gen (
.clk_i (clk_i),
.rst_n_i (rst_n_i),
.dlr_msb_i (dlr_msb_i),
.dlr_lsb_i (dlr_lsb_i),
.baud_tick_o (baud_tick_i)
);
uart_tx dut (
.clk_i (clk_i),
.rst_n_i (rst_n_i),
.baud_tick_i (baud_tick_i),
.char_len_sel_i (char_len_sel_i),
.stop_bit_ctrl_i (stop_bit_ctrl_i),
.parity_en_i (parity_en_i),
.even_parity_sel_i (even_parity_sel_i),
.stick_parity_en_i (stick_parity_en_i),
.break_ctrl_en_i (break_ctrl_en_i),
.thr_wr_i (thr_wr_i),
.thr_data_i (thr_data_i),
.thr_empty_o (thr_empty_o),
.xmitr_empty_o (xmitr_empty_o),
.tx_ready_n_o (tx_ready_n_o),
.txd_o (txd_o)
);
initial clk_i = 1'b0;
always #5 clk_i = ~clk_i;
task send_byte;
input [1:0] len_sel;
input [7:0] data;
input stop_ctrl;
begin
@(negedge clk_i);
char_len_sel_i = len_sel;
thr_data_i     = data;
stop_bit_ctrl_i = stop_ctrl;
thr_wr_i       = 1'b1;

@(negedge clk_i);
thr_wr_i       = 1'b0;

wait (xmitr_empty_o == 1'b1);
#200000;
end
endtask
initial begin
rst_n_i           = 1'b0;
char_len_sel_i    = 2'b11;
stop_bit_ctrl_i   = 1'b0;
parity_en_i       = 1'b0;
even_parity_sel_i = 1'b0;
stick_parity_en_i = 1'b0;
break_ctrl_en_i   = 1'b0;
thr_wr_i          = 1'b0;
thr_data_i        = 8'h00;
// 100 MHz / 9600 baud -> divisor = 10417 = 0x28B1
dlr_msb_i = 8'h28;
dlr_lsb_i = 8'hB1;

#20;
rst_n_i = 1'b1;
#20000;

// 5-bit data
send_byte(2'b00, 8'hA5, 1'b0);   // 5 bit, 1 stop bit
send_byte(2'b00, 8'h15, 1'b1);   // 5 bit, 1.5 stop bits

// 6-bit data
send_byte(2'b01, 8'h15, 1'b0);   // 6 bit, 1 stop bit
send_byte(2'b01, 8'h15, 1'b1);   // 6 bit, 2 stop bits

// 7-bit data
send_byte(2'b10, 8'hAA, 1'b0);   // 7 bit, 1 stop bit
send_byte(2'b10, 8'hAA, 1'b1);   // 7 bit, 2 stop bits

// 8-bit data
send_byte(2'b11, 8'h3B, 1'b0);   // 8 bit, 1 stop bit
send_byte(2'b11, 8'h3B, 1'b1);   // 8 bit, 2 stop bits

$finish;
end
endmodule
