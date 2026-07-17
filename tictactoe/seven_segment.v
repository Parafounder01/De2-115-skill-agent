// ============================================================
//  seven_segment.v — 7-segment decoder (active-low)
//  Maps 4-bit BCD to 7-segment pattern for DE2-115
// ============================================================

module seven_segment (
    input  [3:0] bcd,
    output [6:0] seg
);

    reg [6:0] seg_r;
    always @(*) begin
        case (bcd)
            4'd0: seg_r = 7'b1000000;
            4'd1: seg_r = 7'b1111001;
            4'd2: seg_r = 7'b0100100;
            4'd3: seg_r = 7'b0110000;
            4'd4: seg_r = 7'b0011001;
            4'd5: seg_r = 7'b0010010;
            4'd6: seg_r = 7'b0000010;
            4'd7: seg_r = 7'b1111000;
            4'd8: seg_r = 7'b0000000;
            4'd9: seg_r = 7'b0010000;
            default: seg_r = 7'b1111111;  // all off
        endcase
    end
    assign seg = seg_r;

endmodule
