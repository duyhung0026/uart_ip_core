`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: uart_tx
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

module uart_tx(
input  wire clk_i,
input  wire rst_n_i,

// Baud tick - baud gen
// oversample x16, UART 16450
input  wire baud_tick_i,

//cofig LCR
input  wire [1:0] char_len_sel_i,   // 00=5bit,01=6bit,10=7bit,11=8bit
input  wire stop_bit_ctrl_i,  // 0=1 stop bit, 1=1.5/2 stop bit (theo char_len)
input  wire parity_en_i,
input  wire even_parity_sel_i,// 0=odd, 1=even
input  wire stick_parity_en_i,
input  wire break_ctrl_en_i,  // push txd_o = 0

// write data THR
input  wire thr_wr_i,         // 1 clk when write possible
input  wire [7:0] thr_data_i,       // data write

// state output for LSR
output wire thr_empty_o,      // = LSR.thr_empty
output wire xmitr_empty_o,    // = LSR.xmitr_empty
output wire tx_ready_n_o,     // auxiliary signal

output reg txd_o
);
localparam [2:0] S_IDLE = 3'b000;
localparam [2:0] S_LOAD = 3'b001;
localparam [2:0] S_START = 3'b010;
localparam [2:0] S_DATA = 3'b011;
localparam [2:0] S_PARITY = 3'b100;
localparam [2:0] S_STOP = 3'b101;

localparam [4:0] TICKS_PER_BIT = 5'b10000;

reg [2:0] current_state;
reg [2:0] next_state;

reg [7:0] thr_reg;
reg thr_valid;
reg [7:0] tsr_reg;
reg [3:0] bit_cnt;
reg [4:0] tick_cnt;
reg [3:0] last_bit_idx;
reg parity_bit_reg;

wire tick_done;
wire [7:0] data_mask = (8'b00000001 <<(last_bit_idx+4'b0001))-8'b00000001;
//example data 5 bits:
//last_bit_idx=4 => 4+1 =5 => push bit 1: 8'b00100000-1'b1=8'b00011111
wire [7:0] data_masked = thr_reg & data_mask;
reg [4:0] stop_ticks_needed;
wire xor_result = ^data_masked;
wire [4:0] current_threshold = (current_state == S_STOP) ? stop_ticks_needed : (TICKS_PER_BIT - 1);

always@(*) begin
next_state=current_state;
case(current_state)
S_IDLE: begin
if(thr_valid) next_state=S_LOAD;
end
S_LOAD: begin
next_state=S_START;
end
S_START: begin
if(baud_tick_i&&tick_done)
next_state=S_DATA;
end
S_DATA: begin
if(baud_tick_i&&tick_done&&(bit_cnt==last_bit_idx)) begin
if (parity_en_i)
next_state = S_PARITY;
else
next_state=S_STOP;
end
end
S_PARITY: begin
    if(baud_tick_i&&tick_done)
        next_state = S_STOP;
end
S_STOP: begin
if(baud_tick_i&&tick_done) begin
if(thr_valid) 
next_state=S_LOAD;
else 
next_state= S_IDLE;
end
end
default: next_state=S_IDLE;
endcase
end

always@ (posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i)
current_state<=S_IDLE;
else
current_state<=next_state;
end

always@(posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i)
tick_cnt<=5'b0;
else begin
case(current_state)
S_START,S_DATA,S_PARITY,S_STOP: begin
if (baud_tick_i) begin
if(tick_done)                           
tick_cnt<=5'b0;
else
tick_cnt<=tick_cnt+1'b1;
end
end
default: tick_cnt<=5'b0;
endcase
end
end

always@(posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i) 
bit_cnt<=4'b0;
else begin
case(current_state)
S_LOAD: bit_cnt <= 4'b0;
S_DATA: begin
if(baud_tick_i && tick_done)
bit_cnt<=bit_cnt+1'b1;
end
default: bit_cnt<=bit_cnt;
endcase
end
end

always@(posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i) begin
last_bit_idx <= 4'b111;
end else begin
if(current_state==S_LOAD)
last_bit_idx <= char_len_sel_i +4'b100; 
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
 thr_reg   <= 8'b0;
thr_valid <= 1'b0;
end else begin
if (thr_wr_i&&!thr_valid) begin
thr_reg   <= thr_data_i;
thr_valid <= 1'b1;
end else if (current_state==S_LOAD) begin
thr_valid <=1'b0;
end
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
tsr_reg <= 8'b0;
end else begin
case (current_state)
S_LOAD: tsr_reg <= thr_reg;
S_DATA: begin
if (baud_tick_i && tick_done)
tsr_reg <= {1'b1,tsr_reg[7:1]};
end 
endcase
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
txd_o <= 1'b1;
end else if (break_ctrl_en_i) begin
txd_o <= 1'b0;             
end else begin
case (current_state)
S_IDLE:  txd_o <= 1'b1;
S_LOAD:  txd_o <= 1'b1;
S_START: txd_o <= 1'b0;         
S_DATA:  txd_o <= tsr_reg[0]; 
S_PARITY: txd_o <= parity_bit_reg;  
S_STOP:  txd_o <= 1'b1;         
default: txd_o <= 1'b1;
endcase
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if(!rst_n_i) begin
parity_bit_reg <= 0;
end else begin
if(current_state==S_LOAD) begin
parity_bit_reg <= stick_parity_en_i?(even_parity_sel_i?1'b0:1'b1):(even_parity_sel_i?xor_result:~xor_result);
end
end
end

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin
stop_ticks_needed <= 5'd15;
end else begin
if (current_state == S_LOAD) begin
if (!stop_bit_ctrl_i)
stop_ticks_needed <= 5'd15;
else if (char_len_sel_i == 2'b00)
stop_ticks_needed <= 5'd23;
else
stop_ticks_needed <= 5'd31;
end
end
end

assign tick_done = (tick_cnt == current_threshold);
assign thr_empty_o   = (thr_valid==1'b0);
assign xmitr_empty_o = (thr_valid==1'b0)&&(current_state==S_IDLE);
assign tx_ready_n_o   = (thr_valid==1'b1);
endmodule

