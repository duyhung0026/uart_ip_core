`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 08:50:03 PM
// Design Name: 
// Module Name: rx_top_tb
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


module rx_top_tb;
localparam DIV = 4;
localparam BIT_CLKS = 16 * DIV;

reg clk_i, rst_n_i, baud_tick_i, rxd_i;
reg [1:0] char_len_sel_i;
reg parity_en_i, even_parity_sel_i, stick_parity_en_i;
reg rbr_rd_i, lsr_rd_i;
wire [7:0] rbr_data_o;
wire data_rdy_o, overrun_err_o, parity_err_o, framing_err_o, rx_ready_n_o;

integer tx_bit_clks, div_cnt;
integer errors = 0, checks = 0;
integer random_delay;
reg [7:0] read_data;
reg [3:0] read_lsr;

rx_top dut (
.clk_i(clk_i), .rst_n_i(rst_n_i), .baud_tick_i(baud_tick_i), .rxd_i(rxd_i),
.char_len_sel_i(char_len_sel_i), .parity_en_i(parity_en_i),
.even_parity_sel_i(even_parity_sel_i), .stick_parity_en_i(stick_parity_en_i),
.rbr_rd_i(rbr_rd_i), .lsr_rd_i(lsr_rd_i), .rbr_data_o(rbr_data_o),
.data_rdy_o(data_rdy_o), .overrun_err_o(overrun_err_o),
.parity_err_o(parity_err_o), .framing_err_o(framing_err_o),
.rx_ready_n_o(rx_ready_n_o)
);

initial clk_i = 1'b0;
always #5 clk_i = ~clk_i;

always @(posedge clk_i or negedge rst_n_i) begin
if (!rst_n_i) begin div_cnt <= 0; baud_tick_i <= 1'b0; end
else if (div_cnt == DIV-1) begin div_cnt <= 0; baud_tick_i <= 1'b1; end
else begin div_cnt <= div_cnt + 1; baud_tick_i <= 1'b0; end
end

task check(input [8*64-1:0] name, input cond);
begin
checks = checks + 1;
if (cond !== 1'b1) begin errors = errors + 1; $display("[FAIL] %0s", name); end
else $display("[PASS] %0s", name);
end
endtask

task send_bit(input b);
begin
@(negedge clk_i); rxd_i = b;
repeat (tx_bit_clks) @(negedge clk_i);
end
endtask

task send_frame(input [7:0] data, input [1:0] len_sel, input bad_parity, input bad_stop);
integer n, i;
reg [7:0] d;
reg p;
begin
n = len_sel + 5;
char_len_sel_i = len_sel;
d = data & ((1 << n) - 1);
if (stick_parity_en_i) p = ~even_parity_sel_i;
else if (even_parity_sel_i) p = ^d;
else p = ~(^d);
if (bad_parity) p = ~p;
send_bit(1'b0);
for (i = 0; i < n; i = i + 1) send_bit(d[i]);
if (parity_en_i) send_bit(p);
send_bit(bad_stop ? 1'b0 : 1'b1);
@(negedge clk_i); rxd_i = 1'b1;
end
endtask

task cpu_read_rbr(output [7:0] value);
begin
@(negedge clk_i); value = rbr_data_o; rbr_rd_i = 1'b1;
@(negedge clk_i); rbr_rd_i = 1'b0;
end
endtask

task cpu_read_lsr(output [3:0] value);
begin
@(negedge clk_i); value = {framing_err_o, parity_err_o, overrun_err_o, data_rdy_o}; lsr_rd_i = 1'b1;
@(negedge clk_i); lsr_rd_i = 1'b0;
end
endtask

task test_frame(input [8*64-1:0] name, input [7:0] data, input [1:0] len_sel, input bad_parity, input bad_stop);
integer n;
reg [7:0] expected_data;
begin
n = len_sel + 5;
expected_data = data & ((1 << n) - 1);
send_frame(data, len_sel, bad_parity, bad_stop);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check({name, " : Data ready"}, data_rdy_o == 1'b1);
check({name, " : RX data"}, rbr_data_o == expected_data);
check({name, " : Parity error"}, parity_err_o == (parity_en_i && bad_parity));
check({name, " : Framing error"}, framing_err_o == bad_stop);
cpu_read_rbr(read_data);
check({name, " : CPU reads RBR"}, read_data == expected_data);
check({name, " : Data ready cleared"}, data_rdy_o == 1'b0);
cpu_read_lsr(read_lsr);
check({name, " : LSR parity"}, read_lsr[2] == (parity_en_i && bad_parity));
check({name, " : LSR framing"}, read_lsr[3] == bad_stop);
check({name, " : Error flags cleared"}, !overrun_err_o && !parity_err_o && !framing_err_o);
end
endtask

task test_false_start;
begin
rxd_i = 1'b1;
repeat (5) @(negedge clk_i);
rxd_i = 1'b0;
repeat (6 * DIV) @(negedge clk_i);
rxd_i = 1'b1;
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("False start: no data ready", data_rdy_o == 1'b0);
check("False start: no overrun", overrun_err_o == 1'b0);
end
endtask

task test_baud_mismatch(input [8*64-1:0] name, input integer bit_period);
begin
tx_bit_clks = bit_period;
send_frame(8'hA5, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check({name, " : Data ready"}, data_rdy_o == 1'b1);
check({name, " : RX data"}, rbr_data_o == 8'hA5);
check({name, " : No parity error"}, parity_err_o == 1'b0);
check({name, " : No framing error"}, framing_err_o == 1'b0);
cpu_read_rbr(read_data); cpu_read_lsr(read_lsr);
tx_bit_clks = BIT_CLKS;
end
endtask

task test_overrun;
begin
$display("\n========== RX BUFFER OVERRUN TEST ==========");
parity_en_i = 1'b0;
send_frame(8'hA5, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
send_frame(8'h3C, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("Overrun: Data ready", data_rdy_o == 1'b1);
check("Overrun: Error flag set", overrun_err_o == 1'b1);
check("Overrun: Old data preserved", rbr_data_o == 8'hA5);
cpu_read_rbr(read_data); cpu_read_lsr(read_lsr);
check("Overrun: Flag cleared after LSR read", overrun_err_o == 1'b0);
end
endtask

task test_read_in_time;
begin
$display("\n========== RX BUFFER READ IN TIME TEST ==========");
parity_en_i = 1'b0;
send_frame(8'hA5, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("Read in time: First frame received", rbr_data_o == 8'hA5 && data_rdy_o == 1'b1);
cpu_read_rbr(read_data);
check("Read in time: First RBR data", read_data == 8'hA5);
check("Read in time: Data ready cleared", data_rdy_o == 1'b0);
send_frame(8'h3C, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("Read in time: Second frame received", rbr_data_o == 8'h3C && data_rdy_o == 1'b1);
check("Read in time: No overrun", overrun_err_o == 1'b0);
cpu_read_rbr(read_data); cpu_read_lsr(read_lsr);
end
endtask

task test_sticky_error;
begin
$display("\n========== RX BUFFER STICKY ERROR TEST ==========");
parity_en_i = 1'b1; even_parity_sel_i = 1'b1; stick_parity_en_i = 1'b0;
send_frame(8'h55, 2'b11, 1'b1, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("Sticky: Parity error initially set", parity_err_o == 1'b1);
cpu_read_rbr(read_data);
send_frame(8'h55, 2'b11, 1'b0, 1'b0);
repeat (2 * BIT_CLKS) @(negedge clk_i);
check("Sticky: Second frame received", data_rdy_o == 1'b1 && rbr_data_o == 8'h55);
check("Sticky: Parity error remains set", parity_err_o == 1'b1);
cpu_read_lsr(read_lsr);
check("Sticky: LSR captures parity error", read_lsr[2] == 1'b1);
check("Sticky: Parity error cleared after LSR read", parity_err_o == 1'b0);
cpu_read_rbr(read_data);
parity_en_i = 1'b0; even_parity_sel_i = 1'b0; stick_parity_en_i = 1'b0;
end
endtask

initial begin
rst_n_i = 1'b1; rxd_i = 1'b1; baud_tick_i = 1'b0;
char_len_sel_i = 2'b11; parity_en_i = 1'b0; even_parity_sel_i = 1'b0; stick_parity_en_i = 1'b0;
rbr_rd_i = 1'b0; lsr_rd_i = 1'b0; tx_bit_clks = BIT_CLKS;
read_data = 8'h00; read_lsr = 4'h0;
#1; rst_n_i = 1'b0;
repeat (3) @(negedge clk_i);
rst_n_i = 1'b1;
repeat (4) @(negedge clk_i);
$display("\n========== BASIC FRAME TESTS =============");
parity_en_i = 1'b0;
test_frame("8N1 0x55", 8'h55, 2'b11, 0, 0);
test_frame("8N1 0xA3", 8'hA3, 2'b11, 0, 0);
test_frame("8N1 0x00", 8'h00, 2'b11, 0, 0);
test_frame("8N1 0xFF", 8'hFF, 2'b11, 0, 0);
test_frame("5N1 0x1B", 8'hDB, 2'b00, 0, 0);
test_frame("6N1 0x2D", 8'hED, 2'b01, 0, 0);
test_frame("7N1 0x53", 8'hD3, 2'b10, 0, 0);

$display("\n========== EVEN PARITY TESTS =============");
parity_en_i = 1'b1; even_parity_sel_i = 1'b1; stick_parity_en_i = 1'b0;
test_frame("8E1 Good parity", 8'h55, 2'b11, 0, 0);
test_frame("8E1 Bad parity", 8'h55, 2'b11, 1, 0);

$display("\n========== ODD PARITY TESTS ==============");
parity_en_i = 1'b1; even_parity_sel_i = 1'b0; stick_parity_en_i = 1'b0;
test_frame("8O1 Good parity", 8'hA3, 2'b11, 0, 0);
test_frame("8O1 Bad parity", 8'hA3, 2'b11, 1, 0);

$display("\n========== STICK PARITY TESTS ============");
parity_en_i = 1'b1; stick_parity_en_i = 1'b1; even_parity_sel_i = 1'b1;
test_frame("Stick parity 0 good", 8'h55, 2'b11, 0, 0);
test_frame("Stick parity 0 bad", 8'h55, 2'b11, 1, 0);
even_parity_sel_i = 1'b0;
test_frame("Stick parity 1 good", 8'hA3, 2'b11, 0, 0);
test_frame("Stick parity 1 bad", 8'hA3, 2'b11, 1, 0);

$display("\n========== FRAMING ERROR TESTS ===========");
parity_en_i = 1'b0; stick_parity_en_i = 1'b0; even_parity_sel_i = 1'b0;
test_frame("Bad stop bit", 8'h55, 2'b11, 0, 1);

$display("\n========== RANDOM START PHASE ============");
random_delay = $random;
if (random_delay < 0) random_delay = -random_delay;
random_delay = random_delay % BIT_CLKS;
repeat (random_delay) @(negedge clk_i);
test_frame("Random start phase", 8'hC7, 2'b11, 0, 0);

$display("\n========== FALSE START TEST ==============");
test_false_start();

$display("\n========== BAUD MISMATCH TESTS ===========");
test_baud_mismatch("Baud mismatch +3%", 66);
test_baud_mismatch("Baud mismatch -3%", 62);

test_overrun();
test_read_in_time();
test_sticky_error();

$display("\n------------------------------------------");
if (errors == 0) $display("ALL TESTS PASSED (%0d checks)", checks);
 else $display("TEST FAILED: %0d / %0d checks failed", errors, checks);
$display("------------------------------------------");
$finish;
end

initial begin
    #5000000;
    $display("[FAIL] Simulation timeout");
    $finish;
end
endmodule
