// -----------------------------------------------------------------------------
// prbs15.v : PRBS-15 (x^15 + x^14 + 1) pseudo-random binary source
// -----------------------------------------------------------------------------
module prbs15 #(parameter [14:0] SEED = 15'h1ACE) (
    input  wire clk,
    input  wire rst,
    input  wire en,
    output wire bit_o
);
    reg [14:0] sr;
    assign bit_o = sr[14];
    always @(posedge clk) begin
        if (rst)     sr <= SEED;
        else if (en) sr <= {sr[13:0], sr[14] ^ sr[13]};
    end
endmodule
