`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:
// Design Name: 
// Module Name: apb_top
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


//======================================
//===========NO WAIT STATE==============
//======================================

module apb_top
#(parameter ADDR_W = 6,
parameter DATA_W = 32)
(input  wire apb_psel_i,
input  wire apb_penable_i,
input  wire apb_pwrite_i,
input  wire [ADDR_W-1:0] apb_paddr_i,
input  wire [DATA_W-1:0] apb_pwdata_i,
output wire apb_pready_o,
output wire apb_pslverr_o,
output wire [DATA_W-1:0] apb_prdata_o,
// register bus
output wire reg_wr_o,
output wire reg_rd_o,
output wire [ADDR_W-1:0] reg_addr_o,
output wire [DATA_W-1:0] reg_wdata_o,
input  wire [DATA_W-1:0] reg_rdata_i
);
assign apb_pready_o  = 1'b1;
assign apb_pslverr_o = 1'b0;
wire access = apb_psel_i && apb_penable_i && apb_pready_o;
assign reg_wr_o = access &&  apb_pwrite_i;
assign reg_rd_o = access && !apb_pwrite_i;
assign reg_addr_o = apb_paddr_i;
assign reg_wdata_o = apb_pwdata_i;
assign apb_prdata_o = reg_rdata_i;
endmodule
