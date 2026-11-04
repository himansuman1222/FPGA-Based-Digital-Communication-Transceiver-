`timescale 1ns/1ps
// Short run (noise-free + noisy) dumping a VCD for waveform inspection in Vivado/GTKWave
module tb_bpsk_wave;
    reg clk = 0, rst = 1; reg [7:0] gain = 8'd0;
    always #5 clk = ~clk;
    wire [31:0] bc, ec; wire t, r;
    bpsk_transceiver dut (.clk(clk), .rst(rst), .noise_gain(gain),
        .bit_count(bc), .err_count(ec), .tx_bit_dbg(t), .rx_bit_dbg(r));
    initial begin
        $dumpfile("sim/bpsk_wave.vcd"); $dumpvars(0, tb_bpsk_wave);
        repeat (20) @(posedge clk); rst = 0;
        repeat (8*500) @(posedge clk);
        $display("Noise-free : bits=%0d errors=%0d (expect 0)", bc, ec);
        gain = 8'd91;                       // 0 dB
        repeat (8*500) @(posedge clk);
        $display("After 0 dB : bits=%0d errors=%0d", bc, ec);
        $finish;
    end
endmodule
