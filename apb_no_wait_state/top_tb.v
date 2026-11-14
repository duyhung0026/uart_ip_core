`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/27/2025 11:20:20 PM
// Design Name: 
// Module Name: top_tb
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


module top_tb;
parameter addr_width = 16;
parameter data_width = 16;

reg pclk;
reg preset_n;
reg [addr_width-1:0]paddr;
reg pselx;
reg penable;
reg pwrite;
reg [data_width-1:0]pwdata;

wire pready;
wire pslverr;
wire [data_width-1:0]prdata;

apb_top UUT (
    .pclk(pclk),
    .preset_n(preset_n),
    .paddr(paddr),
    .pselx(pselx),
    .penable(penable),
    .pwrite(pwrite),
    .pwdata(pwdata),
    .pready(pready),
    .pslverr(pslverr),
    .prdata(prdata)
);

initial begin
    pclk = 0;
    forever #5 pclk = ~pclk;
end

task apb_write_no_wait;
    input [15:0] addr;
    input [15:0] wdata;
    begin
        @(posedge pclk);
        paddr   = addr;
        pwdata  = wdata;
        pwrite  = 1;
        pselx   = 1;
        penable = 0;

        @(posedge pclk);
        penable = 1;
        @(posedge pclk);
        $strobe("[%0t] WRITE: addr=%h data=%h", $time, paddr, pwdata);
        pselx   = 0;
        penable = 0;
    end
endtask

task apb_read_no_wait;
    input [15:0] addr;
    begin
        @(posedge pclk);
        paddr   = addr;
        pwrite  = 0;
        pselx   = 1;
        penable = 0;

        @(posedge pclk);
        penable = 1;

        @(posedge pclk);
        $strobe("[%0t] READ : addr=%h data=%h", $time, paddr, prdata);
        pselx   = 0;
        penable = 0;
    end
endtask

initial begin
    preset_n = 0;
    #50;
    preset_n = 1;
    #10;
    apb_write_no_wait(16'h0001, 16'h1234);
    apb_read_no_wait(16'h0001);
    #100;
    apb_write_no_wait(16'h000F, 16'h0008);
    apb_read_no_wait(16'h000F);
    #100;
    apb_write_no_wait(16'h0010, 16'h000);
    apb_read_no_wait(16'h0010);
    #100;
    $finish;
end
endmodule
