// dancing_leds.v — 10-pattern LED animation, 1 second per full cycle
// Each of 10 steps runs for exactly 100ms (total = 1.0s), then repeats.
// Patterns are smooth, no glitches. Parameterized LED width.
//
// Timing at 50 MHz:
//   Step period = STEP_CYCLES = 5_000_000 cycles = 100 ms
//   10 steps × 100 ms = 1000 ms = 1 second
//   10 Hz step transition
//
// Each step uses counter[22:17] (6 bits, 64 sub-frames per step)
//   Sub-frame period = 5_000_000 / 64 = 78125 cycles = 1.5625 ms
//   Provides smooth sub-step animation within each pattern

module dancing_leds #(
    parameter LED_WIDTH = 18
)(
    input  wire                    clk,         // 50 MHz
    input  wire                    reset_n,     // active-low reset
    output reg  [LED_WIDTH-1:0]    led           // LED outputs
);

    //==============================================================
    // Step timer — 10 Hz / 100 ms per step
    //==============================================================
    localparam STEP_CYCLES = 5_000_000;   // 100 ms @ 50 MHz

    reg [22:0] counter;    // 0 .. 4,999,999
    reg [3:0]  step;       // 0..9  (10 patterns)
    reg        step_tick;  // pulse at start of each new step

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter   <= 0;
            step      <= 0;
            step_tick <= 0;
        end else begin
            if (counter >= (STEP_CYCLES - 1)) begin
                counter   <= 0;
                step_tick <= 1;
                if (step >= 9)
                    step <= 0;
                else
                    step <= step + 1;
            end else begin
                counter   <= counter + 1;
                step_tick <= 0;
            end
        end
    end

    //==============================================================
    // Sub-frame position — 64 smooth steps per pattern
    // counter[22:17] counts 0..63 within each 100 ms step
    //==============================================================
    wire [5:0] sub_pos = counter[22:17];

    // Knight Rider sweep position (derived from sub_pos)
    // Positions 0..15: sweeping right, 16..31: sweeping left
    wire [4:0] kr_pos = (sub_pos[4:0] < 16) ? sub_pos[4:0] : (31 - sub_pos[4:0]);

    //==============================================================
    // Pattern generation
    //==============================================================
    always @(*) begin
        case (step)
            //------------------------------------------------------
            // 0: Left → Right running LED
            //------------------------------------------------------
            4'd0: begin
                // sub_pos[4:0] = 0..31 → LED position
                // Position 17 and beyond: all off (gap at end of step)
                if (sub_pos[4:0] < LED_WIDTH)
                    led = (1 << sub_pos[4:0]);
                else
                    led = {LED_WIDTH{1'b0}};
            end

            //------------------------------------------------------
            // 1: Right → Left running LED
            //------------------------------------------------------
            4'd1: begin
                if (sub_pos[4:0] < LED_WIDTH)
                    led = (1 << ((LED_WIDTH-1) - sub_pos[4:0]));
                else
                    led = {LED_WIDTH{1'b0}};
            end

            //------------------------------------------------------
            // 2: Center expand (both sides outward)
            //------------------------------------------------------
            4'd2: begin
                // sub_pos[3:0] = 0..15, use 0..8 for expansion
                // pos=0: LEDs[8:9], pos=8: LEDs[0:17]
                if (sub_pos[3:0] <= 8) begin
                    led = (1 << (8 - sub_pos[3:0])) |
                          (1 << (9 + sub_pos[3:0]));
                end else begin
                    led = {LED_WIDTH{1'b0}};
                end
            end

            //------------------------------------------------------
            // 3: Edge contract (both sides inward)
            //------------------------------------------------------
            4'd3: begin
                // sub_pos[3:0] = 0..15, use 0..8
                // pos=0: LEDs[0:17], pos=8: LEDs[8:9]
                if (sub_pos[3:0] <= 8) begin
                    led = (1 << (0 + sub_pos[3:0])) |
                          (1 << ((LED_WIDTH-1) - sub_pos[3:0]));
                end else begin
                    led = {LED_WIDTH{1'b0}};
                end
            end

            //------------------------------------------------------
            // 4: Alternate even/odd blink
            //------------------------------------------------------
            4'd4: begin
                // sub_pos[0] toggles every sub-frame = ~3.125ms
                if (sub_pos[0])
                    led = 18'b010101010101010101;   // odd:  1,3,5,...,17
                else
                    led = 18'b101010101010101010;   // even: 0,2,4,...,16
            end

            //------------------------------------------------------
            // 5: Binary counter
            //------------------------------------------------------
            4'd5: begin
                // Show sub_pos as binary value on lower 6 LEDs
                led = {{(LED_WIDTH-6){1'b0}}, sub_pos[5:0]};
            end

            //------------------------------------------------------
            // 6: Knight Rider sweep (4-LED bar)
            //------------------------------------------------------
            4'd6: begin
                // kr_pos = 0..15: leftmost position of 4-LED bar
                // Positions 12..15 truncated at right edge
                if (kr_pos <= (LED_WIDTH - 4))
                    led = ({4{1'b1}} << kr_pos);
                else
                    led = {LED_WIDTH{1'b0}};
            end

            //------------------------------------------------------
            // 7: Circular rotate (3-LED bar)
            //------------------------------------------------------
            4'd7: begin
                if (sub_pos[4:0] <= (LED_WIDTH - 3))
                    led = ({3{1'b1}} << sub_pos[4:0]);
                else
                    led = {LED_WIDTH{1'b0}};
            end

            //------------------------------------------------------
            // 8: All LEDs ON
            //------------------------------------------------------
            4'd8: begin
                led = {LED_WIDTH{1'b1}};
            end

            //------------------------------------------------------
            // 9: All LEDs OFF
            //------------------------------------------------------
            4'd9: begin
                led = {LED_WIDTH{1'b0}};
            end

            default: begin
                led = {LED_WIDTH{1'b0}};
            end
        endcase
    end

endmodule
