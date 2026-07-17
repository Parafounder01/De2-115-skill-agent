// clock_divider.v — Configurable clock divider
// Takes 50MHz input, produces divided clock output
// Output toggles every DIVISOR input cycles
// Example: DIVISOR=25_000_000 → 1Hz output (50MHz / 50M = 1Hz)

module clock_divider #(
    parameter DIVISOR = 50_000_000
)(
    input  wire       clk_in,
    input  wire       reset_n,
    output reg        clk_out
);

    integer counter;

    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter >= (DIVISOR - 1)) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
