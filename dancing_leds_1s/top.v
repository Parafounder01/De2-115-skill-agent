// top.v — DE2-115 top module for 10-pattern dancing LEDs
// 1 second per full cycle, 10 × 100ms steps
// Uses 50 MHz clock, drives LEDR[17:0]

module top (
    input  wire       CLOCK_50,
    input  wire       KEY_0,         // reset_n (active-low push button)
    output wire [17:0] LEDR
);

    wire reset_n;

    // Reset: active low from KEY0
    assign reset_n = KEY_0;

    // Instantiate the core LED controller
    dancing_leds #(
        .LED_WIDTH(18)
    ) led_ctrl (
        .clk(CLOCK_50),
        .reset_n(reset_n),
        .led(LEDR)
    );

endmodule
