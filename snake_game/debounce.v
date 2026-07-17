// ============================================================
//  debounce.v — key/switch debounce (10ms at 50MHz)
//  falling_edge pulses high for 1 cycle on press (active-low)
//  rising_edge  pulses high for 1 cycle on release
//  level is the debounced active-low value
// ============================================================

module debounce (
    input  clk,        // 50 MHz
    input  rst_n,
    input  raw,        // raw input (active-low for keys)
    output level,      // debounced active-low
    output falling_edge,
    output rising_edge
);

    reg [19:0] cnt;
    reg        stable;
    reg        prev;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin cnt <= 0; stable <= 1; prev <= 1; end
        else begin
            prev <= stable;
            if (raw != stable) begin
                if (cnt == 20'd500_000) begin stable <= raw; cnt <= 0; end
                else cnt <= cnt + 1;
            end else cnt <= 0;
        end
    end

    assign level = stable;
    assign falling_edge = ~stable &  prev;  // key just pressed
    assign rising_edge  =  stable & ~prev;  // key just released

endmodule
