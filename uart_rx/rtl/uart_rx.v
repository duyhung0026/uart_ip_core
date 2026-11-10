`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: uart_rx
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


module uart_rx(
input  wire clk_i,
input  wire rst_n_i,
input  wire baud_tick_i,// 16x
input  wire rxd_i,

input  wire [1:0] char_len_sel_i,
input  wire parity_en_i,
input  wire even_parity_sel_i,
input  wire  stick_parity_en_i,

output reg rx_valid_o,
output reg [7:0] rx_data_o,
output reg rx_parity_err_o,
output reg rx_framing_err_o
);
localparam [2:0] S_IDLE   = 3'b000;
localparam [2:0] S_START  = 3'b001;
localparam [2:0] S_DATA   = 3'b010;
localparam [2:0] S_PARITY = 3'b011;
localparam [2:0] S_STOP   = 3'b100;

reg [2:0] current_state;
reg [2:0] next_state;

reg rxd_sync1, rxd_sync2,rxd_prev;
wire falling_edge = rxd_prev && !rxd_sync2;
reg [4:0] tick_cnt;
reg [3:0] bit_cnt;
reg [3:0] last_bit_idx;
reg [7:0] rsr_reg;
wire start_check_done = baud_tick_i && (tick_cnt == 5'd7);
wire sample_done      = baud_tick_i && (tick_cnt == 5'd15);


always @(*) begin
next_state = current_state;
case (current_state)
S_IDLE: begin
    if (falling_edge) next_state = S_START;
end
S_START: begin
    if (start_check_done) begin
        if (!rxd_sync2)
            next_state = S_DATA;
        else
            next_state = S_IDLE;
    end
end
S_DATA: begin
if (sample_done && (bit_cnt == last_bit_idx)) begin
    if (parity_en_i) next_state = S_PARITY;
    else             next_state = S_STOP;
end
end
S_PARITY: begin
if (sample_done) next_state = S_STOP;
end
S_STOP: begin
if (sample_done) next_state = S_IDLE;
end
default:  next_state = S_IDLE;
endcase
end

always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) current_state <= S_IDLE;
    else          current_state <= next_state;
end


always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
rxd_sync1 <= 1'b1;
rxd_sync2 <= 1'b1;
rxd_prev  <= 1'b1;
end else begin
rxd_sync1 <= rxd_i;
rxd_sync2 <= rxd_sync1;
rxd_prev  <= rxd_sync2;
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
    tick_cnt <= 5'd0;
else if (current_state == S_IDLE)
    tick_cnt <= 5'd0;
else if (baud_tick_i) begin
if ((current_state == S_START && start_check_done) ||
    (current_state != S_START && sample_done))
    tick_cnt <= 5'd0;
else
    tick_cnt <= tick_cnt + 1'b1;
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
    bit_cnt <= 4'd0;
    rsr_reg <= 8'd0;
end else if (current_state == S_START) begin
    bit_cnt <= 4'd0;
    rsr_reg <= 8'd0;
end else if (current_state == S_DATA && sample_done) begin
    rsr_reg[bit_cnt[2:0]] <= rxd_sync2;
    bit_cnt <= bit_cnt + 1'b1;
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
    last_bit_idx <= 4'd7;
else if (current_state == S_IDLE)
    last_bit_idx <= char_len_sel_i + 4'd4;
end

reg  parity_err_reg;
wire expected_parity = stick_parity_en_i ? ~even_parity_sel_i
                     : (even_parity_sel_i ? ^rsr_reg : ~^rsr_reg);

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i)
    parity_err_reg <= 1'b0;
else if (current_state == S_START)
    parity_err_reg <= 1'b0;
else if (current_state == S_PARITY && sample_done)
    parity_err_reg <= (rxd_sync2 != expected_parity);
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
    rx_valid_o       <= 1'b0;
    rx_data_o        <= 8'd0;
    rx_parity_err_o  <= 1'b0;
    rx_framing_err_o <= 1'b0;
end else begin
rx_valid_o <= 1'b0;
if (current_state == S_STOP && sample_done) begin
     rx_valid_o <= 1'b1;
     rx_data_o <= rsr_reg;
     rx_parity_err_o <= parity_err_reg;
     rx_framing_err_o <= !rxd_sync2;
end
end
end
endmodule
