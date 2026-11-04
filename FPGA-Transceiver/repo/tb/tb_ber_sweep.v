`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// tb_ber_sweep.v : sweeps Eb/N0 = 0..10 dB (noise gain table) for BPSK and QPSK
// and writes sim/ber_results.csv  ->  consumed by python/plot_ber.py
//
//   sigma(LSB) = 128 / sqrt(2 * Eb/N0)   (see docs/theory.md)
// -----------------------------------------------------------------------------
module tb_ber_sweep;
    parameter NSYM = 100000;               // symbols per SNR point
    reg clk = 0;  reg rst = 1;
    reg [7:0] gain = 8'd91;
    always #5 clk = ~clk;                  // 100 MHz

    wire [31:0] bb_cnt, be_cnt, qb_cnt, qe_cnt;
    wire tdbg, rdbg;

    bpsk_transceiver u_bpsk (.clk(clk), .rst(rst), .noise_gain(gain),
        .bit_count(bb_cnt), .err_count(be_cnt), .tx_bit_dbg(tdbg), .rx_bit_dbg(rdbg));
    qpsk_transceiver u_qpsk (.clk(clk), .rst(rst), .noise_gain(gain),
        .bit_count(qb_cnt), .err_count(qe_cnt));

    reg [7:0] gtab [0:10];
    integer i, fd;
    initial begin
        // Eb/N0 = 0,1,...,10 dB
        gtab[0]=91; gtab[1]=81; gtab[2]=72; gtab[3]=64; gtab[4]=57; gtab[5]=51;
        gtab[6]=45; gtab[7]=40; gtab[8]=36; gtab[9]=32; gtab[10]=29;
        fd = $fopen("sim/ber_results.csv", "w");
        $fwrite(fd, "ebn0_db,gain,bpsk_bits,bpsk_errs,qpsk_bits,qpsk_errs\n");
        for (i = 0; i <= 10; i = i + 1) begin
            gain = gtab[i];
            rst = 1; repeat (20) @(posedge clk);
            rst = 0;
            repeat (NSYM * 8) @(posedge clk);
            $fwrite(fd, "%0d,%0d,%0d,%0d,%0d,%0d\n", i, gain,
                    bb_cnt, be_cnt, qb_cnt, qe_cnt);
            $display("EbN0=%2d dB gain=%3d | BPSK %0d/%0d | QPSK %0d/%0d",
                     i, gain, be_cnt, bb_cnt, qe_cnt, qb_cnt);
        end
        $fclose(fd);
        $finish;
    end
endmodule
