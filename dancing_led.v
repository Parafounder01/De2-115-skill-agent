// ============================================================
//  dancing_led.v — DE2-115 running light (standalone)
//
//  A single lit LED bounces back and forth across LEDR[17:0].
//  Starts automatically on power-up (no reset needed).
// ============================================================

module dancing_led (
    input  clk,             // 50 MHz (PIN_Y2)
    output [17:0] ledr
);

    reg [24:0] dance_cnt;
    reg [17:0] ledr_r;
    reg        dance_dir;   // 0 = toward LEDR17, 1 = toward LEDR0
    localparam DANCE_STEP = 25'd1_500_000;  // 30 ms per step @ 50 MHz

    assign ledr = ledr_r;

    initial begin
        dance_cnt <= 25'd0;
        ledr_r    <= 18'h0_0001;   // LEDR[0] lit at start
        dance_dir <= 1'b0;
    end

    always @(posedge clk) begin
        if (dance_cnt >= DANCE_STEP) begin
            dance_cnt <= 25'd0;
            if (dance_dir == 1'b0) begin
                if (ledr_r[17]) begin dance_dir <= 1'b1; ledr_r <= ledr_r >> 1; end
                else            ledr_r <= ledr_r << 1;
            end else begin
                if (ledr_r[0])  begin dance_dir <= 1'b0; ledr_r <= ledr_r << 1; end
                else            ledr_r <= ledr_r >> 1;
            end
        end else begin
            dance_cnt <= dance_cnt + 25'd1;
        end
    end

endmodule
