// -----------------------------------------------------------------------------
// qpsk_transceiver.v : QPSK (2 bits/symbol) -> AWGN -> coherent I/Q demodulator
//
//   s(t) = bI*cos(wt) + bQ*sin(wt)    bI,bQ in {+1,-1}  (Gray-mapped bit pairs)
//   Same symbol rate / bandwidth as BPSK but 2x data rate (spectral efficiency
//   doubled).  Per-bit BER vs Eb/N0 equals BPSK because I and Q are orthogonal.
// -----------------------------------------------------------------------------
module qpsk_transceiver (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  noise_gain,
    output reg  [31:0] bit_count,
    output reg  [31:0] err_count
);
    reg [2:0] ph0;
    always @(posedge clk) ph0 <= rst ? 3'd0 : ph0 + 3'd1;

    wire bi, bq;
    prbs15 #(.SEED(15'h1ACE)) u_srci (.clk(clk), .rst(rst), .en(ph0 == 3'd7), .bit_o(bi));
    prbs15 #(.SEED(15'h2B67)) u_srcq (.clk(clk), .rst(rst), .en(ph0 == 3'd7), .bit_o(bq));

    // ---- QPSK modulator (stage 1) -------------------------------------------
    wire signed [7:0] c0, s0;
    carrier_lut u_lut0 (.ph(ph0), .cos_o(c0), .sin_o(s0));

    wire signed [9:0] ci = {{2{c0[7]}}, c0};
    wire signed [9:0] sq = {{2{s0[7]}}, s0};

    reg signed [9:0] tx_s; reg [2:0] ph1; reg bi1, bq1;
    always @(posedge clk) begin
        tx_s <= (bi ? ci : -ci) + (bq ? sq : -sq);
        ph1 <= ph0; bi1 <= bi; bq1 <= bq;
    end

    // ---- AWGN (stage 2) -------------------------------------------------------
    wire signed [13:0] n;
    awgn_gen #(.SEED0(32'h0BAD_F00D), .SEED1(32'hDEAD_BEEF), .SEED2(32'h1234_ABCD))
        u_awgn (.clk(clk), .rst(rst), .en(1'b1), .gain(noise_gain), .noise(n));

    reg signed [13:0] rx_s; reg [2:0] ph2; reg bi2, bq2;
    always @(posedge clk) begin
        rx_s <= $signed({{4{tx_s[9]}}, tx_s}) + n;
        ph2 <= ph1; bi2 <= bi1; bq2 <= bq1;
    end

    // ---- coherent I/Q mixers (stage 3) -----------------------------------------
    wire signed [7:0] c2, s2;
    carrier_lut u_lut2 (.ph(ph2), .cos_o(c2), .sin_o(s2));

    reg signed [21:0] pi_, pq_; reg [2:0] ph3; reg bi3, bq3;
    always @(posedge clk) begin
        pi_ <= rx_s * c2;
        pq_ <= rx_s * s2;
        ph3 <= ph2; bi3 <= bi2; bq3 <= bq2;
    end

    // ---- integrate & dump (stage 4) ----------------------------------------------
    reg signed [25:0] acc_i, acc_q;
    wire signed [25:0] ni = ((ph3 == 3'd0) ? 26'sd0 : acc_i) + pi_;
    wire signed [25:0] nq = ((ph3 == 3'd0) ? 26'sd0 : acc_q) + pq_;
    always @(posedge clk) begin acc_i <= ni; acc_q <= nq; end

    wire sym_done = (ph3 == 3'd7);
    wire rbi = ~ni[25];
    wire rbq = ~nq[25];

    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 32'd0; err_count <= 32'd0;
        end else if (sym_done) begin
            bit_count <= bit_count + 32'd2;
            err_count <= err_count + (rbi ^ bi3) + (rbq ^ bq3);
        end
    end
endmodule
