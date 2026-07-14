// dancing_led.v — DE2-115 running-light that bounces across LEDR[17:0]
// clk = 50 MHz (PIN_Y2), rst = active-high (PIN_AB28), ledr = 18 red LEDs
module dancing_led(
    input  wire       clk,
    input  wire       rst,
    output reg [17:0] ledr
);

    reg [24:0] counter;
    localparam HALF_PERIOD = 25'd1_500_000;  // 30 ms step @ 50 MHz

    reg dir;  // 0 = move toward LEDR17, 1 = move toward LEDR0
    localparam TO_HIGH = 1'b0, TO_LOW = 1'b1;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 25'd0;
            ledr    <= 18'h0_0001;  // LEDR[0] lit
            dir     <= TO_HIGH;
        end else begin
            if (counter >= HALF_PERIOD) begin
                counter <= 25'd0;
                if (dir == TO_HIGH) begin
                    if (ledr[17]) begin
                        dir  <= TO_LOW;
                        ledr <= ledr >> 1;
                    end else begin
                        ledr <= ledr << 1;
                    end
                end else begin
                    if (ledr[0]) begin
                        dir  <= TO_HIGH;
                        ledr <= ledr << 1;
                    end else begin
                        ledr <= ledr >> 1;
                    end
                end
            end else begin
                counter <= counter + 25'd1;
            end
        end
    end

endmodule
