`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/24/2025 08:23:38 AM
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
#(parameter addr_width = 16,
parameter data_width =16)

(input wire pclk,
input wire preset_n,
input wire [addr_width -1:0]paddr,
input wire pselx,
input wire penable,
input wire pwrite,
input wire [data_width -1:0]pwdata,
output reg pready,
output reg pslverr,
output reg [data_width -1:0]prdata);
        
reg [data_width -1:0] reg_a;
reg [data_width -1:0] reg_b;
reg [data_width -1:0] reg_c;
reg [data_width -1:0] reg_d;
reg [data_width -1:0] reg_e;
reg [data_width -1:0] reg_f;
reg [data_width -1:0] reg_g;
reg [data_width -1:0] reg_h;
reg [data_width -1:0] reg_i;
reg [data_width -1:0] reg_j;
reg [data_width -1:0] reg_k;
reg [data_width -1:0] reg_l;
reg [data_width -1:0] reg_m;
reg [data_width -1:0] reg_n;
reg [data_width -1:0] reg_o;
reg [data_width -1:0] reg_p;


always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
        pready <= 1'b0;
    else pready <= (penable && pselx);
end

always @(posedge pclk or negedge preset_n) begin
    if (!preset_n)
        pslverr <= 1'b0;
    else
        pslverr <= (pselx && penable && (paddr > 16'h000F));
end



always @(posedge pclk or negedge preset_n) begin
        if(!preset_n) begin
            reg_a <= 16'h0000;
            reg_b <= 16'h0000;
            reg_c <= 16'h0000;
            reg_d <= 16'h0000;
            reg_e <= 16'h0000;
            reg_f <= 16'h0000;
            reg_g <= 16'h0000;
            reg_h <= 16'h0000;
            reg_i <= 16'h0000;
            reg_j <= 16'h0000;
            reg_k <= 16'h0000;
            reg_l <= 16'h0000;
            reg_m <= 16'h0000;
            reg_n <= 16'h0000;
            reg_o <= 16'h0000;
            reg_p <= 16'h0000;                                            
            end else begin
              //write state
                if(pwrite && pselx && penable)begin
                    case(paddr)
                    16'h0000: reg_a <= pwdata;
                    16'h0001: reg_b <= pwdata;
                    16'h0002: reg_c <= pwdata;
                    16'h0003: reg_d <= pwdata;
                    16'h0004: reg_e <= pwdata;
                    16'h0005: reg_f <= pwdata;
                    16'h0006: reg_g <= pwdata;
                    16'h0007: reg_h <= pwdata;
                    16'h0008: reg_i <= pwdata;
                    16'h0009: reg_j <= pwdata;
                    16'h000A: reg_k <= pwdata;
                    16'h000B: reg_l <= pwdata;
                    16'h000C: reg_m <= pwdata;
                    16'h000D: reg_n <= pwdata;
                    16'h000E: reg_o <= pwdata;
                    16'h000F: reg_p <= pwdata;   
                    default: pslverr <= 1'b1;
                     endcase
                end else if (!pwrite && pselx && penable) begin
                case (paddr)
                    16'h0000: prdata<= reg_a;
                    16'h0001: prdata<= reg_b;
                    16'h0002: prdata<= reg_c;
                    16'h0003: prdata<= reg_d;
                    16'h0004: prdata<= reg_e;
                    16'h0005: prdata<= reg_f;
                    16'h0006: prdata<= reg_g;
                    16'h0007: prdata<= reg_h;
                    16'h0008: prdata<= reg_i;
                    16'h0009: prdata<= reg_j;
                    16'h000A: prdata<= reg_k;
                    16'h000B: prdata<= reg_l;
                    16'h000C: prdata<= reg_m;
                    16'h000D: prdata<= reg_n;
                    16'h000E: prdata<= reg_o;
                    16'h000F: prdata<= reg_p;   
                    default: pslverr <= 1'b1;
                    endcase
                    end
            end
        end
endmodule
