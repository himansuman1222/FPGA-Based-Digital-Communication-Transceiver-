// -----------------------------------------------------------------------------
// carrier_lut.v : 8-sample-per-cycle cosine / sine look-up table (amplitude 64)
// One carrier cycle per symbol (fc = fs/8).  Values = round(64*cos(2*pi*n/8)).
// -----------------------------------------------------------------------------
module carrier_lut (
    input  wire [2:0]        ph,
    output reg  signed [7:0] cos_o,
    output reg  signed [7:0] sin_o
);
    always @(*) begin
        case (ph)
            3'd0: begin cos_o =  8'sd64; sin_o =  8'sd0;  end
            3'd1: begin cos_o =  8'sd45; sin_o =  8'sd45; end
            3'd2: begin cos_o =  8'sd0;  sin_o =  8'sd64; end
            3'd3: begin cos_o = -8'sd45; sin_o =  8'sd45; end
            3'd4: begin cos_o = -8'sd64; sin_o =  8'sd0;  end
            3'd5: begin cos_o = -8'sd45; sin_o = -8'sd45; end
            3'd6: begin cos_o =  8'sd0;  sin_o = -8'sd64; end
            default: begin cos_o = 8'sd45; sin_o = -8'sd45; end
        endcase
    end
endmodule
