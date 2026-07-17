// ============================================================
//  clock_divider.v — System clock dividers
//  Generates: 25 MHz (pixel), 1 kHz (debounce), 100 Hz (game)
// ============================================================

module clock_divider (
    input  clk_50,      // 50 MHz
    output clk_25,      // 25 MHz pixel clock
    output tick_1khz,   // 1 kHz tick (1 cycle pulse)
    output tick_100hz   // 100 Hz tick (1 cycle pulse)
);

    // 25 MHz: toggle on every edge of 50 MHz
    reg clk25;
    always @(posedge clk_50) clk25 <= ~clk25;
    assign clk_25 = clk25;

    // 1 kHz: 50 MHz / 50000 = 1000 Hz
    reg [15:0] cnt_1k;
    reg        t1k;
    always @(posedge clk_50) begin
        if (cnt_1k == 16'd49999) begin cnt_1k <= 0; t1k <= 1; end
        else begin cnt_1k <= cnt_1k + 1; t1k <= 0; end
    end
    assign tick_1khz = t1k;

    // 100 Hz: 1 kHz / 10 = 100 Hz
    reg [3:0] cnt_100;
    reg       t100;
    always @(posedge clk_50) begin
        if (t1k) begin
            if (cnt_100 == 4'd9) begin cnt_100 <= 0; t100 <= 1; end
            else begin cnt_100 <= cnt_100 + 1; t100 <= 0; end
        end else t100 <= 0;
    end
    assign tick_100hz = t100;

endmodule
