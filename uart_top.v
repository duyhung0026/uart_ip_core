`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: uart_top
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


module uart_top
#(parameter [15:0] DLR_RESET = 16'd434,
parameter [2:0]  IER_RESET = 3'b000)
(
input  wire clk_i,
input  wire rst_n_i,
// APB slave, no wait state
input  wire apb_psel_i,
input  wire [5:0] apb_paddr_i,
input  wire [31:0] apb_pwdata_i,
input  wire apb_pwrite_i,
input  wire apb_penable_i,
output wire apb_pready_o,
output wire  apb_pslverr_o,
output wire [31:0] apb_prdata_o,
// serial + status
input  wire rxd_i,
output wire txd_o,
output wire rx_ready_n_o,
output wire tx_ready_n_o,
output wire int_o
);
localparam [5:0] A_RBR_THR = 6'h00, 
A_IER = 6'h04, 
A_IIR = 6'h08, 
A_LCR = 6'h0C,
A_LSR = 6'h14, 
A_DLR_LSB = 6'h20, 
A_DLR_MSB = 6'h24;


// ---------------- APB front-end (no wait state) -> simple register bus ----------------
wire        reg_wr, reg_rd;
wire [5:0]  reg_addr;
wire [31:0] reg_wdata;
reg  [31:0] reg_rdata;
apb_slave #(.ADDR_W(6), .DATA_W(32)) u_apb (
.apb_psel_i(apb_psel_i), .apb_penable_i(apb_penable_i), .apb_pwrite_i(apb_pwrite_i),
.apb_paddr_i(apb_paddr_i), .apb_pwdata_i(apb_pwdata_i),
.apb_pready_o(apb_pready_o), .apb_pslverr_o(apb_pslverr_o), .apb_prdata_o(apb_prdata_o),
.reg_wr_o(reg_wr), .reg_rd_o(reg_rd), .reg_addr_o(reg_addr), .reg_wdata_o(reg_wdata),
.reg_rdata_i(reg_rdata));

// ---------------- config registers ----------------
reg [6:0] lcr;                               // LCR[6:0]
reg [7:0] dlr_lsb, dlr_msb;
reg [2:0] ier;                               // {rls_int_en, thre_int_en, rda_int_en}
always @(posedge clk_i or negedge rst_n_i) begin
    if (!rst_n_i) begin
        ier     <= IER_RESET;
        lcr     <= 7'b001_0011;              // 8 bit, 1 stop, no parity, even_parity_sel=1
        dlr_lsb <= DLR_RESET[7:0];
        dlr_msb <= DLR_RESET[15:8];
    end else if (reg_wr) begin
        case (reg_addr)
            A_IER:     ier     <= reg_wdata[2:0];
            A_LCR:     lcr     <= reg_wdata[6:0];
            A_DLR_LSB: dlr_lsb <= reg_wdata[7:0];
            A_DLR_MSB: dlr_msb <= reg_wdata[7:0];
            default: ;
        endcase
    end
end
wire break_ctrl_en   = lcr[6];
wire stick_parity_en = lcr[5];
wire even_parity_sel = lcr[4];
wire parity_en       = lcr[3];
wire stop_bit_ctrl   = lcr[2];
wire [1:0] char_len_sel    = lcr[1:0];

// ---------------- strobes ----------------
wire thr_wr = reg_wr && (reg_addr == A_RBR_THR);
wire rbr_rd = reg_rd && (reg_addr == A_RBR_THR);
wire lsr_rd = reg_rd && (reg_addr == A_LSR);

// ---------------- datapath ----------------
wire baud_tick;
baud_gen u_baud_gen (.clk_i(clk_i), .rst_n_i(rst_n_i),
.dlr_lsb_i(dlr_lsb), .dlr_msb_i(dlr_msb), .baud_tick_o(baud_tick));

wire thr_empty, xmitr_empty;
uart_tx u_uart_tx (.clk_i(clk_i), .rst_n_i(rst_n_i), .baud_tick_i(baud_tick),
.char_len_sel_i(char_len_sel), .stop_bit_ctrl_i(stop_bit_ctrl), .parity_en_i(parity_en),
.even_parity_sel_i(even_parity_sel), .stick_parity_en_i(stick_parity_en),
.break_ctrl_en_i(break_ctrl_en),
.thr_wr_i(thr_wr), .thr_data_i(reg_wdata[7:0]),
.thr_empty_o(thr_empty), .xmitr_empty_o(xmitr_empty), .tx_ready_n_o(tx_ready_n_o),
.txd_o(txd_o));

wire [7:0] rbr_data;
wire data_rdy, overrun_err, parity_err, framing_err, break_cond;
rx_top u_rx_top (.clk_i(clk_i), .rst_n_i(rst_n_i), .baud_tick_i(baud_tick), .rxd_i(rxd_i),
.char_len_sel_i(char_len_sel), .parity_en_i(parity_en), .even_parity_sel_i(even_parity_sel),
.stick_parity_en_i(stick_parity_en), .rbr_rd_i(rbr_rd), .lsr_rd_i(lsr_rd),
.rbr_data_o(rbr_data), .data_rdy_o(data_rdy), .overrun_err_o(overrun_err),
.parity_err_o(parity_err), .framing_err_o(framing_err), .break_cond_o(break_cond),
.rx_ready_n_o(rx_ready_n_o));

// LSR[7]=0, [6]=xmitr_empty, [5]=thr_empty, [4]=break, [3]=framing, [2]=parity, [1]=overrun, [0]=data_rdy
wire [7:0] lsr = {1'b0, xmitr_empty, thr_empty, break_cond, framing_err, parity_err, overrun_err, data_rdy};

// ---------------- interrupts (level-based, masked by IER) ----------------
// RLS : any LSR error flag -> cleared by reading LSR (flags are sticky until lsr_rd)
// RDA : data_rdy -> cleared by reading RBR (non-FIFO: trigger level = 1 char)
// THRE: thr_empty -> cleared by writing THR
wire int_rls  = ier[2] && (overrun_err | parity_err | framing_err | break_cond);
wire int_rda  = ier[0] && data_rdy;
wire int_thre = ier[1] && thr_empty;
wire int_pend = int_rls | int_rda | int_thre;
wire [1:0] int_prio = int_rls ? 2'b11 : int_rda ? 2'b10 : int_thre ? 2'b01 : 2'b00;
assign int_o = int_pend;
// IIR[7:6]=fifos_en=00 (no FIFO), [2:1]=int_prio, [0]=int_pending (0 = pending)
wire [7:0] iir = {2'b00, 3'b000, int_prio, ~int_pend};
// ---------------- read mux (combinational: pready is always 1) ----------------
always @(*) begin
reg_rdata = 32'd0;                       // WO / reserved read as 0
case (reg_addr)
A_RBR_THR: reg_rdata = {24'd0, rbr_data};
A_IER:     reg_rdata = {29'd0, ier};
A_IIR:     reg_rdata = {24'd0, iir};
A_LCR:     reg_rdata = {25'd0, lcr};
A_LSR:     reg_rdata = {24'd0, lsr};
A_DLR_LSB: reg_rdata = {24'd0, dlr_lsb};
A_DLR_MSB: reg_rdata = {24'd0, dlr_msb};
default:   reg_rdata = 32'd0;
endcase
end
endmodule
