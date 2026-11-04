// -----------------------------------------------------------------------------
// fpga_top.v : demo top for Digital Basys-3 / Nexys-A7 style boards (100 MHz)
//
//   sw[3:0]  -> Eb/N0 select (0..10 dB, values >10 clamp to 10 dB)
//   sw[4]    -> 0 = BPSK, 1 = QPSK
//   sw[5]    -> 1 = show upper 16 bits of error counter, 0 = lower 16 bits
//   btnC     -> reset / clear counters
//   led[15:0]-> error counter (live)         led is split by sw[5]
// Observe BER on-chip via ILA/VIO on bit_count/err_count, or read LEDs.
// -----------------------------------------------------------------------------
module fpga_top (
    input  wire        clk,         // 100 MHz
    input  wire        btnC,
    input  wire [5:0]  sw,
    output wire [15:0] led
);
    reg [7:0] gain;
    always @(*) begin
        case (sw[3:0])
            4'd0:  gain = 8'd91;  4'd1: gain = 8'd81;  4'd2: gain = 8'd72;
            4'd3:  gain = 8'd64;  4'd4: gain = 8'd57;  4'd5: gain = 8'd51;
            4'd6:  gain = 8'd45;  4'd7: gain = 8'd40;  4'd8: gain = 8'd36;
            4'd9:  gain = 8'd32;  default: gain = 8'd29;
        endcase
    end

    // synchronise reset
    reg [1:0] rs; always @(posedge clk) rs <= {rs[0], btnC};
    wire rst = rs[1];

    wire [31:0] bb, be, qb, qe;
    bpsk_transceiver u_b (.clk(clk), .rst(rst), .noise_gain(gain),
                          .bit_count(bb), .err_count(be),
                          .tx_bit_dbg(), .rx_bit_dbg());
    qpsk_transceiver u_q (.clk(clk), .rst(rst), .noise_gain(gain),
                          .bit_count(qb), .err_count(qe));

    wire [31:0] err = sw[4] ? qe : be;
    assign led = sw[5] ? err[31:16] : err[15:0];
endmodule
