// -----------------------------------------------------------------------------
// bpsk_transceiver.v : BPSK modulator -> AWGN channel -> coherent demodulator
//                      + built-in BER counter.
//
//  Data path (1 sample / clock, 8 samples / symbol, 1 carrier cycle / symbol)
//   PRBS15 -> BPSK mod (+/-cos) -> +AWGN -> x cos (coherent) -> integrate&dump
//          -> sign decision -> compare with delayed Tx bit -> BER counters
// -----------------------------------------------------------------------------
module bpsk_transceiver (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  noise_gain,     // AWGN sigma (LSBs)
    output reg  [31:0] bit_count,
    output reg  [31:0] err_count,
    output reg         tx_bit_dbg,
    output reg         rx_bit_dbg
);
    // ---- symbol timing --------------------------------------------------
    reg [2:0] ph0;
    always @(posedge clk) ph0 <= rst ? 3'd0 : ph0 + 3'd1;

    // ---- source ------------------------------------------------------------
    wire prbs_bit;
    prbs15 #(.SEED(15'h1ACE)) u_src (.clk(clk), .rst(rst),
                                     .en(ph0 == 3'd7), .bit_o(prbs_bit));
    // bit is stable for the whole symbol (LFSR steps at ph==7 -> new bit @ph==0)
    wire tx_bit = prbs_bit;

    // ---- modulator (stage 1) ------------------------------------------------
    wire signed [7:0] c0, s0_unused;
    carrier_lut u_lut0 (.ph(ph0), .cos_o(c0), .sin_o(s0_unused));

    reg signed [8:0] tx_s;  reg [2:0] ph1;  reg b1;
    always @(posedge clk) begin
        tx_s <= tx_bit ? $signed({c0[7], c0}) : -$signed({c0[7], c0});
        ph1  <= ph0;
        b1   <= tx_bit;
    end

    // ---- AWGN channel (stage 2) --------------------------------------------
    wire signed [13:0] n;
    awgn_gen u_awgn (.clk(clk), .rst(rst), .en(1'b1), .gain(noise_gain), .noise(n));

    reg signed [13:0] rx_s; reg [2:0] ph2; reg b2;
    always @(posedge clk) begin
        rx_s <= $signed({{5{tx_s[8]}}, tx_s}) + n;
        ph2  <= ph1;
        b2   <= b1;
    end

    // ---- coherent demod: multiply by local carrier (stage 3) ---------------
    wire signed [7:0] c2, s2_unused;
    carrier_lut u_lut2 (.ph(ph2), .cos_o(c2), .sin_o(s2_unused));

    reg signed [21:0] prod; reg [2:0] ph3; reg b3;
    always @(posedge clk) begin
        prod <= rx_s * c2;
        ph3  <= ph2;
        b3   <= b2;
    end

    // ---- integrate & dump + decision (stage 4) -----------------------------
    reg signed [25:0] acc;
    wire signed [25:0] acc_next = ((ph3 == 3'd0) ? 26'sd0 : acc) + prod;
    always @(posedge clk) acc <= acc_next;

    wire sym_done = (ph3 == 3'd7);
    wire rx_bit   = ~acc_next[25];            // sign bit: >0 -> '1'

    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 32'd0; err_count <= 32'd0;
            tx_bit_dbg <= 1'b0; rx_bit_dbg <= 1'b0;
        end else if (sym_done) begin
            bit_count  <= bit_count + 32'd1;
            err_count  <= err_count + (rx_bit ^ b3);
            tx_bit_dbg <= b3;
            rx_bit_dbg <= rx_bit;
        end
    end
endmodule
