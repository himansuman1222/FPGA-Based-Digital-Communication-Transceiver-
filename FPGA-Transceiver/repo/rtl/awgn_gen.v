// -----------------------------------------------------------------------------
// awgn_gen.v : synthesizable Additive White Gaussian Noise generator
//
//  * 3 x xorshift32 PRNGs -> 12 uniform bytes per clock
//  * Central Limit Theorem: sum of 12 uniform U[0,255] bytes, minus mean 1530
//        -> approx. N(0, sigma_raw^2),  sigma_raw = 256 * sqrt(1)  ~= 256
//  * noise = (raw * gain) >>> 8  ->  sigma_out ~= gain   (gain = 0..255)
//  => noise standard deviation (in LSBs) is directly the 8-bit "gain" input.
// -----------------------------------------------------------------------------
module awgn_gen #(
    parameter [31:0] SEED0 = 32'hA5A5_1234,
    parameter [31:0] SEED1 = 32'h1357_9BDF,
    parameter [31:0] SEED2 = 32'hC0FF_EE11
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               en,
    input  wire        [7:0]  gain,       // noise sigma in LSBs
    output reg  signed [13:0] noise
);
    reg [31:0] x0, x1, x2;

    function [31:0] xs32(input [31:0] v);
        reg [31:0] a, b, c;
        begin
            a = v ^ (v << 13);
            b = a ^ (a >> 17);
            c = b ^ (b << 5);
            xs32 = c;
        end
    endfunction

    wire [11:0] sum =
          x0[7:0] + x0[15:8] + x0[23:16] + x0[31:24]
        + x1[7:0] + x1[15:8] + x1[23:16] + x1[31:24]
        + x2[7:0] + x2[15:8] + x2[23:16] + x2[31:24];

    wire signed [12:0] raw    = $signed({1'b0, sum}) - 13'sd1530;
    wire signed [21:0] scaled = raw * $signed({1'b0, gain});

    always @(posedge clk) begin
        if (rst) begin
            x0 <= SEED0; x1 <= SEED1; x2 <= SEED2; noise <= 14'sd0;
        end else if (en) begin
            x0 <= xs32(x0); x1 <= xs32(x1); x2 <= xs32(x2);
            noise <= scaled >>> 8;
        end
    end
endmodule
